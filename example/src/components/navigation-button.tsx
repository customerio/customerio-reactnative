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
      style={styles.container}
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
  container: {
    // iOS liquid UI requires slight left padding to center header icons properly
    paddingLeft: 6,
    justifyContent: 'center',
    alignItems: 'center',
  },
  settingsIcon: {
    width: 24,
    height: 24,
  },
});
