import { JobType } from '#cds-models/kernseife/db';
import { connect, entities, log, Service, Transaction } from '@sap/cds';
import { PassThrough, Readable } from 'stream';
import dayjs from 'dayjs';
import {
  assignFrameworkByRef,
  assignSuccessorByRef,
  getClassificationCount,
  getClassificationJsonAsZip,
  getClassificationJsonCloud,
  getClassificationJsonCustom,
  getClassificationJsonStandard,
  importEnhancementObjectsById,
  importExpliticObjectsById,
  importGithubClassificationById,
  importMissingClassificationsById,
  syncClassificationsToExternalSystemByRef,
  syncClassificationsToExternalSystems
} from './features/classification-feature';
import {
  calculateScores,
  calculateScoreByRef,
  importFindingsById
} from './features/developmentObject-feature';
import {
  addAllUnassignedDevelopmentObjects,
  addDevelopmentObject,
  addDevelopmentObjectsByDevClass,
  removeAllDevelopmentObjects
} from './features/extension-feature';
import { runAsJob } from './features/jobs-feature';
import {
  loadReleaseState,
  updateClassificationsFromReleaseStates
} from './features/releaseState-feature';
import { createInitialData } from './features/setup-feature';
import { uploadFile } from './features/upload-feature';
import JSZip from 'jszip';
import { updateDestinations } from './lib/connectivity';

