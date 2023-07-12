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
import BuildInfoText from '../src/components/BuildInfoText';
import User from '../src/data/models/user';
import CustomerIOService from '../src/services/CustomerIOService';
import StorageService from '../src/services/StorageService';
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
  });

  const [email, setEmail] = useState('');
  const [name, setName] = useState('');

  const handleSettingsPress = () => {
    navigation.navigate('SettingsScreen');
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
    const storageService = new StorageService();
    // Save user to storage
    await storageService.saveUser(user);
    // Identify user to Customer.io
    const customerIOService = new CustomerIOService();
    customerIOService.identifyUser(user.email, {
      first_name: user.name,
      email: user.email,
      is_guest: user.isGuest,
    });
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

        <BuildInfoText style={styles.footerText} />
      </ScrollView>
    </View>
  );
};

export default Login;
