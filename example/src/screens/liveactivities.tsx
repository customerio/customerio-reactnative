import { BodyText, Button, ButtonExperience } from '@components';
import { Colors } from '@colors';
import { CustomerIO, LiveActivityTemplate } from 'customerio-reactnative';
import React, { useState } from 'react';
import { NativeModules, Platform, ScrollView, StyleSheet, View } from 'react-native';
import { showMessage } from 'react-native-flash-message';

// Reverse-DNS identifier for the app-defined "rideshare" activity type. Must match the
// value registered in the SDK config (`liveActivities.customTypes`), the Android
// `createLiveNotification` callback, and the iOS widget's `RideshareAttributes`.
const RIDESHARE_TYPE = 'io.customer.livenotifications.custom.rideshare';

// iOS custom Live Activities are app-owned: the sample ships its own native module
// (SampleCustomLiveActivity) + Widget Extension rather than driving them from the wrapper.
const { SampleCustomLiveActivity } = NativeModules;

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
      await CustomerIO.liveActivities.end(countdownId);
      showMessage({ message: 'Countdown ended', type: 'info' });
      setCountdownId(null);
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  // Custom (app-defined) template — "Rideshare".
  //
  // Android renders custom live notifications through the app's
  // `CustomerIOPushNotificationCallback.createLiveNotification` (wired in MainApplication),
  // so the wrapper's `startCustom`/`end` drive it directly.
  //
  // iOS custom activities require an app-owned Widget Extension + ActivityAttributes, so the
  // wrapper can't data-drive them; the sample calls its own native module instead.
  const startCustom = async () => {
    try {
      const id =
        Platform.OS === 'ios'
          ? await SampleCustomLiveActivity.startRideshare('Alex', 'On the way', 5)
          : await CustomerIO.liveActivities.startCustom(RIDESHARE_TYPE, {
              driverName: 'Alex',
              status: 'On the way',
              etaMinutes: 5,
            });
      setCustomId(id);
      showMessage({ message: `Rideshare started (${id})`, type: 'success' });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const updateCustom = async () => {
    if (!customId) return;
    try {
      if (Platform.OS === 'ios') {
        await SampleCustomLiveActivity.updateRideshare(customId, 'Almost there', 2);
      } else {
        // Android has no by-id update for custom types: `startCustom` always mints a new
        // notification. End the current one first so we replace it in place instead of
        // stacking a second notification and orphaning the previous one.
        await CustomerIO.liveActivities.end(customId);
        const id = await CustomerIO.liveActivities.startCustom(RIDESHARE_TYPE, {
          driverName: 'Alex',
          status: 'Almost there',
          etaMinutes: 2,
        });
        setCustomId(id);
      }
      showMessage({ message: 'Rideshare updated', type: 'success' });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const endCustom = async () => {
    if (!customId) return;
    try {
      if (Platform.OS === 'ios') {
        await SampleCustomLiveActivity.endRideshare(customId);
      } else {
        await CustomerIO.liveActivities.end(customId);
      }
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
          Android renders live notifications in-SDK (custom types via the app's
          createLiveNotification callback). iOS additionally requires a Widget Extension in
          the app to render the built-in templates and app-owned custom activities.
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
