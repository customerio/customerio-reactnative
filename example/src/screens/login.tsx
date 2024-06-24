import {
  BuildInfoText,
  Button,
  ButtonExperience,
  TextField,
} from '@components';
import { Storage } from '@services';
import { User, getRandomUser } from '@utils';

import {
  HomeScreenName,
  NavigationCallbackContext,
  NavigationScreenProps,
} from '@navigation';
import React, { useContext } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';
import 'react-native-get-random-values';
import { v4 as uuidv4 } from 'uuid';

export const LogingScreen = ({
  navigation,
}: NavigationScreenProps<'Login'>) => {
  const [user, setUser] = React.useState<User>({
    id: uuidv4(),
    traits: {},
  });

  const { onLogin } = useContext(NavigationCallbackContext);

  return (
    <>
      <ScrollView>
        <View style={styles.container}>
          <TextField
            label="Name"
            value={user.traits.name}
            onChangeText={(name) => {
              setUser({ ...user, traits: { ...user.traits, name } });
            }}
          />
          <TextField
            label="Email"
            value={user.traits.email}
            keyboardType="email-address"
            autoCapitalize="none"
            onChangeText={(email) => {
              setUser({ ...user, traits: { ...user.traits, email } });
            }}
          />

          <Button
            title="Login"
            experience={ButtonExperience.callToAction}
            onPress={async () => {
              await Storage.instance.setUser(user);
              showMessage({
                message: 'Logged in successfully',
                type: 'success',
              });
              onLogin(user);
              navigation.reset({
                index: 0,
                routes: [{ name: HomeScreenName }],
              });
            }}
          />

          <Button
            title="Login with a random user"
            experience={ButtonExperience.secondary}
            onPress={async () => {
              const random = getRandomUser();
              await Storage.instance.setUser(random);
              showMessage({
                message: 'Logged in with a random user',
                type: 'success',
              });
              onLogin(random);
              navigation.reset({
                index: 0,
                routes: [{ name: HomeScreenName }],
              });
            }}
          />
        </View>
      </ScrollView>
      <BuildInfoText />
    </>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    gap: 16,
  },
});
