import { Alert } from 'react-native';
import Snackbar from 'react-native-snackbar';

class Prompts {
  static showAlert(
    { title, message, buttons, options } = {
      title: null,
      message: null,
      buttons: {
        text: 'OK',
        // eslint-disable-next-line prettier/prettier
        onPress: () => { },
      },
      options: {
        cancelable: true,
      },
    }
  ) {
    Alert.alert(title, message, buttons, options);
  }

  static showSnackbar(
    { text, duration, action } = {
      text: null,
      duration: Snackbar.LENGTH_SHORT,
      action: null,
    }
  ) {
    Snackbar.show({
      text: text,
      duration: duration,
      action: action,
    });
  }
}

export default Prompts;
