import { BuildInfoText, Button, Profile } from '@components';
import {
  CustomDeviceAttrScreenName,
  CustomProfileAttrScreenName,
  InboxMessagesScreenName,
  InlineExamplesScreenName,
  NavigationCallbackContext,
  NavigationScreenProps,
} from '@navigation';
import { Storage } from '@services';
import { CioPushPermissionStatus } from 'customerio-reactnative';
import React, { useContext, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

export const HomeScreen = ({
  navigation,
}: NavigationScreenProps<'Customer.io'>) => {
  const [user] = useState(Storage.instance.getUser());
  const { onTrackEvent, onPushNotificationRequestPermissionButtonPress } =
    useContext(NavigationCallbackContext);
  return (
    <>
      <ScrollView>
        <View style={styles.container}>
          <Button
            title="Send Random Event"
            onPress={() => {
              onTrackEvent({
                name: 'random_event',
                properties: { random: Math.random() },
              });
              showMessage({
                message: 'Random event sent successfully',
                type: 'success',
              });
            }}
          />
          <Button
            title="Track an Event"
            onPress={() => navigation.navigate('Track')}
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
          <Button
            title="Request Push Notification Permission"
            onPress={async () => {
              const permission = await onPushNotificationRequestPermissionButtonPress();
              if (permission === CioPushPermissionStatus.Granted) {
                showMessage({
                  message: 'Push notifications enabled successfully',
                  type: 'success',
                });
              }
            }}
          />
          <Button
            title="Inline Examples"
            onPress={() => {
              navigation.navigate(InlineExamplesScreenName);
            }}
          />
          <Button
            title="Inbox Messages"
            onPress={() => {
              navigation.navigate(InboxMessagesScreenName);
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
    padding: 16,
  },
  spacer: { flex: 1, justifyContent: 'flex-end' },
});
