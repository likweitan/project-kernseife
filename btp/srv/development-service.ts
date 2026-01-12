import { log, Service } from '@sap/cds';
import { calculateScores, getDevelopmentObjectCount } from './features/developmentObject-feature';
import {
  addAllUnassignedDevelopmentObjects,
  addDevelopmentObject,
  addDevelopmentObjectsByDevClass,
  removeAllDevelopmentObjects
} from './features/extension-feature';
import { DynamicAppLauncher } from '#cds-models/kernseife/types';

export default (srv: Service) => {
  const LOG = log('DevelopmentService');

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

  srv.on('recalculateAllScores', async () => {
    await calculateScores();
  });

  srv.on('READ', 'FeatureControl', async (req) => {
    let isNotManager = true;

    if (req.user.is('development-manager')) {
      isNotManager = false;
    }

    return {
      isNotManager: isNotManager,
      isManager: !isNotManager
    };
  });

   srv.on('getTileInfo', async (req) => {
      switch (req.data.appName) {
        default:
          return {
            subtitle: req.user.is('development-manager') ? 'Manager' : 'Viewer',
            icon: 'sap-icon://activity-assigned-to-goal',
            number: await getDevelopmentObjectCount(),
          } as DynamicAppLauncher;
      }
    });
};
