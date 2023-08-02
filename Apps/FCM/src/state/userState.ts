import { createContext, useContext } from 'react';

export const UserStateContext = createContext(null);

export function useUserStateContext() {
  return useContext(UserStateContext);
}
