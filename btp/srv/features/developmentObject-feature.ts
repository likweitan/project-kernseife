import {
  DevelopmentObject,
  Import,
  FindingRecord,
  CleanCoreLevel
} from '#cds-models/kernseife/db';
import { db, entities, log, Transaction } from '@sap/cds';
import { text } from 'node:stream/consumers';
import papa from 'papaparse';
import {
  getSuccessorKey,
  getSuccessorRatingMap
} from './classification-feature';
import { supportslanguageVersions } from '../lib/languageVersions';

const LOG = log('DevelopmentObjectFeature');

export const getDevelopmentObjectCount = async () => {
  const result = await SELECT.from(entities.DevelopmentObjects).columns(
    'IFNULL(COUNT( * ),0) as count'
  );
  return result[0]['count'];
};

export const getTotalScore = async () => {
  const result = await SELECT.from(entities.DevelopmentObjects).columns(
    'IFNULL(SUM( score ), 0) as score'
  );
  return result[0]['score'];
};

export const determineNamespace = (developmentObject) => {
  switch (developmentObject.objectName?.charAt(0)) {
    case '/':
      return '/' + developmentObject.objectName.split('/')[1] + '/';
    case 'Z':
    case 'Y':
      return developmentObject.objectName?.charAt(0);
    default:
      return undefined;
  }
};

export const calculateScoreByRef = async (ref) => {
  // read Development Object
  const developmentObject = await SELECT.one.from(ref);

  // Get Latest Scoring Run
  const findingRecordList = await SELECT.from(entities.FindingRecords)
    .columns(
      'itemId',
      'messageId',
      'classification.rating.code as code',
      'classification.rating.score as score'
    )
    .where({
      import_ID: developmentObject.latestFindingImportId,
      objectType: developmentObject.objectType,
      objectName: developmentObject.objectName,
      devClass: developmentObject.devClass,
      systemId: developmentObject.systemId
    });
  LOG.info('findingRecordList', { findingRecordList: findingRecordList });
  const score = findingRecordList.reduce((sum, row) => {
    return sum + row.score;
  }, 0);
  developmentObject.score = score || 0;
  LOG.info('Development Object Score', {
    score: developmentObject.score
  });
  // Update Development Object
  await UPSERT.into(entities.DevelopmentObjects).entries([developmentObject]);
  // Update Scoring Findings
  for (const findingRecord of findingRecordList) {
    if (findingRecord.messageId !== findingRecord.code) {
      await UPDATE.entity(entities.FindingRecords)
        .with({
          messageId: findingRecord.code + findingRecord.messageId.substring(3)
        })
        .where({
          import_ID: developmentObject.latestFindingImportId,
          itemId: findingRecord.itemId
        });
    }
  }

  return developmentObject;
};

export const calculateNamespaces = async () => {
  if (db.kind != 'sqlite') {
    await db.run(
      "UPDATE kernseife_db_DEVELOPMENTOBJECTS SET NAMESPACE = CASE SUBSTRING(OBJECTNAME,1,1) WHEN 'Z' THEN 'Z' WHEN 'Y' THEN 'Y' WHEN '/' THEN SUBSTR_REGEXPR('(^/.*/).+$' IN OBJECTNAME GROUP 1) ELSE ''  END"
    );
  }
};

export const calculateScores = async () => {
  // we could put all 3 operations into once Statement, but this is easier to debug

  // First update Scoring Records with latest classification ratings in case those changed
  await db.run(
    'UPDATE kernseife_db_FINDINGRECORDS as s SET messageId = CONCAT((SELECT c.rating_code FROM kernseife_db_CLASSIFICATIONS as c WHERE c.objectType = s.refObjectType AND c.objectName = s.refObjectName), SUBSTRING(s.messageId, 4))'
  );

  // Calculate Score for all Development Objects
  await db.run(
    'UPDATE kernseife_db_DEVELOPMENTOBJECTS as d SET score = IFNULL((' +
      'SELECT IFNULL(sum(r.score),0) AS sum_score ' +
      'FROM kernseife_db_FINDINGRECORDS as f ' +
      'INNER JOIN kernseife_db_RATINGS as r ON r.code = f.messageId ' +
      'WHERE f.objectType = d.objectType AND f.objectName = d.objectName AND f.devClass = d.devClass AND f.systemId = d.systemId AND d.latestFindingImportId = f.import_ID ' +
      'GROUP BY f.import_ID, f.objectType, f.objectName, f.devClass, f.systemId),0)'
  );

  // Set Score to 0 in case there are no findings
  await db.run(
    "UPDATE kernseife_db_DEVELOPMENTOBJECTS as d SET score = 0 WHERE score IS NULL AND latestFindingImportId IS NOT NULL AND latestFindingImportId != ''"
  );

  // Calculate Name spaces
  await calculateNamespaces();
  // Calculate Reference Count & Score
  await db.run(
    'UPDATE kernseife_db_CLASSIFICATIONS as c SET ' +
      'referenceCount =  IFNULL((SELECT SUM(count) FROM kernseife_db_DevelopmentObjectsAggregated as d WHERE d.refObjectType = c.objectType AND d.refObjectName = c.objectName),0),' +
      'totalScore = IFNULL((SELECT SUM(score) FROM kernseife_db_DevelopmentObjectsAggregated as d WHERE d.refObjectType = c.objectType AND d.refObjectName = c.objectName),0)'
  );
};

