import { BuildInfoText, Button, Profile } from '@components';
import {
  CustomDeviceAttrScreenName,
  CustomProfileAttrScreenName,
  NavigationScreenProps,
} from '@navigation';
import { Storage } from '@services';
import { CustomerIO } from 'customerio-reactnative';
import React, { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

export const HomeScreen = ({
  navigation,
}: NavigationScreenProps<'Customer.io'>) => {
  const [user] = useState(Storage.instance.getUser());
  return (
    <>
      <ScrollView>
        <View style={styles.container}>
          <Button
            title="Track an Event"
            onPress={() => navigation.navigate('Track')}
          />
          <Button
            title="Send Random Event"
            onPress={() => {
              showMessage({
                message: 'Random event sent',
                type: 'success',
              });
              CustomerIO.track('random_event', { random: Math.random() });
            }}
          />
          <Button
            title="Set Profile Attributes"
            onPress={() => {
              navigation.navigate(CustomProfileAttrScreenName);
            }}
          />
          <Button
            title="Set Device Attributes"
            onPress={() => {
              navigation.navigate(CustomDeviceAttrScreenName);
            }}
          />
        </View>
      </ScrollView>
      <View style={styles.spacer}>
        {user && <Profile user={user!} navigation={navigation} />}
      </View>
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
  spacer: { flex: 1, justifyContent: 'flex-end' },
});
