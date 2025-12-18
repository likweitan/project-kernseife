import { entities, log, Service } from '@sap/cds';

import {
  assignFrameworkByRef,
  assignSuccessorByRef,
  getClassificationCount
} from './features/classification-feature';

import { runAsJob } from './features/jobs-feature';
import {
  loadReleaseState,
  updateClassificationsFromReleaseStates
} from './features/releaseState-feature';

export default (srv: Service) => {
  const LOG = log('ClassificationService');

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
};
