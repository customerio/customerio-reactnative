import Clipboard from '@react-native-clipboard/clipboard';
import React from 'react';
import {
  Image,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
} from 'react-native';
import Snackbar from 'react-native-snackbar';
import { Colors } from '../colors';
import { BodyText } from './text';
interface Props extends React.ComponentProps<typeof Text> {
  style?: object;
}

export const CopyableText = (props: Props) => {
  return (
    <TouchableOpacity
      style={styles.container}
      onPress={() => {
        Clipboard.setString(props.children?.toString() || '');
        Snackbar.show({
          text: `Copied to clipboard: ${props.children}`,
          duration: Snackbar.LENGTH_SHORT,
        });
      }}
    >
      <Image
        source={require('@assets/images/copy-icon.png')}
        style={styles.copyIcon}
        tintColor={Colors.bodyText}
      />
      <ScrollView directionalLockEnabled={true} horizontal={true}>
        <BodyText lineBreakMode="tail" numberOfLines={1} {...props} />
      </ScrollView>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    flexShrink: 1,
    alignItems: 'center',
  },

  copyIcon: {
    width: 16,
    height: 16,
  },
});
