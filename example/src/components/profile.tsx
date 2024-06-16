import {
  LoginScreenName,
  NavigationCallbackContext,
  NavigationProps,
} from '@navigation';
import { Storage } from '@services';
import { User } from '@utils';
import React, { useContext } from 'react';
import { StyleSheet, View } from 'react-native';
import { Colors } from '../colors';
import { Button, ButtonExperience } from './button';
import { CopyableText } from './copyable-text';
import { BodyText, BoldText } from './text';

export const Profile = ({
  user,
  navigation,
}: {
  user: User;
  navigation: NavigationProps;
}) => {
  const { onLogout } = useContext(NavigationCallbackContext);
  return (
    <View style={styles.container}>
      <View style={styles.trait}>
        <BoldText>Idenfitier:</BoldText>
        <CopyableText style={styles.identifier}>{user?.id}</CopyableText>
      </View>

      {user.traits.name && (
        <View style={styles.trait}>
          <BoldText>Name:</BoldText>
          <BodyText>{user?.traits.name}</BodyText>
        </View>
      )}
      {user.traits.email && (
        <View style={styles.trait}>
          <BoldText>Email:</BoldText>
          <BodyText>{user?.traits.email}</BodyText>
        </View>
      )}

      <Button
        title="Logout"
        experience={ButtonExperience.secondary}
        style={styles.logoutButton}
        onPress={async () => {
          await Storage.instance.removeUser();
          navigation.reset({
            index: 0,
            routes: [{ name: LoginScreenName }],
          });
          onLogout();
        }}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'column',
    gap: 8,
    borderRadius: 8,
    backgroundColor: Colors.bodySecondaryBg,
    padding: 8,
  },

  trait: {
    flexDirection: 'row',
    justifyContent: 'flex-start',
    gap: 8,
  },

  logoutButton: {
    marginTop: 8,
    alignSelf: 'flex-start',
  },

  identifier: {
    flexShrink: 1,
    height: 24,
  },
});
