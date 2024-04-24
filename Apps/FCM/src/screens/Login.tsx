import { NavigationProp, ParamListBase } from '@react-navigation/native';
import React, { useRef, useState } from 'react';
import { Image, StyleSheet, TouchableOpacity, View } from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import BuildInfoText from '../components/BuildInfoText';
import { FilledButton, TextButton } from '../components/Button';
import { Text } from '../components/Text';
import { TextField } from '../components/TextField';
import * as Colors from '../constants/Colors';
import * as Sizes from '../constants/Sizes';
import { Screen } from '../data/enums/Screen';
import User from '../data/models/user';
import { useUserStateContext } from '../state/userState';
import { navigateToScreen } from '../utils/navigation';
import Prompts from '../utils/prompts';
import { InlineView } from "customerio-reactnative";

interface LoginProps {
  navigation: NavigationProp<ParamListBase>;
}

const Login: React.FC<LoginProps> = ({ navigation }) => {
  const { onUserStateChanged } = useUserStateContext();

  const [email, setEmail] = useState('');
  const [name, setName] = useState('');

  const handleSettingsPress = () => {
    navigateToScreen(navigation, Screen.SETTINGS);
  };

  const handleLoginPress = () => {
    const trimmedEmail = email.trim();
    if (!validateEmail(trimmedEmail)) {
      Prompts.showAlert({
        title: 'Error',
        message: 'Please enter valid email',
      });
      return;
    }
    performLogin(new User(trimmedEmail, { name: name }));
  };

  const validateEmail = (text: string) => {
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
      () => whitelist[Math.floor(Math.random() * whitelist.length)],
    );
    const username = random.join('');
    performLogin(new User(`${username}@customer.io`, { name: '' }));
  };

  const performLogin = async (user: User) => {
    await onUserStateChanged(user);
  };

  const firstNameRef = useRef();
  const emailRef = useRef();

  // Now that we have a RN View for displaying inline in-app messages, we can add it to our app's UI. (I added the View to the Login page for simple demonstration purposes. You can add it to any page in your app.)
  // See <InlineView> below. Developers set a hard-coded width and set a flexible height. 
  return (
    <View style={styles.container}>
      <View style={styles.topBar}>
        <TouchableOpacity
          style={styles.settingsButton}
          onPress={handleSettingsPress}
          accessibilityLabel="Settings">
          <Image
            source={require('../../assets/images/ic_settings.png')}
            style={styles.settingsIcon}
          />
        </TouchableOpacity>
      </View>

      <InlineView style={{width: 350, flex: 1}} />

        <BuildInfoText />
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
    fontSize: 22,
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
  textInputContainer: {
    marginVertical: 10,
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
