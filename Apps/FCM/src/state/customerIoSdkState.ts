import { Context, createContext, useContext } from 'react';
import CustomerIoSDKConfig from '../data/sdk/CustomerIoSDKConfig';

interface CustomerIoSdkState {
  config?: CustomerIoSDKConfig;
  onSdkConfigStateChanged: (config: CustomerIoSDKConfig) => Promise<void>;
}

export const CustomerIoSdkStateEmpty: CustomerIoSdkState = {
  config: undefined,
  onSdkConfigStateChanged: async () => {},
};

export const CustomerIoSdkContext: Context<CustomerIoSdkState> = createContext(
  CustomerIoSdkStateEmpty,
);

export function useCustomerIoSdkContext(): CustomerIoSdkState {
  return useContext(CustomerIoSdkContext);
}
