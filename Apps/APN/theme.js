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
      backgroundColor: '#ffffff',
    },
    filledButton: {
      width: '80%',
      maxWidth: 320,
      backgroundColor: '#3C437D',
      paddingVertical: 12,
      paddingHorizontal: 20,
      borderRadius: 4,
    },
    filledButtonText: {
      color: '#FFFFFF',
      fontFamily: 'Roboto',
      fontWeight: 'bold',
      textAlign: 'center',
    },
    input: {
      width: '80%',
      maxWidth: 488,
      height: 40,
      borderBottomWidth: 1,
      borderColor: '#cccccc',
      borderRadius: 4,
      marginVertical: 10,
      paddingHorizontal: 10,
    },
    text: {
      color: '#000000',
      fontFamily: 'Roboto',
    },
    translucentButton: {
      width: '80%',
      maxWidth: 320,
      paddingVertical: 12,
      paddingHorizontal: 20,
      borderRadius: 4,
    },
    translucentButtonText: {
      color: '#7131FF',
      fontFamily: 'Roboto',
      fontWeight: 'bold',
      textAlign: 'center',
    },
    topBar: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'flex-end',
      paddingHorizontal: 16,
      height: 72,
    },
  }),
};
