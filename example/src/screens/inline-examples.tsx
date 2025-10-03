import { InlineInAppMessageView, type InAppMessage } from 'customerio-reactnative';
import React, { useContext } from 'react';
import { ScrollView, StyleSheet, View, Text } from 'react-native';
import { NavigationCallbackContext } from '@navigation';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

const Tab = createBottomTabNavigator();

// Helper function to render sample content
const renderSampleContent = () => (
  <>
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
  </>
);

// Single Inline View Screen Component
const SingleInlineScreen = () => {
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
    <ScrollView contentContainerStyle={styles.scrollContent}>
      <Text style={styles.tabDescription}>
        This tab uses elementId: "single-inline"
      </Text>
      
      {renderSampleContent()}

      <InlineInAppMessageView
        elementId="single-inline"
        style={styles.inlineMessage}
        onActionClick={handleActionClick}
      />

      {renderSampleContent()}
    </ScrollView>
  );
};

// Multiple Inline Views Screen Component
const MultipleInlineScreen = () => {
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
    <ScrollView contentContainerStyle={styles.scrollContent}>
      <Text style={styles.tabDescription}>
        This tab uses elementIds: "multi-top", "multi-middle", "multi-bottom"
      </Text>

      <InlineInAppMessageView
        elementId="multi-top"
        style={styles.inlineMessage}
        onActionClick={handleActionClick}
      />

      {renderSampleContent()}

      <InlineInAppMessageView
        elementId="multi-middle"
        style={styles.inlineMessage}
        onActionClick={handleActionClick}
      />

      {renderSampleContent()}

      <InlineInAppMessageView
        elementId="multi-bottom"
        style={styles.inlineMessage}
        onActionClick={handleActionClick}
      />
    </ScrollView>
  );
};

// Main Tab Navigator Component
export const InlineExamplesScreen = () => {
  return (
    <Tab.Navigator
      screenOptions={{
        // Mount on first focus, then keep mounted
        lazy: true,
        // Don't re-render inactive tabs (needs enableFreeze in App.tsx)
        freezeOnBlur: true,
        // Hide tab bar header since we already have the main screen header
        headerShown: false,
      }}
    >
      <Tab.Screen 
        name="Single View" 
        component={SingleInlineScreen}
        options={{
          tabBarLabel: 'Single View',
        }}
      />
      <Tab.Screen 
        name="Multiple Views" 
        component={MultipleInlineScreen}
        options={{
          tabBarLabel: 'Multiple Views',
        }}
      />
    </Tab.Navigator>
  );
};

const styles = StyleSheet.create({
  tabDescription: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    backgroundColor: '#e8f4fd',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
    textAlign: 'center',
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