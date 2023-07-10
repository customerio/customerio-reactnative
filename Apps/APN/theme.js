import { createContext, useContext } from 'react';
import { StyleSheet } from 'react-native';

export const ThemeContext = createContext(theme);

export function useThemeContext() {
  return useContext(ThemeContext);
}

export function getDefaultTheme() {
  return theme;
}

const theme = {
  styles: StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: '#fff',
    },
    text: {
      color: '#000000',
      fontFamily: 'Roboto',
      textAlign: 'center',
    },
  }),
};
