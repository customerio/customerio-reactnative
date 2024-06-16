import { Colors } from '@colors';
import React from 'react';
import { Text as RNText, StyleSheet } from 'react-native';
import { human, systemWeights } from 'react-native-typography';
import { mergeProps } from './utils';

interface TextProps extends React.ComponentProps<typeof RNText> {
  style?: object;
}
const defaultTextProps = {
  lineBreakMode: 'tail',
  ellipsizeMode: 'tail',
  numberOfLines: 0,
  style: {},
} satisfies TextProps;

const finalProps = (props: TextProps, ...styles: object[]) => {
  return mergeProps(defaultTextProps, props, {
    style: [...styles, props.style],
  });
};

export const BodyText = (props: TextProps) => {
  return <RNText {...finalProps(props, [human.bodyObject, styles.text])} />;
};

export const BoldText = (props: TextProps) => {
  return (
    <RNText
      {...finalProps(props, [
        human.bodyObject,
        systemWeights.bold,
        styles.text,
      ])}
    />
  );
};

export const LargeBoldText = (props: TextProps) => {
  return (
    <RNText
      {...finalProps(props, [
        human.title3Object,
        systemWeights.bold,
        styles.text,
      ])}
    />
  );
};

export const SmallFootnote = (props: TextProps) => {
  return <RNText {...finalProps(props, [human.footnoteObject, styles.text])} />;
};

const styles = StyleSheet.create({
  text: {
    color: Colors.bodyText,
  },
});
