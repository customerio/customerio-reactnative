import { createContext } from 'react';

export const ScreensContext = createContext<{ moduleName: string }>({
  moduleName: '',
});
