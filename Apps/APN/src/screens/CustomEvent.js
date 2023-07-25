import React, { useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import { FilledButton } from '../components/Button';
import { Text } from '../components/Text';
import { TextField } from '../components/TextField';
import * as Colors from '../constants/Colors';
import { trackEvent } from '../services/CustomerIOService';
import Prompts from '../utils/prompts';

const CustomEvent = () => {
  const [eventName, setEventName] = useState('');
  const [propertyName, setPropertyName] = useState('');
  const [propertyValue, setPropertyValue] = useState('');

  const handleSendPress = () => {
    trackEvent(eventName, propertyName, propertyValue);
    Prompts.showSnackbar({ text: 'Event sent successfully' });
  };

  const eventNameRef = useRef();
  const propertyNameRef = useRef();
  const propertyValueRef = useRef();

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
          contentDesc="Event Name Input"
          textInputRef={eventNameRef}
          getNextTextInput={() => ({
            ref: propertyNameRef,
            value: propertyName,
          })}
          textInputProps={{
            autoCapitalize: 'none',
            keyboardType: 'default',
          }}
        />

        <TextField
          style={styles.textInputContainer}
          label="Property Name"
          placeholder=""
          onChangeText={(text) => setPropertyName(text)}
          value={propertyName}
          contentDesc="Property Name Input"
          textInputRef={propertyNameRef}
          getNextTextInput={() => ({
            ref: propertyValueRef,
            value: propertyValue,
          })}
          textInputProps={{
            autoCapitalize: 'none',
            keyboardType: 'default',
          }}
        />

        <TextField
          style={styles.textInputContainer}
          label="Property Value"
          placeholder=""
          onChangeText={(text) => setPropertyValue(text)}
          value={propertyValue}
          contentDesc="Property Value Input"
          textInputRef={propertyValueRef}
          textInputProps={{
            autoCapitalize: 'none',
            keyboardType: 'default',
          }}
        />

        <FilledButton
          style={styles.sendButton}
          onPress={handleSendPress}
          text="Send Event"
          contentDesc="Send Event Button"
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
