import React, { useState } from 'react';
import {
  Image,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import BuildInfoText from '../components/BuildInfoText';
import { FilledButton, TextButton } from '../components/Button';
import * as Colors from '../constants/Colors';
import * as Sizes from '../constants/Sizes';
import Screen from '../data/enums/Screen';
import User from '../data/models/user';
import { useUserStateContext } from '../state/userState';
import { navigateToScreen } from '../utils/navigation';

const Login = ({ navigation }) => {
  const { onUserStateChanged } = useUserStateContext();

  const [email, setEmail] = useState('');
  const [name, setName] = useState('');

  const handleSettingsPress = () => {
    navigateToScreen(navigation, Screen.SETTINGS);
  };

  const handleLoginPress = () => {
    if (!validateEmail(email)) {
      // eslint-disable-next-line no-alert
      alert('Please enter valid email');
      return;
    }
    performLogin(new User(email, { name: name, isGuest: false }));
  };

  const validateEmail = (text) => {
    // Regular expression pattern for email validation
    const emailRegex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i;
    return emailRegex.test(text);
  };

  const handleRandomLoginPress = () => {
    // Repeated numbers to increase the probability in random value
    const whitelist =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    const random = Array.from(
      { length: 10 },
      () => whitelist[Math.floor(Math.random() * whitelist.length)]
    );
    const username = random.join('');
    performLogin(
      new User(`${username}@customer.io`, { name: '', isGuest: true })
    );
  };

  const performLogin = async (user) => {
    onUserStateChanged(user);
  };

  return (
    <View style={styles.container}>
      <View style={styles.topBar}>
        <TouchableOpacity
          style={styles.settingsButton}
          onPress={handleSettingsPress}
        >
          <Image
            source={require('../../assets/images/black-settings-button.png')}
            style={styles.settingsIcon}
          />
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={styles.container}>
        <Text style={styles.title}>React Native APN Ami App</Text>

        <View style={styles.spaceTop} />

        <View style={styles.form}>
          <TextInput
            style={styles.input}
            placeholder="First Name"
            onChangeText={(text) => setName(text)}
            value={name}
          />
          <TextInput
            style={styles.input}
            placeholder="Email"
            onChangeText={(text) => setEmail(text)}
            value={email}
          />
          <FilledButton
            style={styles.loginButton}
            onPress={handleLoginPress}
            text="Login"
            textStyle={styles.loginButtonText}
          />
          <TextButton
            style={styles.randomLoginButton}
            onPress={handleRandomLoginPress}
            text="Generate Random Login"
          />
        </View>

        <View style={styles.spaceBottom} />

        <BuildInfoText style={styles.footerText} />
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: Colors.CONTAINER_BACKGROUND_COLOR,
    flex: 1,
  },
  topBar: {
    alignItems: 'center',
    flexDirection: 'row',
    height: Sizes.TOP_BAR_HEIGHT,
    justifyContent: 'flex-end',
    paddingHorizontal: Sizes.TOP_BAR_PADDING_HORIZONTAL,
  },
  settingsButton: {
    padding: Sizes.IMAGE_BUTTON_PADDING,
  },
  settingsIcon: {
    width: Sizes.IMAGE_BUTTON_ICON_SIZE,
    height: Sizes.IMAGE_BUTTON_ICON_SIZE,
  },
  title: {
    alignSelf: 'center',
    color: Colors.TEXT_COLOR_PRIMARY,
    fontSize: 24,
    fontWeight: Colors.FONT_WEIGHT_REGULAR,
    marginTop: 48,
  },
  spaceTop: {
    flex: 0.6,
  },
  spaceBottom: {
    flex: 1,
  },
  form: {
    alignItems: 'center',
  },
  input: {
    borderBottomWidth: Sizes.INPUT_FIELD_BORDER_WIDTH_BOTTOM,
    borderColor: Colors.INPUT_FIELD_BORDER_COLOR,
    borderRadius: Sizes.INPUT_FIELD_BORDER_RADIUS,
    height: Sizes.INPUT_FIELD_HEIGHT,
    marginVertical: 10,
    maxWidth: Sizes.INPUT_FIELD_MAX_WIDTH,
    paddingHorizontal: Sizes.INPUT_FIELD_PADDING_HORIZONTAL,
    width: '80%',
  },
  loginButton: {
    marginTop: 32,
  },
  loginButtonText: {
    textTransform: 'uppercase',
  },
  randomLoginButton: {
    marginTop: 16,
  },
});

export default Login;
