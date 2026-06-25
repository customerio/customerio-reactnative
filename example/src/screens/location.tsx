import {
  BodyText,
  BoldText,
  Button,
  ButtonExperience,
} from '@components';
import { Colors } from '@colors';
import { CustomerIO } from 'customerio-reactnative';
import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  Alert,
  AppState,
  Linking,
  Platform,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
} from 'react-native';
import Geolocation from '@react-native-community/geolocation';
import { check, request, PERMISSIONS, RESULTS } from 'react-native-permissions';
import { systemWeights } from 'react-native-typography';
import { showMessage } from 'react-native-flash-message';

const LOCATION_PERMISSION =
  Platform.OS === 'ios'
    ? PERMISSIONS.IOS.LOCATION_WHEN_IN_USE
    : PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION;

const BACKGROUND_LOCATION_PERMISSION =
  Platform.OS === 'ios'
    ? PERMISSIONS.IOS.LOCATION_ALWAYS
    : PERMISSIONS.ANDROID.ACCESS_BACKGROUND_LOCATION;

/**
 * Background-location permission state, mirroring the native sample apps.
 * `null` until first queried.
 */
type LocationStatus =
  | 'notDetermined'
  | 'foregroundOnly'
  | 'backgroundGranted'
  | 'denied';

const isGrantedStatus = (status: LocationStatus | null) =>
  status === 'foregroundOnly' || status === 'backgroundGranted';

const PRESETS: { label: string; lat: number; lng: number }[] = [
  { label: 'New York', lat: 40.7128, lng: -74.006 },
  { label: 'London', lat: 51.5074, lng: -0.1278 },
  { label: 'Tokyo', lat: 35.6762, lng: 139.6503 },
  { label: 'Sydney', lat: -33.8688, lng: 151.2093 },
  { label: 'São Paulo', lat: -23.5505, lng: -46.6333 },
  { label: '0, 0', lat: 0, lng: 0 },
];

const SectionCard = ({
  children,
  style,
}: {
  children: React.ReactNode;
  style?: object;
}) => <View style={[styles.sectionCard, style]}>{children}</View>;

function showLocationPermissionAlert() {
  Alert.alert(
    'Location Permission Required',
    'Please enable location access in Settings to use this feature.',
    [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Open Settings', onPress: () => Linking.openSettings() },
    ]
  );
}

