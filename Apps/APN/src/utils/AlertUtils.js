import { Alert } from 'react-native';

class AlertUtils {
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
}

export default AlertUtils;
