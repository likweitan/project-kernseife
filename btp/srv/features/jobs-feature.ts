import { Export, Import, Job } from '#cds-models/kernseife/db';
import cds, {
  log,
  utils,
  Transaction,
  db,
  context,
  EventContext
} from '@sap/cds';
import { JobResult } from '../types/jobs';

const LOG = log('Jobs');

export const createJob = async (
  title: string,
  type: string,
  progressTotal: number
) => {
  const id = utils.uuid();
  await INSERT.into('kernseife.db.Jobs').entries({
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
  await UPDATE('kernseife.db.Jobs')
    .set({ progressCurrent: progress, status: 'RUNNING' })
    .where({ ID: id });
  if (tx) await tx.commit();
};

export const finishJob = async (id: string, jobResult?: JobResult) => {
  LOG.info('Job Finished ' + id);
  const { progressTotal } = await SELECT.one
    .from('kernseife.db.Jobs')
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

  await UPDATE('kernseife.db.Jobs', { ID: id }).set(job);
};

export const failJob = async (id: string, err: any) => {
  LOG.error('Job Failed: ' + id, err);
  const { progressTotal } = await SELECT.one
    .from('kernseife.db.Jobs')
    .columns('progressTotal')
    .where({ ID: id });
  await UPDATE('kernseife.db.Jobs', { ID: id }).with({
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
  const { user } = context as EventContext;
  LOG.info(`Starting Job ${jobId} as user ${user.id}`);
  cds
    .spawn({ user, after: 200 }, async (tx: Transaction) => {
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
  await INSERT.into('kernseife.db.Exports').entries(exportObject);
  LOG.info(`Export created ${exportObject.ID}`);
  return exportObject.ID as string;
};

export const createImport = async (
  importType: string,
  fileName: string,
  file: any,
  fileType: string,
  systemId: string | undefined | null = undefined,
  overwite: boolean | undefined = undefined
): Promise<string> => {
  const importObject = {
    ID: utils.uuid(),
    type: importType,
    title: importType + ' Import ' + fileName,
    status: 'NEW',
    systemId,
    overwite,
    file,
    fileType,
    fileName
  } as Import;
  // Seperate transaction to avoid issues with File Streams for some reason in SQLite
  await INSERT.into('kernseife.db.Imports').entries(importObject);

  return importObject.ID as string;
};

export const setJobIdForImport = async (importId: string, jobId: string) => {
  await UPDATE('kernseife.db.Imports', { ID: importId }).set({ job_ID: jobId });
};

export const setJobIdForExport = async (exportId: string, jobId: string) => {
  await UPDATE('kernseife.db.Exports', { ID: exportId }).set({ job_ID: jobId });
};

export const jobHasImports = async (jobId: string) => {
  const result = await SELECT.from('kernseife.db.Imports')
    .columns('COUNT( * ) as count')
    .where({ job_ID: jobId });
  return result && result[0] && result[0].count > 0;
};

export const jobHasExports = async (jobId: string) => {
  const result = await SELECT.from('kernseife.db.Exports')
    .columns('COUNT( * ) as count')
    .where({ job_ID: jobId });
  return result && result[0] && result[0].count > 0;
};
