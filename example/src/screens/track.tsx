import { Button, ButtonExperience, TextField } from '@components';

import { NavigationCallbackContext } from '@navigation';
import React, { useContext, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

export const TrackScreen = () => {
  const { onTrackEvent } = useContext(NavigationCallbackContext);
  const [event, setEvent] = useState({
    name: '',
    propertyName: '',
    propertyValue: '',
  });

  return (
    <ScrollView>
      <View style={styles.container}>
        <TextField
          testID="event_name_input"
          label="Event name"
          autoCapitalize="none"
          value={event.name}
          onChangeText={(name) => {
            setEvent({ ...event, ...{ name } });
          }}
        />
        <TextField
          testID="property_name_input"
          label="Property name"
          value={event.propertyName}
          autoCapitalize="none"
          onChangeText={(propertyName) => {
            setEvent({
              ...event,
              ...{ propertyName },
            });
          }}
        />

        <TextField
          testID="property_value_input"
          label="Property value"
          value={event.propertyValue}
          autoCapitalize="none"
          onChangeText={(propertyValue) => {
            setEvent({
              ...event,
              ...{ propertyValue },
            });
          }}
        />

        <Button
          testID="send_event_button"
          title="Send Event"
          experience={ButtonExperience.callToAction}
          onPress={async () => {
            onTrackEvent({
              name: event.name,
              properties: {
                [event.propertyName]: event.propertyValue,
              },
            });

            showMessage({
              message: 'Event sent successfully',
              type: 'success',
            });
          }}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    gap: 16,
    padding: 16,
  },
});
