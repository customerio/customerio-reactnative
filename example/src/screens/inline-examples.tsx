import { InlineInAppMessageView, type InAppMessage } from 'customerio-reactnative';
import React, { useContext } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { NavigationCallbackContext } from '@navigation';

export const InlineExamplesScreen = () => {
  const { onTrackEvent } = useContext(NavigationCallbackContext);

  const handleActionClick = (message: InAppMessage, actionValue: string, actionName: string) => {
    onTrackEvent({
      name: 'example_app_inline_message_action_clicked',
      properties: {
        messageId: message.messageId,
        deliveryId: message.deliveryId,
        elementId: message.elementId,
        actionName,
        actionValue,
      },
    });
  };

  return (
    <View style={styles.container}>
      <InlineInAppMessageView
        elementId="sticky-header"
        style={[styles.inlineMessage, { marginTop: 0 }]}
        onActionClick={handleActionClick}
      />

      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.row}>
          <View style={[styles.image, styles.grayBackground, { aspectRatio: 4 / 3 }]} />
          <View style={styles.textBlock}>
            <View style={[styles.title, styles.grayBackground]} />
            <View style={[styles.subTitle, styles.grayBackground]} />
            <View style={[styles.description, styles.grayBackground]} />
          </View>
        </View>

        <View style={[styles.fullWidthCard, styles.grayBackground]} />

        <View style={styles.row}>
          <View style={[styles.columnCard, styles.grayBackground]} />
          <View style={[styles.columnCard, styles.grayBackground]} />
          <View style={[styles.columnCard, styles.grayBackground]} />
        </View>

        <InlineInAppMessageView
          elementId="inline"
          style={[styles.inlineMessage]}
          onActionClick={handleActionClick}
        />

        <View style={styles.row}>
          <View style={[styles.image, styles.grayBackground, { aspectRatio: 4 / 3 }]} />
          <View style={styles.textBlock}>
            <View style={[styles.title, styles.grayBackground]} />
            <View style={[styles.subTitle, styles.grayBackground]} />
            <View style={[styles.description, styles.grayBackground]} />
          </View>
        </View>

        <View style={[styles.fullWidthCard, styles.grayBackground]} />

        <View style={styles.row}>
          <View style={[styles.columnCard, styles.grayBackground]} />
          <View style={[styles.columnCard, styles.grayBackground]} />
          <View style={[styles.columnCard, styles.grayBackground]} />
        </View>

        <InlineInAppMessageView
          elementId="below-fold"
          style={[styles.inlineMessage]}
          onActionClick={handleActionClick}
        />
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    paddingBottom: 16,
  },
  scrollContent: {
    padding: 16,
  },
  row: {
    flexDirection: 'row',
    marginTop: 16,
  },
  grayBackground: {
    backgroundColor: '#ccc',
  },
  image: {
    width: 150,
    height: undefined,
    borderRadius: 8,
  },
  textBlock: {
    flex: 1,
    marginLeft: 12,
  },
  title: {
    height: 16,
    borderRadius: 8,
  },
  subTitle: {
    height: 16,
    marginTop: 8,
    borderRadius: 8,
  },
  description: {
    flex: 1,
    marginTop: 12,
    borderRadius: 8,
  },
  fullWidthCard: {
    aspectRatio: 10 / 3,
    width: '100%',
    marginTop: 16,
    borderRadius: 8,
  },
  columnCard: {
    flex: 1,
    aspectRatio: 3 / 4,
    marginHorizontal: 4,
    marginTop: 16,
    borderRadius: 8,
  },
  inlineMessage: {
    width: '100%',
    height: 64,
    marginTop: 16,
  },
});