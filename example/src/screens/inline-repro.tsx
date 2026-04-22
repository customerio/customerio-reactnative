import { Button } from '@components';
import { InlineInAppMessageView } from 'customerio-reactnative';
import React, { useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';

// Repro harness for the iOS inline in-app crash / init-never-called finding.
// Run on iOS without the fix applied and watch Xcode console for [CIO-REPRO] logs.
export const InlineReproScreen = () => {
  const [mounted, setMounted] = useState(false);
  const [elementId, setElementId] = useState('repro-A');

  return (
    <ScrollView contentContainerStyle={styles.content}>
      <Text style={styles.description}>
        iOS inline in-app repro harness. Watch Xcode console for
        [CIO-REPRO] logs while toggling these buttons.
      </Text>

      <Button
        title={mounted ? 'Unmount inline view' : 'Mount inline view'}
        onPress={() => setMounted((m) => !m)}
      />

      <Button
        title={`Toggle elementId (current: ${elementId})`}
        onPress={() =>
          setElementId((id) => (id === 'repro-A' ? 'repro-B' : 'repro-A'))
        }
      />

      <View style={styles.stage}>
        {mounted ? (
          <InlineInAppMessageView
            elementId={elementId}
            style={styles.inlineMessage}
          />
        ) : (
          <Text style={styles.placeholder}>(view unmounted)</Text>
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  content: {
    padding: 16,
    gap: 16,
  },
  description: {
    fontSize: 14,
    color: '#333',
    backgroundColor: '#fff3cd',
    padding: 12,
    borderRadius: 8,
  },
  stage: {
    minHeight: 120,
    justifyContent: 'center',
  },
  placeholder: {
    textAlign: 'center',
    color: '#999',
  },
  inlineMessage: {
    width: '100%',
    height: 64,
  },
});
