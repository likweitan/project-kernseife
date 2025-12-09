import { entities, log } from '@sap/cds';
import { remoteServiceCall } from '../lib/connectivity';
import { System } from '#cds-models/kernseife/db';
import {
  DevelopmentObjectImport,
  FindingImport,
  ProjectImport
} from '../types/imports';

export const BTP_CONNECTOR_PATH =
  '/sap/opu/odata4/sap/zknsf_btp_connector/srvd/sap/zknsf_btp_connector/0001/';

const LOG = log('BTP Connector');

export const setupProject = async (destination: string) => {
  const response = await remoteServiceCall({
    destinationName: destination,
    method: 'POST',
    url:
      BTP_CONNECTOR_PATH +
      'ZKNSF_I_PROJECTS/com.sap.gateway.srvd.zknsf_btp_connector.v0001.Setup',
    data: {}
  });
  LOG.info(
    `Received response from Destination ${destination}: ${response.message}`
  );
  return response.message;
};

export const getProject = async (
  destination: string
): Promise<ProjectImport> => {
  // Read Project
  const response = await remoteServiceCall({
    destinationName: destination,
    method: 'GET',
    url: BTP_CONNECTOR_PATH + 'ZKNSF_I_PROJECTS'
  });
  LOG.info(
    `Received response from Destination ${destination}: ${JSON.stringify(response?.result?.value)}`
  );
  return response.result.value[0] as ProjectImport;
};

export const triggerAtcRun = async (destination: string) => {
  const response = await remoteServiceCall({
    destinationName: destination,
    method: 'POST',
    url:
      BTP_CONNECTOR_PATH +
      'ZKNSF_I_PROJECTS/com.sap.gateway.srvd.zknsf_btp_connector.v0001.RunATC',
    data: {}
  });
  LOG.info(
    `Received response from Destination ${destination}: ${response.message}`
  );
  return response.message;
};


export const getDevelopmentObjects = async (
  destination: string,
  projectId: string,
  top: number,
  skip: number
): Promise<DevelopmentObjectImport[]> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: destination,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_DEVELOPMENT_OBJECTS?$top=${top}&$skip=${skip}&$expand=_findings,_metrics,_usages&$filter=projectId eq ${projectId}`
  });
  // LOG.info(
  //   `Received response from Destination ${destination}: ${JSON.stringify(response?.result?.value)}`
  // );
  return response.result.value as DevelopmentObjectImport[];
};

export const getDevelopmentObjectsCount = async (
  destination: string,
  projectId: string
): Promise<number> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: destination,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_DEVELOPMENT_OBJECTS/$count?$filter=projectId eq ${projectId}`
  });
   LOG.info(
     `Received response from Destination ${destination}: ${JSON.stringify(response?.result)}`
   );
  return response.result as number;
};

export const getFindings = async (
  destination: string,
  projectId: string,
  runId: string,
  top: number,
  skip: number
): Promise<FindingImport[]> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: destination,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_FINDINGS?$top=${top}&$skip=${skip}&$filter=projectId eq ${projectId} and runId eq ${runId}`
  });
  // LOG.info(
  //   `Received response from Destination ${destination}: ${JSON.stringify(response?.result?.value)}`
  // );
  return response.result.value as FindingImport[];
};

export const getFindingsCount = async (
  destination: string,
  projectId: string,
  runId: string
): Promise<number> => {
  // Read Development Objects
  const response = await remoteServiceCall({
    destinationName: destination,
    method: 'GET',
    url:
      BTP_CONNECTOR_PATH +
      `ZKNSF_I_FINDINGS/$count?$filter=projectId eq ${projectId} and runId eq ${runId}`
  });
   LOG.info(
     `Received response from Destination ${destination}: ${JSON.stringify(response?.result)}`
   );
  return response.result as number;
};

export const getDestinationBySystemId = async (systemId: string) => {
  const system: System = await SELECT.one
    .from(entities.Systems)
    .where({ sid: systemId });
  if (!system || !system.destination) {
    throw new Error(`System ${systemId} not found or no destination assigned`);
  }
  return system.destination;
};