const calculateScoreAndLevel = async (
  developmentObject: DevelopmentObject
): Promise<{
  score: number;
  potentialScore: number;
  level: CleanCoreLevel;
  potentialLevel: CleanCoreLevel;
}> => {
  const result = await SELECT.from(entities.FindingRecords)
    .columns(
      `sum(rating.score) as score`,
      `sum(potentialRating.score) as potentialScore`,
      `max(rating.level) as level`,
      `max(potentialRating.level) as potentialLevel`
    )
    .where({
      import_ID: developmentObject.latestFindingImportId,
      objectType: developmentObject.objectType,
      objectName: developmentObject.objectName,
      devClass: developmentObject.devClass
    })
    .groupBy('objectType', 'objectName', 'devClass');
  return {
    score: result[0]?.score || 0,
    potentialScore: result[0]?.potentialScore || result[0]?.score || 0,
    level: result[0]?.level || CleanCoreLevel.A,
    potentialLevel:
      result[0]?.potentialLevel || result[0]?.level || CleanCoreLevel.A
  };
};

export const getDevelopmentObjectIdentifier = (
  object: FindingRecord | DevelopmentObject
) => {
  return (
    (object.systemId || '') +
    (object.devClass || '') +
    (object.objectType || '') +
    (object.objectName || '')
  );
};

export const getDevelopmentObjectMap = async () => {
  const developmentObjectDB = await SELECT.from(entities.DevelopmentObjects);
  return developmentObjectDB.reduce((map, developmentObject) => {
    return map.set(
      getDevelopmentObjectIdentifier(developmentObject),
      developmentObject
    );
  }, new Map<string, DevelopmentObject>()) as Map<string, DevelopmentObject>;
};

