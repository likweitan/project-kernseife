import { Jobs } from '#cds-models/AdminService';
import { log, Service, Transaction } from '@sap/cds';
import { PassThrough } from 'stream';
import dayjs from 'dayjs';
import {
  getClassificationCount,
  getClassificationJsonAsZip,
  getClassificationJsonExternal,
  getClassificationJsonCustom,
  importEnhancementObjectsById,
  importExpliticObjectsById,
  importExternalClassificationById,
  importMissingClassificationsById,
  syncClassificationsToExternalSystemByRef,
  syncClassificationsToExternalSystems,
  importMissingClassificationsBTP
} from './features/classification-feature';
import {

  importFindingsById,
  importDevelopmentObjectsBTP
} from './features/developmentObject-feature';

import {
  createExport,
  createImport,
  jobHasExports,
  jobHasImports,
  runAsJob,
  setJobIdForImport,
  uploadFile
} from './features/jobs-feature';
import { createInitialData } from './features/setup-feature';
import JSZip from 'jszip';
import { handleMessage, updateDestinations } from './lib/connectivity';
import { JobResult } from './types/jobs';
import {
  getProject,
  setupProject,
  triggerAtcRun
} from './features/btp-connector-feature';
import { System } from '#cds-models/kernseife/db';

export default (srv: Service) => {
  const LOG = log('AdminService');

  srv.on('PUT', 'FileUpload', async (req: any, next: any) => {
    LOG.info('FileUpload');

    const uploadType = req.headers['x-upload-type'];
    const fileName = req.headers['x-file-name'];
    const systemId = req.headers['x-system-id'];
    const defaultRating = req.headers['x-default-rating'];
    const overwrite = req.headers['x-overwrite'] === 'true';
    const comment = req.headers['x-comment'];

    const stream = new PassThrough();
    const buffers = [] as any[];
    req.data.file.pipe(stream);
    const importId = await new Promise((resolve) => {
      stream.on('data', (dataChunk: any) => {
        buffers.push(dataChunk);
      });
      stream.on('end', async () => {
        const buffer = Buffer.concat(buffers);
        try {
          resolve(
            await uploadFile(
              uploadType,
              fileName,
              buffer,
              systemId,
              defaultRating,
              overwrite,
              comment
            )
          );
        } catch (e) {
          resolve(undefined);
        }
      });
    });
    if (importId) {
      await srv.emit('Imported', {
        ID: importId,
        type: uploadType
      });

      req.notify({
        message: 'Upload Successful',
        status: 200
      });
    } else {
      req.error(400);
    }
  });

  srv.on('createInitialData', ['Settings', 'Settings.drafts'], async (req) => {
    LOG.info('createInitialData');
    const configUrl = req.data.configUrl;
    await createInitialData(configUrl);
  });

  srv.on('Imported', async (msg) => {
    const ID = msg.data.ID;
    const importType = msg.data.type;
    LOG.info(`Imported ${ID} ${importType}`);

    const jobId = await runAsJob(
      `Import ${importType}`,
      `IMPORT_${importType}`,
      100,
      async (
        tx: Transaction,
        updateProgress: (progress: number) => Promise<void>
      ): Promise<JobResult> => {
        LOG.info('importType', importType);
        switch (importType) {
          case 'MISSING_CLASSIFICATION':
            return await importMissingClassificationsById(
              ID,
              tx,
              updateProgress
            );
          case 'FINDINGS':
            return await importFindingsById(ID, tx, updateProgress);
          case 'ENHANCEMENT':
            return await importEnhancementObjectsById(ID, tx, updateProgress);
          case 'EXPLICIT':
            return await importExpliticObjectsById(ID, tx, updateProgress);
          case 'EXTERNAL_CLASSIFICATION':
            return await importExternalClassificationById(
              ID,
              tx,
              updateProgress
            );
          case 'BTP_DEVELOPMENT_OBJECTS':
            return await importDevelopmentObjectsBTP(ID, tx, updateProgress);
          case 'BTP_MISSING_CLASSIFICATION':
            return await importMissingClassificationsBTP(
              ID,
              tx,
              updateProgress
            );
          default:
            LOG.error(`Unknown Import Type ${importType}`);
            throw new Error(`Unknown Import Type ${importType}`);
        }
      }
    );

    await setJobIdForImport(ID, jobId);
  });

  srv.before(
    'READ',
    ['Destinations', 'Destinations.drafts'],
    async (req: any) => {
      await updateDestinations();
    }
  );

  srv.on('syncClassificationsToAllSystems', async (req: any) => {
    LOG.info('syncRatingsToAllSystems');
    await syncClassificationsToExternalSystems();
    req.notify('SYNC_SUCCESSFUL');
  });

  srv.on(
    'syncClassifications',
    ['Systems', 'Systems.drafts'],
    async (req: any) => {
      try {
        await syncClassificationsToExternalSystemByRef(req.subject);

        req.notify('SYNC_SUCCESSFUL');
      } catch (e: any) {
        handleMessage(req, {
          message: e.message,
          numericSeverity: 3
        });
      }
    }
  );

  srv.on('setupSystem', ['Systems', 'Systems.drafts'], async (req: any) => {
    const system: System = await SELECT.one.from(req.subject);
    if (!system || !system.destination) {
      return {
        message: 'SYSTEM_NO_DESTINATION',
        numericSeverity: 3
      };
    }

    const message = await setupProject({
      destination: system.destination,
      jwtToken: req.headers.authorization
    });
    handleMessage(req, message);
  });

  srv.on('triggerATCRun', ['Systems', 'Systems.drafts'], async (req: any) => {
    const system: System = await SELECT.one.from(req.subject);
    if (!system || !system.destination) {
      return {
        message: 'SYSTEM_NO_DESTINATION',
        numericSeverity: 3
      };
    }

    const message = await triggerAtcRun({
      destination: system.destination,
      jwtToken: req.headers.authorization
    });
    handleMessage(req, message);
  });

  // Read Project via System
  srv.after('READ', ['Systems', 'Systems.drafts'], async (Systems, req) => {
    for (const system of Systems as any[]) {
      system.setupDone = false;
      system.setupNotDone = true;
      if (system.destination) {
        try {
          const project = await getProject({
            destination: system.destination,
            jwtToken: req.headers.authorization
          });

          system.project = project;
          system.setupDone = true;
          system.setupNotDone = false; // As UI Bindings cannot handle negation
        } catch (e) {
          LOG.error('Error getting Project for System', {
            systemId: system.ID,
            error: e
          });
        }
      }
    }
  });

  // Read Project via System
  srv.after('READ', ['Jobs'], async (jobs, req) => {
    for (const job of jobs as Jobs) {
      // Check if Job has Imports
      job.hideImports = !(await jobHasImports(job.ID!));
      job.hideExports = !(await jobHasExports(job.ID!));
    }
  });

  srv.on('triggerImport', async (req: any) => {
    LOG.info('Trigger Import', req.data);
    const { importType, systemId } = req.data;
    const importId = await createImport(
      importType,
      '',
      null,
      '',
      systemId,
      '',
      false,
      ''
    );

    if (importId) {
      await srv.emit('Imported', {
        ID: importId,
        type: importType
      });

      req.notify({
        message: 'Import started',
        status: 200
      });
    } else {
      req.error(400);
    }
  });

  srv.on('triggerExport', async (req: any) => {
    LOG.info('Trigger Export', req.data);
    const { exportType, legacy, dateFrom } = req.data;

    await runAsJob(
      `Export ${exportType}`,
      `EXPORT_${exportType}`,
      100,
      async (
        tx: Transaction,
        updateProgress: (progress: number) => Promise<void>
      ): Promise<JobResult> => {
        LOG.info('type', exportType);
        switch (exportType) {
          case 'SYSTEM_CLASSIFICATION': {
            const fileType = 'application/zip';
            const filename = `system_classification_${dayjs().format('YYYY_MM_DD')}.zip`;
            await updateProgress(15);
            const classificationJson = await getClassificationJsonCustom({
              legacy
            });
            await updateProgress(85);
            const file = await getClassificationJsonAsZip(classificationJson);
            await updateProgress(100);
            return {
              message: `Exported ${classificationJson.objectClassifications.length} classifications`,
              exportIdList: [
                await createExport(exportType, filename, file, fileType)
              ]
            };
          }
          case 'EXTERNAL_CLASSIFICATION': {
            // Wrap in ZIP

            const count = await getClassificationCount(dateFrom);
            let offset = 0;
            const rowSize = 100000;
            let classificationList;
            const exportList: string[] = [];
            do {
              const zip = new JSZip();
              const fileType = 'application/zip';
              const filename = `external_classification_${dayjs().format('YYYY_MM_DD')}_${offset + 1}.zip`;
              const progress = Math.round((100 / count) * rowSize * offset);
              classificationList = await getClassificationJsonExternal(
                rowSize,
                offset * rowSize,
                dateFrom
              );
              if (tx) tx.commit(); // Commit Read
              for (const classification of classificationList) {
                if (
                  classification.tadirObjectType ===
                    classification.objectType &&
                  classification.tadirObjectName === classification.objectName
                ) {
                  zip.file(
                    `${classification.objectName.replaceAll('/', '#').toUpperCase()}.${classification.objectType.toUpperCase()}.json`,
                    JSON.stringify(classification, null, 2)
                  );
                } else {
                  zip.file(
                    `${classification.tadirObjectName.replaceAll('/', '#').toUpperCase()}.${classification.tadirObjectType.toUpperCase()}.${classification.objectName.replaceAll('/', '#').toLowerCase()}.${classification.objectType.toUpperCase()}.json`,
                    JSON.stringify(classification, null, 2)
                  );
                }
              }
              offset++;

              await updateProgress(progress);

              LOG.info('Generate Zip - Start ' + Object.keys(zip.files).length);
              const file = await zip.generateAsync({
                streamFiles: true,
                type: 'nodebuffer',
                compression: 'DEFLATE',
                compressionOptions: { level: 7 }
              });

              LOG.info('Generate Zip - Finish');

              exportList.push(
                await createExport(exportType, filename, file, fileType)
              );
              if (tx) tx.commit();
            } while (classificationList.length == rowSize);

            await updateProgress(100);
            return {
              message: `Exported ${count} classifications`,
              exportIdList: exportList
            };
          }
          default:
            LOG.error(`Unknown Export Type ${exportType}`);
            throw new Error(`Unknown Import Type ${exportType}`);
        }
      }
    );
  });
};
