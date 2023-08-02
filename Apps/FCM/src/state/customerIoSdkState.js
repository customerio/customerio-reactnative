import { createContext, useContext } from 'react';

export const CustomerIoSdkContext = createContext(null);

export function useCustomerIoSdkContext() {
  return useContext(CustomerIoSdkContext);
}
