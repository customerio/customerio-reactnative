import { Colors } from '@colors';
import React from 'react';
import {
  Image,
  ImageSourcePropType,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';

export const NavigationButton = ({
  onPress,
  iconSource,
  onLongPress,
}: {
  onPress: () => void;
  onLongPress?: () => void;
  iconSource: ImageSourcePropType;
}) => {
  return (
    <TouchableOpacity
      onPress={onPress}
      onLongPress={() => {
        onLongPress?.();
      }}
    >
      <Image
        source={iconSource}
        tintColor={Colors.bodySecondaryText}
        style={styles.settingsIcon}
      />
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  settingsIcon: {
    width: 24,
    height: 24,
  },
});
