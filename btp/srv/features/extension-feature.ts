import { log } from '@sap/cds';

const LOG = log('ExtensionFeature');

export const removeAllDevelopmentObjects = async (ref: any) => {
  // read Extension Object
  const extension = await SELECT.one.from(ref, (e) => {
    e.ID;
  });
  LOG.info(
    'Removing all DevelopmentObjects for Extension ' + extension.title,
    extension
  );

  await UPDATE.entity('kernseife.db.DevelopmentObjects')
    .set({
      extension_ID: null
    })
    .where({ extension_ID: extension.ID });
};

export const addAllUnassignedDevelopmentObjects = async (ref: any) => {
  // read Extension Object
  const extension = await SELECT.one.from(ref, (e) => {
    e.ID, e.system();
  });
  await UPDATE.entity('kernseife.db.DevelopmentObjects')
    .set({
      extension_ID: extension.ID
    })
    .where({ extension_ID: null, systemId: extension.system.sid });
};

export const addDevelopmentObjectsByDevClass = async (
  ref: any,
  devClass: string
) => {
  // read Extension Object
  const extension = await SELECT.one.from(ref, (e) => {
    e.ID, e.system();
  });
  return await UPDATE.entity('kernseife.db.DevelopmentObjects')
    .set({
      extension_ID: extension.ID
    })
    .where({
      extension_ID: null,
      systemId: extension.system.sid,
      devClass: devClass
    });
};

export const addDevelopmentObject = async (
  ref: any,
  objectType: string,
  objectName: string,
  devClass: string
) => {
  // read Extension Object
  // Add Tests
  const extension = await SELECT.one.from(ref, (e) => {
    e.ID, e.system();
  });
  await UPDATE.entity('kernseife.db.DevelopmentObjects')
    .set({
      extension_ID: extension.ID
    })
    .where({
      extension_ID: null,
      systemId: extension.system.sid,
      devClass: devClass,
      objectType: objectType,
      objectName: objectName
    });
};
