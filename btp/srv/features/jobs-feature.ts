import { Export, Import, Job } from '#cds-models/kernseife/db';
import cds, { log, utils, entities, Transaction, db } from '@sap/cds';
import { JobResult } from '../types/jobs';

const LOG = log('Jobs');

export const createJob = async (
  title: string,
  type: string,
  progressTotal: number
) => {
  const id = utils.uuid();
  await INSERT.into(entities.Jobs).entries({
    ID: id,
    title,
    type,
    progressTotal,
    progressCurrent: 0,
    status: 'NEW'
  });
  LOG.info('Job Started ' + title + ' (' + id + ')');
  return id;
};

export const updateJobProgress = async (
  id: string,
  tx: Transaction,
  progress: number
) => {
  await UPDATE(entities.Jobs)
    .set({ progressCurrent: progress, status: 'RUNNING' })
    .where({ ID: id });
  if (tx) tx.commit();
};

export const finishJob = async (id: string, jobResult?: JobResult) => {
  LOG.info('Job Finished ' + id);
  const { progressTotal } = await SELECT.one
    .from(entities.Jobs)
    .columns('progressTotal')
    .where({ ID: id });
  const job = {
    status: 'SUCCESS',
    message: jobResult?.message,
    progressCurrent: progressTotal || 100
  } as Job;
  if (jobResult?.exportIdList) {
    for (const exportId of jobResult.exportIdList) {
      await setJobIdForExport(exportId, id);
    }
  }

  await UPDATE(entities.Jobs, { ID: id }).set(job);
};

export const failJob = async (id: string, err: any) => {
  LOG.error('Job Failed: ' + id, err);
  const { progressTotal } = await SELECT.one
    .from(entities.Jobs)
    .columns('progressTotal')
    .where({ ID: id });
  await UPDATE(entities.Jobs, { ID: id }).with({
    progressCurrent: progressTotal || 100,
    status: 'ERROR',
    message: err.message
  });
};

export const runAsJob = async (
  title: string,
  type: string,
  progressTotal: number,
  jobFunction: (
    tx: Transaction,
    updateProgress: (progressNumber: number) => Promise<void>
  ) => Promise<void | JobResult>,
  errorHandler?: () => Promise<void>,
  successHandler?: () => Promise<void | JobResult>
) => {
  if (!Number.isInteger(progressTotal)) {
    throw new Error('progressTotal is Not a Number: ' + progressTotal);
  }
  const jobId = await createJob(title, type, progressTotal);

  cds
    .spawn({ after: 200 }, async (tx: Transaction) => {
      return await jobFunction(tx, (progress) =>
        updateJobProgress(jobId, tx, progress)
      );
    })
    .on('succeeded', async (jobResult?: JobResult) => {
      LOG.info(
        `Job Succeeded ${jobResult?.message} ${jobResult?.exportIdList}`
      );
      await finishJob(jobId, jobResult);
      if (successHandler) await successHandler();
    })
    .on('failed', async (err) => {
      // Open new transaction to avoid issues with previous transaction being rolled back
      db.tx(async (tx) => {
        await failJob(jobId, err);
        if (errorHandler) await errorHandler();
      });
    });

  return jobId;
};

export const createExport = async (
  type: string,
  fileName: string,
  file: any,
  fileType: string
) => {
  const exportObject = {
    ID: utils.uuid(),
    type,
    file,
    fileType,
    fileName
  } as Export;
  // Seperate transaction to avoid issues with File Streams for some reason in SQLite
  await INSERT.into(entities.Exports).entries(exportObject);
  LOG.info(`Export created ${exportObject.ID}`);
  return exportObject.ID as string;
};

export const createImport = async (
  importType: string,
  fileName: string,
  file: any,
  fileType: string,
  systemId: string | undefined | null = undefined,
  defaultRating: string | undefined = undefined,
  overwite: boolean | undefined = undefined,
  comment: string | undefined = undefined
): Promise<string> => {
  const importObject = {
    ID: utils.uuid(),
    type: importType,
    title: importType + ' Import ' + fileName,
    status: 'NEW',
    systemId,
    defaultRating,
    overwite,
    comment,
    file,
    fileType,
    fileName
  } as Import;
  // Seperate transaction to avoid issues with File Streams for some reason in SQLite
  await INSERT.into(entities.Imports).entries(importObject);

  return importObject.ID as string;
};

export const setJobIdForImport = async (importId: string, jobId: string) => {
  await UPDATE(entities.Imports, { ID: importId }).set({ job_ID: jobId });
};

export const setJobIdForExport = async (exportId: string, jobId: string) => {
  await UPDATE(entities.Exports, { ID: exportId }).set({ job_ID: jobId });
};

export const uploadFile = async (
  importType: string,
  fileName: string,
  file: any,
  systemId: string | undefined | null,
  defaultRating?: string,
  overwrite?: boolean,
  comment?: string
): Promise<string> => {
  LOG.info('Uploading file', {
    fileName: fileName,
    type: importType,
    defaultRating,
    overwrite,
    systemId,
    comment
  });

  if (!file) {
    throw new Error('No file uploaded');
  }
  let fileType = 'text/csv'; // Default file type
  switch (importType) {
    case 'FINDINGS':
      if (!systemId) {
        throw new Error('No SystemId provided');
      }
      break;
    case 'MISSING_CLASSIFICATION':
      break;
    case 'ENHANCEMENT':
      break;
    case 'EXPLICIT':
      break;
    case 'EXTERNAL_CLASSIFICATION':
      fileType = 'application/zip';
      break;
    default:
      throw new Error('Invalid type provided');
  }
  return await createImport(
    importType,
    fileName,
    file,
    fileType,
    systemId,
    defaultRating,
    overwrite,
    comment
  );
};

export const jobHasImports = async (jobId: string) => {
  const result = await SELECT.from(entities.Imports)
    .columns('COUNT( * ) as count')
    .where({ job_ID: jobId });
  return result && result[0] && result[0].count > 0;
};

export const jobHasExports = async (jobId: string) => {
  const result = await SELECT.from(entities.Exports)
    .columns('COUNT( * ) as count')
    .where({ job_ID: jobId });
  return result && result[0] && result[0].count > 0;
};
