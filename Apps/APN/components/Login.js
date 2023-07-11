import React, { useEffect, useState } from 'react';
import {
  Image,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { ScrollView } from 'react-native-gesture-handler';
import CioManager from '../manager/CioManager';
import CioKeyValueStorage from '../manager/KeyValueStorage';
import { useThemeContext } from '../theme';

const Login = ({ navigation }) => {
  const theme = useThemeContext();

  const styles = StyleSheet.create({
    container: theme.styles.container,
    topBar: theme.styles.topBar,
    settingsButton: {
      padding: 16,
    },
    settingsIcon: {
      width: 24,
      height: 24,
    },
    title: {
      ...theme.styles.text,
      fontSize: 24,
      fontWeight: '400',
      marginTop: 48,
      alignSelf: 'center',
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
    input: theme.styles.input,
    loginButton: {
      ...theme.styles.filledButton,
      marginTop: 32,
    },
    loginButtonText: {
      ...theme.styles.filledButtonText,
      textTransform: 'uppercase',
    },
    randomLoginButton: {
      ...theme.styles.translucentButton,
      marginTop: 16,
    },
    randomLoginButtonText: theme.styles.translucentButtonText,
    footerText: {
      fontSize: 12,
      fontWeight: '400',
      marginBottom: 50,
      alignSelf: 'center',
    },
  });

  const [email, setEmail] = useState('');
  const [name, setName] = useState('');
  const [buildInfo, setBuildInfo] = useState('Fetching build info...');
  const cioManager = new CioManager();

  useEffect(() => {
    const getBuildInfo = async () => {
      try {
        const version = await cioManager.buildInfo();
        setBuildInfo(version);
      } catch (error) {
        console.error('Error:', error);
      }
    };

    getBuildInfo();
  });

  const handleSettingsPress = () => {
    navigation.navigate('SettingsScreen');
  };

  const handleLoginPress = () => {
    if (!validateEmail(email)) {
      // eslint-disable-next-line no-alert
      alert('Please enter valid email');
      return;
    }
    performLogin({
      name: name,
      email: email,
      isGuest: false,
    });
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
    performLogin({
      name: '',
      email: `${username}@customer.io`,
      isGuest: true,
    });
  };

  const performLogin = (user) => {
    const data = {
      first_name: user.name,
      email: user.email,
      is_guest: user.isGuest,
    };
    cioManager.identifyUser(email.trim(), data);

    // Save login status
    const keyStorageObj = new CioKeyValueStorage();
    keyStorageObj.saveLoginStatus(true);
    keyStorageObj.saveLoginDetail({ name: name.trim(), id: email.trim() });
    navigation.navigate('Dashboard');
  };

  return (
    <View style={styles.container}>
      <View style={styles.topBar}>
        <TouchableOpacity
          style={styles.settingsButton}
          onPress={handleSettingsPress}
        >
          <Image
            source={require('../assets/images/black-settings-button.png')}
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
          <TouchableOpacity
            style={styles.loginButton}
            onPress={handleLoginPress}
          >
            <Text style={styles.loginButtonText}>Login</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.randomLoginButton}
            onPress={handleRandomLoginPress}
          >
            <Text style={styles.randomLoginButtonText}>
              Generate Random Login
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.spaceBottom} />

        <Text style={styles.footerText}>{buildInfo}</Text>
      </ScrollView>
    </View>
  );
};

export default Login;
