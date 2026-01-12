import { Destination } from '#cds-models/kernseife/db';
import { getAllDestinationsFromDestinationService } from '@sap-cloud-sdk/connectivity';
import { context, log } from '@sap/cds';
import { executeHttpRequest } from '@sap-cloud-sdk/http-client';
import { Message } from '../types/connectivity';

const LOG = log('Connectivity');

export const updateDestinations = async () => {
  await DELETE.from('kernseife.db.Destinations');

  const destinations = await getAllDestinationsFromDestinationService();

  await INSERT.into('kernseife.db.Destinations').entries(
    destinations
      .filter(
        (destination) =>
          destination.name != 'ui5' &&
          !destination.name?.endsWith('-html5-repo-host') &&
          !destination.name?.endsWith('-srv') &&
          !destination.name?.endsWith('-auth')
      )
      .map(
        (destination) =>
          ({
            name: destination.name,
            type: destination.type,
            authentication: destination.authentication,
            proxyType: destination.proxyType
          }) as Destination
      )
  );
};

export const remoteServiceCall = async (payload: {
  destinationName: string;
  jwtToken?: string;
  method: 'GET' | 'POST' | 'PUT' | 'DELETE';
  url: string;
  data?: any;
}): Promise<{
  result: any;
  message: Message;
}> => {
  let jwtToken =
    payload.jwtToken || (context?.user as any).authInfo?.config?.jwt;
  // Check if it is actual a JWT Token
  if (jwtToken) {
    if (jwtToken.split('.').length != 3) {
      // It's not a JWT
      jwtToken = undefined;
    }

    // Remove Bearer prefix if exists
    if (jwtToken.startsWith('Bearer ')) {
      jwtToken = jwtToken.substring(7);
    }
  }

  const response = await executeHttpRequest(
    {
      destinationName: payload.destinationName,
      jwt: jwtToken
    },
    {
      method: payload.method,
      url: payload.url,
      data: payload.data
    }
  );
  let message: Message = { message: '', numericSeverity: 0 };
  if (response.headers['sap-messages']) {
    const messages = JSON.parse(response.headers['sap-messages']);
    message = messages.reduce((acc: Message, curr: Message) => {
      if (curr.numericSeverity > acc.numericSeverity) {
        return curr;
      }
      return acc;
    }, message);
    return { result: response.data, message: message };
  }
  return {
    result: response.data,
    message: message
  };
};

export const handleMessage = (req: any, message: Message): void => {
  if (message.numericSeverity == 3) {
    req.warn(message.message);
  } else if (message.numericSeverity === 2) {
    req.notify(message.message);
  } else if (message.numericSeverity === 1) {
    req.info(message.message);
  } else {
    req.reject(400, message.message);
  }
};