export const LocationScreen = () => {
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [lastSetLocation, setLastSetLocation] = useState<{
    lat: number;
    lng: number;
    source: string;
  } | null>(null);
  const [sdkRequestingLabel, setSdkRequestingLabel] = useState(false);
  const [useCurrentLocationLoading, setUseCurrentLocationLoading] = useState(false);

  // Drives the state-aware Background Location button (mirrors the native samples).
  const [locationStatus, setLocationStatus] = useState<LocationStatus | null>(null);
  const locationStatusRef = useRef<LocationStatus | null>(null);
  // Sequence guard: mount, AppState resume, and permission handlers can refresh
  // concurrently — drop a stale completion so it can't overwrite a newer result.
  const refreshSeqRef = useRef(0);

  // Reads current permissions and updates the button state. Returns the resolved
  // status, or null if this run was superseded by a newer one (or errored).
  const refreshLocationStatus = useCallback(async (): Promise<
    LocationStatus | null
  > => {
    const seq = ++refreshSeqRef.current;
    try {
      const foreground = await check(LOCATION_PERMISSION);
      const background = await check(BACKGROUND_LOCATION_PERMISSION);
      // Drop a superseded completion so it can't overwrite a newer refresh.
      if (seq !== refreshSeqRef.current) return null;
      let status: LocationStatus;
      if (background === RESULTS.GRANTED) {
        status = 'backgroundGranted';
      } else if (
        foreground === RESULTS.GRANTED ||
        foreground === RESULTS.LIMITED
      ) {
        status = 'foregroundOnly';
      } else if (foreground === RESULTS.BLOCKED) {
        status = 'denied';
      } else {
        status = 'notDetermined';
      }
      locationStatusRef.current = status;
      setLocationStatus(status);
      return status;
    } catch (e) {
      // Only surface the error if this run is still the latest.
      if (seq === refreshSeqRef.current) {
        showMessage({ message: (e as Error).message, type: 'danger' });
      }
      return null;
    }
  }, []);

  // Query on mount; re-query on resume so the button reflects changes made in
  // Settings, and fetch if a grant happened there. In-app grants fetch directly
  // from their handlers, so this only covers the return-from-Settings path.
  useEffect(() => {
    refreshLocationStatus();
    const subscription = AppState.addEventListener('change', async (state) => {
      if (state !== 'active') return;
      const previous = locationStatusRef.current;
      const status = await refreshLocationStatus();
      // Fetch only when gaining access from a non-granted state — not on a downgrade
      // between granted states (e.g. revoking "Always" back to "When in Use" in Settings).
      // The SDK's auto-fetch hook runs once per process, so a grant made in Settings
      // needs an explicit request to register geofences this session.
      if (status && isGrantedStatus(status) && !isGrantedStatus(previous)) {
        CustomerIO.location.requestLocationUpdate();
      }
    });
    return () => subscription.remove();
  }, [refreshLocationStatus]);

  const setLocation = (lat: number, lng: number, source: string) => {
    try {
      CustomerIO.location.setLastKnownLocation(lat, lng);
      setLastSetLocation({ lat, lng, source });
      setSdkRequestingLabel(false);
      showMessage({
        message: `Location set successfully (${source})`,
        type: 'success',
      });
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const handlePreset = (lat: number, lng: number, presetName: string) => {
    setLocation(lat, lng, presetName);
  };

  const handleManualSet = () => {
    const latText = latitude.trim();
    const lonText = longitude.trim();
    if (!latText || !lonText) {
      showMessage({ message: 'Please enter valid coordinates', type: 'warning' });
      return;
    }
    const lat = parseFloat(latText);
    const lng = parseFloat(lonText);
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      showMessage({ message: 'Please enter valid coordinates', type: 'warning' });
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      showMessage({
        message: 'Latitude must be -90..90, longitude -180..180',
        type: 'warning',
      });
      return;
    }
    setLocation(lat, lng, 'Manual');
  };

  const backgroundButtonLabel = (() => {
    switch (locationStatus) {
      case 'foregroundOnly':
        return Platform.OS === 'ios'
          ? "Upgrade to 'Always'"
          : 'Allow all the time';
      case 'backgroundGranted':
        return Platform.OS === 'ios' ? 'Always — granted' : 'Background — granted';
      case 'denied':
        return 'Open Settings';
      default:
        return 'Grant location access';
    }
  })();

  const backgroundButtonEnabled = locationStatus !== 'backgroundGranted';

  const showOpenSettingsDialog = () => {
    Alert.alert(
      'Location Permission Required',
      'Location permission is denied. Please enable it from app settings.',
      [
        { text: 'Open Settings', onPress: () => Linking.openSettings() },
        { text: 'OK', style: 'cancel' },
      ]
    );
  };

  /** Escalate to background ("Always"/"Allow all the time") after foreground is granted. */
  const requestBackgroundLocation = async () => {
    try {
      const result = await request(BACKGROUND_LOCATION_PERMISSION);
      await refreshLocationStatus();
      if (result === RESULTS.GRANTED) {
        // Fetch so geofences register now (auto-fetch already ran this process).
        CustomerIO.location.requestLocationUpdate();
        showMessage({
          message: 'Background location granted — fetching location to start geofence',
          type: 'success',
        });
      } else if (result === RESULTS.BLOCKED) {
        showOpenSettingsDialog();
      } else {
        // iOS resolves the "Always" prompt asynchronously; the button updates on
        // resume, which fetches if granted. Point the user to Settings otherwise.
        showMessage({
          message:
            'Requesting background location — enable "Always" in Settings if no prompt appears',
          type: 'info',
        });
      }
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const showBackgroundRationale = () => {
    Alert.alert(
      'Allow background location?',
      'Geofence transitions only fire while the app is backgrounded if you grant ' +
        '"Always" / "Allow all the time". If no prompt appears, use Open Settings.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Open Settings', onPress: () => Linking.openSettings() },
        { text: 'Continue', onPress: () => requestBackgroundLocation() },
      ]
    );
  };

  /** State-aware Background Location action, matching the native sample apps. */
  const handleBackgroundLocationTap = async () => {
    switch (locationStatus) {
      case 'foregroundOnly':
        showBackgroundRationale();
        return;
      case 'backgroundGranted':
        return;
      case 'denied':
        Linking.openSettings();
        return;
      default: {
        // notDetermined: request foreground first, then escalate to background.
        const result = await request(LOCATION_PERMISSION);
        await refreshLocationStatus();
        if (result === RESULTS.GRANTED || result === RESULTS.LIMITED) {
          // Foreground granted — fetch so geofences register, then offer background.
          CustomerIO.location.requestLocationUpdate();
          showBackgroundRationale();
        } else if (result === RESULTS.BLOCKED) {
          showOpenSettingsDialog();
        } else {
          showMessage({ message: 'Location permission denied', type: 'info' });
        }
      }
    }
  };

  /** Request permission, then SDK fetches location once. */
  const handleRequestSdkLocationUpdate = async () => {
    try {
      const result = await request(LOCATION_PERMISSION);
      await refreshLocationStatus();
      if (result === RESULTS.GRANTED || result === RESULTS.LIMITED) {
        setSdkRequestingLabel(true);
        CustomerIO.location.requestLocationUpdate();
        showMessage({ message: 'SDK requested location update', type: 'success' });
      } else if (result === RESULTS.DENIED || result === RESULTS.BLOCKED) {
        showLocationPermissionAlert();
      } else {
        showMessage({
          message: 'Location is not available on this device.',
          type: 'info',
        });
      }
    } catch (e) {
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  /** Request permission, get device location, then setLastKnownLocation. */
  const handleUseCurrentLocation = async () => {
    try {
      const result = await request(LOCATION_PERMISSION);
      await refreshLocationStatus();
      if (result === RESULTS.GRANTED || result === RESULTS.LIMITED) {
        setUseCurrentLocationLoading(true);
        Geolocation.getCurrentPosition(
          (position) => {
            const lat = position.coords.latitude;
            const lng = position.coords.longitude;
            setUseCurrentLocationLoading(false);
            setLocation(lat, lng, 'Device');
          },
          (error) => {
            setUseCurrentLocationLoading(false);
            showMessage({
              message: `Failed to get location: ${error.message}`,
              type: 'danger',
            });
          },
          { enableHighAccuracy: false, timeout: 15000, maximumAge: 10000 }
        );
      } else if (result === RESULTS.DENIED || result === RESULTS.BLOCKED) {
        showLocationPermissionAlert();
      } else {
        showMessage({
          message: 'Location is not available on this device.',
          type: 'info',
        });
      }
    } catch (e) {
      setUseCurrentLocationLoading(false);
      showMessage({ message: (e as Error).message, type: 'danger' });
    }
  };

  const statusText = sdkRequestingLabel
    ? 'Requesting location once (SDK)...'
    : lastSetLocation
      ? `Last set: ${lastSetLocation.lat.toFixed(4)}, ${lastSetLocation.lng.toFixed(4)} (${lastSetLocation.source})`
      : 'No location set yet';

  return (
    <ScrollView contentContainerStyle={styles.scrollContent}>
      <View style={styles.container}>
        {/* Background Location (geofence permission) */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>Background Location</BodyText>
          <Button
            title={backgroundButtonLabel}
            experience={ButtonExperience.callToAction}
            onPress={handleBackgroundLocationTap}
            disabled={!backgroundButtonEnabled}
          />
          <BodyText style={styles.hint}>
            Geofence runs automatically once enabled, but needs background
            ("Always" / "Allow all the time") location to deliver transitions
            while the app is closed. This grants foreground access first, then
            escalates to background.
          </BodyText>
        </SectionCard>

        {/* SDK Location */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>SDK Location</BodyText>
          <Button
            title="Request location once (SDK)"
            experience={ButtonExperience.normal}
            onPress={handleRequestSdkLocationUpdate}
          />
          <BodyText style={styles.hint}>
            Ask for permission if needed, then SDK fetches location once. The SDK
            stops any in-flight request when the app goes to background.
          </BodyText>
        </SectionCard>

        {/* Quick Presets */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>Quick Presets</BodyText>
          <View style={styles.presetGrid}>
            {PRESETS.map(({ label, lat, lng }) => (
              <Button
                key={label}
                title={label}
                experience={ButtonExperience.normal}
                onPress={() => handlePreset(lat, lng, label)}
                style={styles.presetButton}
              />
            ))}
          </View>
          <BodyText style={styles.hint}>Tap a city to set its coordinates</BodyText>
        </SectionCard>

        {/* Use Current Location */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>Use Current Location</BodyText>
          <Button
            title={useCurrentLocationLoading ? '📍  Fetching...' : '📍  Use Current Location'}
            experience={ButtonExperience.normal}
            onPress={handleUseCurrentLocation}
            style={styles.useCurrentButton}
            disabled={useCurrentLocationLoading}
          />
          <BodyText style={styles.hint}>
            Fetches coordinates from device (GPS, Wi‑Fi, or cell) and sends them
            to the SDK via setLastKnownLocation.
          </BodyText>
        </SectionCard>

        {/* Manual Entry */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>Manual Entry</BodyText>
          <View style={styles.fieldBlock}>
            <BoldText style={styles.fieldLabel}>Latitude</BoldText>
            <TextInput
              style={styles.fieldInput}
              value={latitude}
              onChangeText={setLatitude}
              keyboardType="numeric"
              placeholder="e.g., 40.7128"
              placeholderTextColor={Colors.bodySecondaryText}
              editable
            />
          </View>
          <View style={styles.fieldBlock}>
            <BoldText style={styles.fieldLabel}>Longitude</BoldText>
            <TextInput
              style={styles.fieldInput}
              value={longitude}
              onChangeText={setLongitude}
              keyboardType="numeric"
              placeholder="e.g., -74.0060"
              placeholderTextColor={Colors.bodySecondaryText}
              editable
            />
          </View>
          <View style={styles.setLocationButtonWrap}>
            <Button
              title="Set Location"
              experience={ButtonExperience.callToAction}
              onPress={handleManualSet}
            />
          </View>
          <BodyText style={styles.hint}>Enter custom coordinates</BodyText>
        </SectionCard>

        {/* Status */}
        <View style={styles.statusCard}>
          <BodyText style={styles.statusText}>{statusText}</BodyText>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  scrollContent: {
    paddingBottom: 24,
  },
  container: {
    padding: 16,
    gap: 16,
  },
  sectionCard: {
    padding: 16,
    borderRadius: 8,
    backgroundColor: Colors.bodySecondaryBg,
    gap: 12,
  },
  sectionHeading: {
    fontWeight: '700',
    marginBottom: 4,
  },
  presetGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  presetButton: {
    minWidth: '30%',
    flex: 1,
  },
  useCurrentButton: {
    alignSelf: 'stretch',
  },
  hint: {
    opacity: 0.9,
    marginTop: 4,
  },
  setLocationButtonWrap: {
    alignSelf: 'center',
    minWidth: 160,
  },
  fieldBlock: {
    marginBottom: 4,
  },
  fieldLabel: {
    marginBottom: 6,
  },
  fieldInput: {
    borderBottomWidth: 1,
    borderBottomColor: Colors.secondaryBg,
    color: Colors.bodyText,
    paddingVertical: 6,
    ...systemWeights.regular,
  },
  statusCard: {
    marginTop: 8,
    padding: 16,
    borderRadius: 8,
    backgroundColor: Colors.bodySecondaryBg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statusText: {
    textAlign: 'center',
  },
});
