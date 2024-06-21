import { BuildInfoText, Button, Profile } from '@components';
import {
  CustomDeviceAttrScreenName,
  CustomProfileAttrScreenName,
  NavigationCallbackContext,
  NavigationScreenProps,
} from '@navigation';
import { Storage } from '@services';
import React, { useContext, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

export const HomeScreen = ({
  navigation,
}: NavigationScreenProps<'Customer.io'>) => {
  const [user] = useState(Storage.instance.getUser());
  const { onTrackEvent } = useContext(NavigationCallbackContext);
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
              onTrackEvent({
                name: 'random_event',
                properties: { random: Math.random() },
              });
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
