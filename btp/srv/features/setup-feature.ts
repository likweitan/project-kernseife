import {
  Customers,
  Ratings,
  Frameworks,
  System,
  Rating
} from '#cds-models/kernseife/db';
import { entities, log } from '@sap/cds';
import axios from 'axios';
import { loadReleaseState } from './releaseState-feature';
import { remoteServiceCall } from '../lib/connectivity';

const LOG = log('Setup');

export const createInitialData = async (configUrl: string) => {
  if (configUrl) {
    const response = await axios.get<{
      ratingList: Ratings;
      frameworkList: Frameworks;
    }>(configUrl);
    if (response.status != 200) {
      throw new Error('Error fetching Data');
    }

    if (!response.data) {
      throw new Error('No Data found');
    }
    // Check if data is string and parse it
    let configData;
    if (typeof response.data === 'string') {
      configData = JSON.parse(response.data);
    } else {
      configData = response.data;
    }

    LOG.info('Config Data', configData);
    // Fix broken
    await UPDATE.entity(entities.Ratings)
      .set({ setting_ID: '1' })
      .where({ not: { setting_ID: '1' } });
    const ratingCount: { count: number }[] = await SELECT.from(
      entities.Ratings
    ).columns('IFNULL(COUNT( * ),0) as count');
    if (ratingCount[0].count === 0 && configData.ratingList.length > 0) {
      const ratingList = configData.ratingList.map((rating: Rating) => ({
        setting_ID: '1',
        code: rating.code,
        title: rating.title,
        score: rating.score,
        criticality_code: rating.criticality,
        level: rating.level,
        usableInClassification: rating.usableInClassification ?? true
      }));
      await INSERT.into(entities.Ratings).entries(ratingList);
    }

    const frameworkCount = await SELECT.from(entities.Frameworks).columns(
      'IFNULL(COUNT( * ),0) as count'
    );
    if (
      frameworkCount[0]['count'] === 0 &&
      configData.frameworkList &&
      configData.frameworkList.length > 0
    ) {
      await INSERT.into(entities.Frameworks).entries(configData.frameworkList);
    }

    // Create Base Customer
    const customerCount = await SELECT.from(entities.Customers).columns(
      'IFNULL(COUNT( * ),0) as count'
    );
    if (customerCount[0]['count'] === 0) {
      await INSERT.into(entities.Customers).entries([
        {
          setting_ID: '1',
          contact: '<Contact Person>',
          prefix: 'KNSF',
          title: 'Kernseife Customer'
        }
      ] as Customers);
    }
  }

  // Load Release States
  await loadReleaseState();
};
export const setupSystem = async (ref: any) => {
  const system: System = await SELECT.one.from(ref);
  if (!system || !system.destination) {
    return {
      message: 'SYSTEM_NO_DESTINATION',
      numericSeverity: 3
    };
  }

  const result = await remoteServiceCall({
    destinationName: system.destination,
    method: 'POST',
    url: '/sap/opu/odata4/sap/zknsf_btp_connector/srvd/sap/zknsf_btp_connector/0001/ZKNSF_I_PROJECTS/com.sap.gateway.srvd.zknsf_btp_connector.v0001.Setup',
    data: {}
  });
  LOG.info(`Received response from System ${system.sid}: ${result.message}`);
  return result.message;
};
