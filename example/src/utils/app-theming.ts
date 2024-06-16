import { Colors } from '@colors';
import { NativeStackNavigationOptions } from '@react-navigation/native-stack';
import { systemWeights } from 'react-native-typography';

export const appTheme = {
  dark: false,
  colors: {
    primary: Colors.primaryText,
    background: Colors.bodySecondaryBg,
    card: Colors.secondaryBg,
    text: Colors.bodySecondaryText,
    border: Colors.bodyText,
    notification: Colors.bodyBg,
  },
};

export const screenStylingOptions = {
  headerStyle: {
    backgroundColor: Colors.secondaryBg,
  },
  headerTintColor: Colors.secondaryText,
  headerTitleStyle: {
    fontWeight: systemWeights.bold.fontWeight,
    fontFamily: systemWeights.bold.fontFamily,
    fontSize: systemWeights.bold.fontSize,
  },
  contentStyle: { backgroundColor: Colors.bodyBg, padding: 16 },
  fullScreenGestureEnabled: true,
  headerBackTitleVisible: false,
} satisfies NativeStackNavigationOptions;