export default (srv: Service) => {
  const LOG = log('AdminService');

  srv.on('PUT', 'FileUpload', async (req: any, next: any) => {
    LOG.info('FileUpload');

    const uploadType = req.headers['x-upload-type'];
    const fileName = req.headers['x-file-name'];
    const systemId = req.headers['x-system-id'];
    const defaultRating = req.headers['x-default-rating'];
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
  srv.on(
    'clearDevelopmentObjectList',
    ['Extensions', 'Extensions.drafts'],
    async ({ subject, params }) => {
      LOG.info('clearDevelopmentObjectList', { subject, params });
      await removeAllDevelopmentObjects(subject);
    }
  );

  srv.on(
    'addUnassignedDevelopmentObjects',
    ['Extensions', 'Extensions.drafts'],
    async ({ subject, params }) => {
      LOG.info('addUnassignedDevelopmentObjects', { subject, params });
      await addAllUnassignedDevelopmentObjects(subject);
    }
  );

  srv.on(
    'addDevelopmentObjectsByDevClass',
    ['Extensions', 'Extensions.drafts'],
    async (req: any) => {
      LOG.info('addDevelopmentObjectsByDevClass', req);
      const devClass = req.data.devClass;
      if (!devClass) {
        return req.error(400, `Package Required`);
      }
      const result = await addDevelopmentObjectsByDevClass(
        req.subject,
        devClass
      );
      LOG.info('addDevelopmentObjectsByDevClass Result', result);
      req.notify({
        message: 'Added Objects Successful',
        status: 200
      });
    }
  );

  srv.on(
    'addDevelopmentObject',
    ['Extensions', 'Extensions.drafts'],
    async (req) => {
      LOG.info('addDevelopmentObject', req);
      const objectName = req.data.objectName;
      const objectType = req.data.objectType;
      const devClass = req.data.devClass;
      if (!devClass || !objectName || !objectType) {
        return req.error(400, `Missing mandatory parameter`);
      }
      await addDevelopmentObject(req.subject, objectType, objectName, devClass);
    }
  );

  srv.on('createInitialData', ['Settings', 'Settings.drafts'], async (req) => {
    LOG.info('createInitialData');
    const contactPerson = req.data.contactPerson;
    const prefix = req.data.prefix;
    const customerTitle = req.data.customerTitle;
    if (!contactPerson || !prefix || !customerTitle) {
      return req.error(400, `Missing mandatory parameter`);
    }
    const configUrl = req.data.configUrl;
    await createInitialData(contactPerson, prefix, customerTitle, configUrl);
  });

  srv.on('loadReleaseState', async () => {
    LOG.info('loadReleaseState');
    await runAsJob(
      'Import Release States',
      'IMPORT_RELEASE_STATE',
      100,
      async (tx, updateProgress) => {
        await loadReleaseState();
        await updateProgress(25);
        const classificationsCount = await getClassificationCount();
        await updateClassificationsFromReleaseStates(
          tx,
          async (progress: number) =>
            await updateProgress(25 + (progress / classificationsCount) * 75)
        );
        await updateProgress(100);
      }
    );
  });

  srv.on('Imported', async (msg) => {
    const ID = msg.data.ID;
    const type = msg.data.type;
    LOG.info(`Imported ${ID} ${type}`);

    await runAsJob(
      `Import ${type}`,
      `IMPORT_${type}` as JobType,
      100,
      async (
        tx: Transaction,
        updateProgress: (progress: number) => Promise<void>
      ) => {
        LOG.info('type', type);
        switch (type) {
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
          case 'GITHUB_CLASSIFICATION':
            return await importGithubClassificationById(ID, tx, updateProgress);
          default:
            LOG.error(`Unknown Import Type ${type}`);
            throw new Error(`Unknown Import Type ${type}`);
        }
      },
      async () => {
        const db = await connect.to('db');
        const tx = db.tx();
        try {
          await tx.run(
            UPDATE(entities.Imports).set({ status: 'FAILED' }).where({ ID })
          );
          await tx.commit();
        } catch (e) {
          LOG.error(e);
          await tx.rollback();
        }
      },
      async () => {
        const db = await connect.to('db');
        const tx = db.tx();
        try {
          await tx.run(
            UPDATE(entities.Imports)
              .set({ status: 'IMPORTED', progress: 100 })
              .where({ ID })
          );
          await tx.commit();
        } catch (e) {
          LOG.error(e);
          await tx.rollback();
        }
      }
    );
  });

  srv.on('recalculateScore', async (req) => {
    LOG.debug('Calculate Score');
    return await calculateScoreByRef(req.subject);
  });

  srv.on('recalculateAllScores', async () => {
    await calculateScores();
  });

  srv.before(
    'DELETE',
    ['SuccessorClassifications', 'SuccessorClassifications.drafts'],
    async (req) => {
      // Don't allow deletion of Successors which are still used
      const result = await SELECT.one.from(entities.Classifications).where({
        successorClassification_Code: (req.params[0] as { Code: string }).Code
      });
      if (!result || !result.custom) {
        // Not allowed to delete
        return req.error(400, `Only custom entries can be deleted`);
      }
    }
  );

  srv.before(
    'READ',
    ['Destinations', 'Destinations.drafts'],
    async (req: any) => {
      await updateDestinations();
    }
  );

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  srv.on('GET', 'Downloads', async (req: any) => {
    const downloadType = req._.req.path.replace('/Downloads/', '');
    let content;
    switch (downloadType) {
      case 'classificationStandard': {
        const mimetype = 'application/zip';
        const filename = `classification_${dayjs().format('YYYY_MM_DD')}.zip`;
        const classificationJson = await getClassificationJsonStandard();
        const file = await getClassificationJsonAsZip(classificationJson);
        req.reply(Readable.from([file]), { mimetype, filename });
        break;
      }
      case 'classificationCustom': {
        const mimetype = 'application/zip';
        const filename = `classification_${dayjs().format('YYYY_MM_DD')}.zip`;
        const classificationJson = await getClassificationJsonCustom();
        const file = await getClassificationJsonAsZip(classificationJson);
        req.reply(Readable.from([file]), { mimetype, filename });
        break;
      }
      case 'classificationCustomLegacy': {
        const mimetype = 'application/zip';
        const filename = `classification_${dayjs().format('YYYY_MM_DD')}_legacy.zip`;
        const classificationJson = await getClassificationJsonCustom({
          legacy: true
        });
        const file = await getClassificationJsonAsZip(classificationJson);
        req.reply(Readable.from([file]), { mimetype, filename });
        break;
      }
      case 'classificationCloud': {
        const mimetype = 'application/zip';
        const filename = `classification_${dayjs().format('YYYY_MM_DD')}.zip`;
        const classificationJson = await getClassificationJsonCloud();
        const file = await getClassificationJsonAsZip(classificationJson);
        req.reply(Readable.from([file]), { mimetype, filename });
        break;
      }
      case 'classificationGithub': {
        const mimetype = 'application/zip';
        const filename = downloadType + '.zip';
        const classificationJson = await getClassificationJsonCloud();
        // Wrap in ZIP
        const zip = new JSZip();

        for (const classification of classificationJson.objectClassifications) {
          if (
            classification.tadirObjectType === classification.objectType &&
            classification.tadirObjectName === classification.objectName
          ) {
            zip.file(
              `${classification.objectName.replaceAll('/', '#').toLowerCase()}.${classification.objectType.toLowerCase()}.json`,
              JSON.stringify(classification, null, 2)
            );
          } else {
            zip.file(
              `${classification.tadirObjectName.replaceAll('/', '#').toLowerCase()}.${classification.tadirObjectType.toLowerCase()}.${classification.objectName.replaceAll('/', '#').toLowerCase()}.${classification.objectType.toLowerCase()}.json`,
              JSON.stringify(classification, null, 2)
            );
          }
        }
        content = await zip.generateAsync({
          type: 'nodebuffer',
          compression: 'DEFLATE',
          compressionOptions: { level: 7 }
        });
        req.reply(Readable.from([content]), { mimetype, filename });
        break;
      }
      default: {
        return req.error(400, `Download Type ${downloadType} not found`);
      }
    }
  });

  srv.on(
    'assignFramework',
    ['Classifications', 'Classifications.drafts'],
    async (req: any) => {
      const code = req.data.frameworkCode;
      LOG.debug('assignFramework', { code });
      return await assignFrameworkByRef(req.subject, code);
    }
  );

  srv.on(
    'assignSuccessor',
    ['Classifications', 'Classifications.drafts'],
    async (req: any) => {
      const tadirObjectType = req.data.tadirObjectType;
      const tadirObjectName = req.data.tadirObjectName;
      const objectType = req.data.objectType;
      const objectName = req.data.objectName;
      const successorType = req.data.successorType;
      LOG.debug('assignSuccssor', {
        tadirObjectType,
        tadirObjectName,
        objectType,
        objectName,
        successorType
      });
      return await assignSuccessorByRef(
        req.subject,
        tadirObjectType,
        tadirObjectName,
        objectType,
        objectName,
        successorType
      );
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
      await syncClassificationsToExternalSystemByRef(req.subject);
      req.notify('SYNC_SUCCESSFUL');
    }
  );

  srv.on('READ', ['Projects', 'Projects.drafts'], async (req) => {
    // Read Destination via System
    const system = (await SELECT.one
      .from({ ref: [req.subject.ref[0]] })
      .columns('destination')) as any;

    if (!system || !system.destination) {
      // No Destination => no Project
      return [];
    }

    const btp = await connect.to('kernseife_btp', {
      credentials: {
        destination: system.destination,
        path: '/sap/opu/odata4/sap/zknsf_btp_connector/srvd/sap/zknsf_btp_connector/0001'
      }
    });
    const projectList = await btp.run(SELECT('ZKNSF_I_PROJECTS'));
    return projectList;
  });

  // Read Project via System
  srv.after('READ', ['Systems', 'Systems.drafts'], async (Systems, req) => {
    for (const system of Systems as any[]) {
      if (system.destination) {
        const btp = await connect.to('kernseife_btp', {
          credentials: {
            destination: system.destination,
            path: '/sap/opu/odata4/sap/zknsf_btp_connector/srvd/sap/zknsf_btp_connector/0001'
          }
        });
        const projectList = await btp.run(SELECT('ZKNSF_I_PROJECTS'));
        if (projectList && projectList.length == 1) {
          system.project = projectList[0];
        }
      }
    }
  });
};
