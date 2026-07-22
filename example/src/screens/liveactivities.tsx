import { BodyText, Button, ButtonExperience } from '@components';
import { Colors } from '@colors';
import { CustomerIO } from 'customerio-reactnative';
import React, { useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

const SectionCard = ({ children }: { children: React.ReactNode }) => (
  <View style={styles.sectionCard}>{children}</View>
);

export const LiveActivitiesScreen = () => {
  const [segmentsId, setSegmentsId] = useState<string | null>(null);
  const [segmentsComplete, setSegmentsComplete] = useState(0);
  const [countdownId, setCountdownId] = useState<string | null>(null);

  const segmentsTotal = 4;

  const startSegments = async () => {
    try {
      const id = await CustomerIO.liveActivities.start({
        type: 'segments',
        header: 'Order #4021',
        status: 'Preparing your order',
        segmentsTotal,
        segmentsComplete: 1,
      });
      setSegmentsId(id);
      setSegmentsComplete(1);
      showMessage({ message: `Segments started (${id})`, type: 'success' });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const advanceSegments = async () => {
    if (!segmentsId) return;
    const next = Math.min(segmentsComplete + 1, segmentsTotal);
    try {
      await CustomerIO.liveActivities.update(segmentsId, {
        type: 'segments',
        header: 'Order #4021',
        status: next >= segmentsTotal ? 'Delivered' : 'Out for delivery',
        segmentsTotal,
        segmentsComplete: next,
      });
      setSegmentsComplete(next);
      showMessage({ message: `Segments → ${next}/${segmentsTotal}`, type: 'success' });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const endSegments = async () => {
    if (!segmentsId) return;
    try {
      await CustomerIO.liveActivities.end(segmentsId);
      showMessage({ message: 'Segments ended', type: 'info' });
      setSegmentsId(null);
      setSegmentsComplete(0);
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const startCountdown = async () => {
    try {
      const id = await CustomerIO.liveActivities.start({
        type: 'countdownTimer',
        header: 'Flash Sale',
        title: '50% off ends in',
        statusMessage: 'Hurry!',
        endTime: Math.floor(Date.now() / 1000) + 3600, // epoch seconds, +1h
      });
      setCountdownId(id);
      showMessage({ message: `Countdown started (${id})`, type: 'success' });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const endCountdown = async () => {
    if (!countdownId) return;
    try {
      await CustomerIO.liveActivities.end(countdownId);
      showMessage({ message: 'Countdown ended', type: 'info' });
      setCountdownId(null);
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.scrollContent}>
      <View style={styles.container}>
        <SectionCard>
          <BodyText style={styles.sectionHeading}>SEGMENTS</BodyText>
          <Button
            title="Start Segments"
            experience={ButtonExperience.callToAction}
            onPress={startSegments}
          />
          <Button
            title="Advance Segment (update)"
            experience={ButtonExperience.normal}
            onPress={advanceSegments}
            disabled={!segmentsId}
          />
          <Button
            title="End Segments"
            experience={ButtonExperience.normal}
            onPress={endSegments}
            disabled={!segmentsId}
          />
          <BodyText style={styles.hint}>
            {segmentsId
              ? `Running: ${segmentsComplete}/${segmentsTotal}`
              : 'Not started'}
          </BodyText>
        </SectionCard>

        <SectionCard>
          <BodyText style={styles.sectionHeading}>COUNTDOWN TIMER</BodyText>
          <Button
            title="Start Countdown (+1h)"
            experience={ButtonExperience.callToAction}
            onPress={startCountdown}
          />
          <Button
            title="End Countdown"
            experience={ButtonExperience.normal}
            onPress={endCountdown}
            disabled={!countdownId}
          />
          <BodyText style={styles.hint}>
            {countdownId ? 'Running' : 'Not started'}
          </BodyText>
        </SectionCard>

        <BodyText style={styles.note}>
          Android renders live notifications in-SDK. iOS additionally requires a
          Widget Extension in the app to render the built-in templates.
        </BodyText>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  scrollContent: { paddingBottom: 24 },
  container: { padding: 16, gap: 16 },
  sectionCard: {
    padding: 16,
    borderRadius: 8,
    backgroundColor: Colors.bodySecondaryBg,
    gap: 12,
  },
  sectionHeading: { fontWeight: '700', marginBottom: 4 },
  hint: { opacity: 0.9, marginTop: 4 },
  note: { opacity: 0.8, marginTop: 8, textAlign: 'center' },
});
