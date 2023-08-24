import { Alert, AlertButton, AlertOptions } from 'react-native';
import Snackbar, { SnackBarOptions } from 'react-native-snackbar';

class Prompts {
  static showAlert(
    {
      title,
      message,
      buttons,
      options,
    }: {
      title: string;
      message?: string;
      buttons?: AlertButton[];
      options?: AlertOptions;
    } = {
      title: '',
      buttons: [
        {
          text: 'OK',
          // eslint-disable-next-line prettier/prettier
            onPress: () => { },
        },
      ],
      options: { cancelable: true },
    },
  ) {
    Alert.alert(title, message, buttons, options);
  }

  static showSnackbar(
    { text, duration, action }: SnackBarOptions = {
      text: '',
      duration: Snackbar.LENGTH_SHORT,
    },
  ) {
    Snackbar.show({
      text: text,
      duration: duration,
      action: action,
    });
  }
}

export default Prompts;
