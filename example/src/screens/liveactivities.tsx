import { BodyText, Button, ButtonExperience } from '@components';
import { Colors } from '@colors';
import { CustomerIO, LiveActivityTemplate } from 'customerio-reactnative';
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
  const [customId, setCustomId] = useState<string | null>(null);

  const segmentsTotal = 4;

  const startSegments = async () => {
    try {
      const id = await CustomerIO.liveActivities.start({
        type: LiveActivityTemplate.Segments,
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
        type: LiveActivityTemplate.Segments,
        header: 'Order #4021',
        status: next >= segmentsTotal ? 'Delivered' : 'Out for delivery',
        segmentsTotal,
        segmentsComplete: next,
      });
      setSegmentsComplete(next);
      showMessage({
        message: `Segments → ${next}/${segmentsTotal}`,
        type: 'success',
      });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const endSegments = async () => {
    if (!segmentsId) return;
    try {
      // Pass a final content-state so iOS renders a terminal card instead of freezing on the
      // last progress value. Android ignores it and renders its own terminal state.
      await CustomerIO.liveActivities.end(segmentsId, {
        type: LiveActivityTemplate.Segments,
        header: 'Order #4021',
        status: 'Delivered',
        segmentsTotal,
        segmentsComplete: segmentsTotal,
      });
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
        type: LiveActivityTemplate.CountdownTimer,
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
      // Terminal state: drop the endTime so the card reads as finished rather than counting down.
      await CustomerIO.liveActivities.end(countdownId, {
        type: LiveActivityTemplate.CountdownTimer,
        header: 'Flash sale',
        title: 'Sale ended',
        statusMessage: 'Thanks for shopping',
      });
      showMessage({ message: 'Countdown ended', type: 'info' });
      setCountdownId(null);
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  // Custom template — "Rideshare".
  //
  // One code path on both platforms. The SDK owns the attributes type, so the payload is just a
  // map of strings: iOS renders it from `CIOCustomAttributes` in the Widget Extension, Android
  // from the app's `createLiveNotification` callback (wired in MainApplication). The activity is
  // named by `liveNotifications.customType` in the SDK config, not here.
  const rideshare = (status: string, etaMinutes: number) => ({
    type: LiveActivityTemplate.Custom as const,
    // Values are strings — a bridge payload carries no schema, so the widget parses what it needs.
    data: { driverName: 'Alex', status, etaMinutes: String(etaMinutes) },
  });

  const startCustom = async () => {
    try {
      const id = await CustomerIO.liveActivities.start(
        rideshare('On the way', 5)
      );
      setCustomId(id);
      showMessage({ message: `Rideshare started (${id})`, type: 'success' });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const updateCustom = async () => {
    if (!customId) return;
    try {
      await CustomerIO.liveActivities.update(
        customId,
        rideshare('Almost there', 2)
      );
      showMessage({ message: 'Rideshare updated', type: 'success' });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const endCustom = async () => {
    if (!customId) return;
    try {
      // A final content-state so the card reads as finished rather than freezing mid-trip.
      await CustomerIO.liveActivities.end(customId, rideshare('Arrived', 0));
      showMessage({ message: 'Rideshare ended', type: 'info' });
      setCustomId(null);
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

        <SectionCard>
          <BodyText style={styles.sectionHeading}>CUSTOM (RIDESHARE)</BodyText>
          <Button
            title="Start Custom"
            experience={ButtonExperience.callToAction}
            onPress={startCustom}
          />
          <Button
            title="Update Custom"
            experience={ButtonExperience.normal}
            onPress={updateCustom}
            disabled={!customId}
          />
          <Button
            title="End Custom"
            experience={ButtonExperience.normal}
            onPress={endCustom}
            disabled={!customId}
          />
          <BodyText style={styles.hint}>
            {customId ? 'Running' : 'Not started'}
          </BodyText>
        </SectionCard>

        <BodyText style={styles.note}>
          Android renders live notifications in-SDK; custom types go to the app's
          createLiveNotification callback. iOS additionally requires a Widget
          Extension — the SDK ships the SwiftUI for the built-in templates, and
          the app supplies a view for the custom one.
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
