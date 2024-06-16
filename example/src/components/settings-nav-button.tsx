import { NavigationProps } from '@navigation';
import { useNavigation } from '@react-navigation/native';
import React from 'react';
import { NavigationButton } from './navigation-button';
export const SettingsNavButton = () => {
  const navigation = useNavigation<NavigationProps>();
  return (
    <NavigationButton
      onPress={() => navigation.navigate('Settings')}
      iconSource={require('@assets/images/settings.png')}
    />
  );
};