export const importFinding = async (
  findingImport: Import,
  tx?: Transaction,
  updateProgress?: (progress: number) => Promise<void>
) => {
  if (!findingImport.file) throw new Error('File broken');

  const csv = await text(findingImport.file);
  const result = papa.parse<any>(csv, {
    header: true,
    skipEmptyLines: true
  });

  const successorMap = await getSuccessorRatingMap();

  const itemIdSet = new Set();

  const findingRecordList = result.data
    .map((finding) => {
      if (itemIdSet.has(finding.itemId || finding.ITEMID || finding.itemID)) {
        // duplicate!
        throw new Error(
          'Duplicate ItemId ' +
            (finding.itemId || finding.ITEMID || finding.itemID)
        );
      }

      itemIdSet.add(finding.itemId || finding.ITEMID || finding.itemID);

      const findingRecord = {
        // Map Attribues
        import_ID: findingImport.ID,
        systemId: findingImport.systemId,
        itemId: finding.itemId || finding.ITEMID || finding.itemID,
        objectType: finding.objectType || finding.OBJECTTYPE,
        objectName: finding.objectName || finding.OBJECTNAME,
        devClass: finding.devClass || finding.DEVCLASS,
        softwareComponent:
          finding.softwareComponent || finding.SOFTWARECOMPONENT,
        refObjectType: finding.refObjectType || finding.REFOBJECTTYPE,
        refObjectName: finding.refObjectName || finding.REFOBJECTNAME,
        messageId:
          finding.messageId ||
          finding.MESSAGEID ||
          finding.messageid ||
          finding.MESSAGE_ID
      } as FindingRecord;

      // Calculate Potential Message Id
      // check if messageId ends with _SUC
      if (!findingRecord.messageId) {
        LOG.error('Missing MessageId', { finding, findingRecord });
      }

      if (findingRecord.messageId!.endsWith('_SUC')) {
        // Find Successors
        const successorKey = getSuccessorKey(
          finding.refObjectType,
          finding.refObjectName
        );
        findingRecord.potentialMessageId = successorMap.get(successorKey);
      }
      if (!findingRecord.potentialMessageId) {
        // No Successor, so use the same as messageId
        findingRecord.potentialMessageId = findingRecord.messageId;
      }

      return findingRecord;
    })
    .filter((finding) => {
      if (!finding.objectType || !finding.objectName) {
        LOG.warn('Invalid finding', { finding });
        return false;
      }
      return true;
    });

  if (findingRecordList == null || findingRecordList.length == 0) {
    LOG.info('No Records to import');
    return;
  }

  await INSERT.into(entities.FindingRecords).entries(findingRecordList);
  if (tx) {
    await tx.commit();
  }

  LOG.info(`Importing Findings ${findingRecordList.length}`);

  // Remove all Development Objects for this System
  // may be in the future we do a versioning per Run
  await DELETE(entities.DevelopmentObjects).where({
    systemId: findingImport.systemId
  });

  let progressCount = 0;
  let insertCount = 0;
  const chunkSize = 1000;

  const map = new Map<string, string>();

  // Only look at the Language Version Findings, as there should exist only one per Development Object
  // use splice instead of filter to reduce memory usage
  let j = 0;
  for (let i = 0, l = findingRecordList.length; i < l; i++) {
    const messageId = findingRecordList[i].messageId;
    if (messageId == 'X' || messageId == '2' || messageId == '5') {
      const id = getDevelopmentObjectIdentifier(findingRecordList[i]);
      if (map.has(id)) {
        // already exists, skip this record
        LOG.error(`Development Object exists multiple times: ${id}`);
        continue;
      }
      findingRecordList[j++] = findingRecordList[i];
      map.set(id, messageId);
    }
  }
  findingRecordList.length = j;

  for (let i = 0; i < findingRecordList.length; i += chunkSize) {
    LOG.info(`Processing ${i}/${findingRecordList.length}`);
    const chunk = findingRecordList.slice(i, i + chunkSize);

    const developmentObjectInsert = [] as Partial<DevelopmentObject>[];
    for (const findingRecord of chunk) {
      progressCount++;
      // Create a new Development Object
      const developmentObject = {
        objectType: findingRecord.objectType || '',
        objectName: findingRecord.objectName,
        systemId: findingRecord.systemId || '',
        devClass: findingRecord.devClass || '',
        softwareComponent: findingRecord.softwareComponent || '',
        latestFindingImportId: findingImport.ID,
        languageVersion_code: findingRecord.messageId,
        namespace: ''
      } as DevelopmentObject;

      const { score, potentialScore, level, potentialLevel } =
        await calculateScoreAndLevel(developmentObject);
      developmentObject.potentialScore = potentialScore;
      developmentObject.score = score;

      developmentObject.level =
        level == CleanCoreLevel.A &&
        findingRecord.messageId != '5' &&
        findingRecord.messageId != '2' // Key-User is also Part of ABAP Cloud => Level A as well
          ? CleanCoreLevel.B
          : level;

      const supportsABAPCloud = supportslanguageVersions(
        developmentObject.objectType!
      );
      developmentObject.potentialLevel =
        !supportsABAPCloud && potentialLevel == CleanCoreLevel.A
          ? CleanCoreLevel.B
          : potentialLevel; // As if all findings are level A, the object could have Language Version 5
      //TODO We might need to define the list of object types which can have Language Version 5
      developmentObject.namespace = determineNamespace(developmentObject);

      if (
        !developmentObject.devClass ||
        !developmentObject.objectName ||
        !developmentObject.objectType ||
        !developmentObject.systemId
      ) {
        LOG.error('Invalid Development Object', { developmentObject });
      }
      developmentObjectInsert.push(developmentObject);
      insertCount++;
    }
    if (developmentObjectInsert.length > 0) {
      await INSERT.into(entities.DevelopmentObjects).entries(
        developmentObjectInsert
      );
      if (tx) {
        await tx.commit();
      }
    }
    if (updateProgress)
      await updateProgress(
        Math.round((100 / findingRecordList.length) * progressCount)
      );
  }
  if (insertCount > 0) {
    LOG.info(`Inserted ${insertCount} DevelopmentObject(s)`);
  }
};

export const importFindingsById = async (
  findingImportId,
  tx: Transaction,
  updateProgress?: (progress: number) => Promise<void>
) => {
  const findingsRunImport = await SELECT.one
    .from(entities.Imports, (d) => {
      d.ID, d.status, d.title, d.file, d.systemId;
    })
    .where({ ID: findingImportId });
  await importFinding(findingsRunImport, tx, updateProgress);
};
