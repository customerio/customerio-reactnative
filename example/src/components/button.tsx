import { Colors } from '@colors';
import React from 'react';
import {
  StyleSheet,
  TouchableOpacity,
  TouchableOpacityProps,
} from 'react-native';
import { human, systemWeights } from 'react-native-typography';
import { BoldText } from './text';
import { mergeProps } from './utils';

export enum ButtonExperience {
  normal = 'normal',
  secondary = 'secondary',
  callToAction = 'callToAction',
}

interface Props extends TouchableOpacityProps {
  experience?: ButtonExperience;
  title: string;
}

const getStyles = (experience?: ButtonExperience) => {
  if (!experience) {
    return {
      containerStyle: styles.normalContainer,
      textStyle: styles.normalText,
    };
  }
  switch (experience) {
    case ButtonExperience.normal:
      return {
        containerStyle: styles.normalContainer,
        textStyle: styles.normalText,
      };
    case ButtonExperience.secondary:
      return {
        containerStyle: styles.secondaryContainer,
        textStyle: styles.secondaryText,
      };
    case ButtonExperience.callToAction:
      return {
        containerStyle: styles.ctaContainer,
        textStyle: styles.ctaText,
      };
  }
};

export const Button = ({ title, experience, ...props }: Props) => {
  const { containerStyle, textStyle } = getStyles(experience);

  return (
    <TouchableOpacity
      {...mergeProps(props, {
        style: [styles.container, containerStyle, props.style],
      })}
    >
      <BoldText style={textStyle}>{title}</BoldText>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    justifyContent: 'center',
    paddingVertical: 8,
    borderRadius: 4,
  },

  text: {
    ...human.bodyObject,
    ...systemWeights.bold,
  },

  normalContainer: {
    backgroundColor: Colors.bodySecondaryBg,
  },

  normalText: {
    color: Colors.secondaryText,
  },

  secondaryContainer: {
    padding: 4,
  },
  secondaryText: {
    ...systemWeights.light,
    color: Colors.bodyText,
  },

  ctaContainer: {
    backgroundColor: Colors.primaryBg,
  },

  ctaText: {
    color: Colors.primaryText,
  },
});
