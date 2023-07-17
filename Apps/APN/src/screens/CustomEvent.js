import React, { useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import { FilledButton } from '../components/Button';
import { TextField } from '../components/TextField';
import * as Colors from '../constants/Colors';
import CustomerIOService from '../services/CustomerIOService';
import Prompts from '../utils/prompts';
import { Text } from '../components/Text';

const CustomEvent = () => {
  const [eventName, setEventName] = useState('');
  const [propertyName, setPropertyName] = useState('');
  const [propertyValue, setPropertyValue] = useState('');

  const isFormValid = () => {
    let message;
    let emptyFieldMessageBuilder = (fieldName) => {
      return `${fieldName} cannot be empty`;
    };

    if (!eventName) {
      message = emptyFieldMessageBuilder('Event Name');
    }

    if (message) {
      Prompts.showAlert({
        title: 'Error',
        message: message,
      });
      return false;
    }
    return true;
  };

  const handleSendPress = () => {
    if (!isFormValid()) {
      return;
    }

    CustomerIOService.sendEvent(eventName, propertyName, propertyValue);
    Prompts.showSnackbar({ text: 'Event sent successfully' });
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.content}>
        <Text style={styles.title}>Send Custom Event</Text>

        <TextField
          style={styles.textInputContainer}
          label="Event Name"
          placeholder=""
          onChangeText={(text) => setEventName(text)}
          value={eventName}
        />

        <TextField
          style={styles.textInputContainer}
          label="Property Name"
          placeholder=""
          onChangeText={(text) => setPropertyName(text)}
          value={propertyName}
        />

        <TextField
          style={styles.textInputContainer}
          label="Property Value"
          placeholder=""
          onChangeText={(text) => setPropertyValue(text)}
          value={propertyValue}
        />

        <FilledButton
          style={styles.sendButton}
          onPress={handleSendPress}
          text="Send Event"
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.CONTAINER_BACKGROUND_COLOR,
    flex: 1,
  },
  content: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 20,
  },
  title: {
    alignSelf: 'flex-start',
    fontSize: 22,
    marginBottom: 32,
  },
  textInputContainer: {
    marginBottom: 8,
  },
  sendButton: {
    marginTop: 24,
  },
});

export default CustomEvent;
