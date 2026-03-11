import {
  BodyText,
  BoldText,
  Button,
  ButtonExperience,
} from '@components';
import { Colors } from '@colors';
import { CustomerIO } from 'customerio-reactnative';
import React, { useState } from 'react';
import {
  Alert,
  Linking,
  Platform,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
} from 'react-native';
import Geolocation from '@react-native-community/geolocation';
import { request, PERMISSIONS, RESULTS } from 'react-native-permissions';
import { systemWeights } from 'react-native-typography';
import { showMessage } from 'react-native-flash-message';

const LOCATION_PERMISSION =
  Platform.OS === 'ios'
    ? PERMISSIONS.IOS.LOCATION_WHEN_IN_USE
    : PERMISSIONS.ANDROID.ACCESS_FINE_LOCATION;

const PRESETS: { label: string; lat: number; lng: number }[] = [
  { label: 'New York', lat: 40.7128, lng: -74.006 },
  { label: 'London', lat: 51.5074, lng: -0.1278 },
  { label: 'Tokyo', lat: 35.6762, lng: 139.6503 },
  { label: 'Sydney', lat: -33.8688, lng: 151.2093 },
  { label: 'São Paulo', lat: -23.5505, lng: -46.6333 },
  { label: '0, 0', lat: 0, lng: 0 },
];

const OrSeparator = () => (
  <View style={styles.orRow}>
    <View style={styles.orLine} />
    <BodyText style={styles.orText}>OR</BodyText>
    <View style={styles.orLine} />
  </View>
);

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
      showMessage({
        message: 'Please enter valid coordinates',
        type: 'warning',
      });
      return;
    }
    const lat = parseFloat(latText);
    const lng = parseFloat(lonText);
    if (Number.isNaN(lat) || Number.isNaN(lng)) {
      showMessage({
        message: 'Please enter valid coordinates',
        type: 'warning',
      });
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

  /** Option 2: Request permission, then SDK fetches location once. */
  const handleRequestSdkLocationUpdate = async () => {
    try {
      const result = await request(LOCATION_PERMISSION);
      if (result === RESULTS.GRANTED || result === RESULTS.LIMITED) {
        setSdkRequestingLabel(true);
        CustomerIO.location.requestLocationUpdate();
        showMessage({
          message: 'SDK requested location update',
          type: 'success',
        });
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

  /** Option 3: Request permission, get device location, then setLastKnownLocation. */
  const handleUseCurrentLocation = async () => {
    try {
      const result = await request(LOCATION_PERMISSION);
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
        {/* OPTION 1: QUICK PRESETS */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>
            OPTION 1: QUICK PRESETS
          </BodyText>
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

        <OrSeparator />

        {/* OPTION 2: SDK LOCATION */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>
            OPTION 2: SDK LOCATION
          </BodyText>
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

        <OrSeparator />

        {/* OPTION 3: MANUALLY SET FROM DEVICE */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>
            OPTION 3: MANUALLY SET FROM DEVICE
          </BodyText>
          <Button
            title={useCurrentLocationLoading ? '📍  Fetching...' : '📍  Use Current Location'}
            experience={ButtonExperience.normal}
            onPress={handleUseCurrentLocation}
            style={styles.useCurrentButton}
            disabled={useCurrentLocationLoading}
          />
          <BodyText style={styles.hint}>
            Fetches coordinates from device (GPS, Wi‑Fi, or cell) and sends them
            to the SDK via setLastKnownLocation. Label shows source when known
            (e.g. Simulated).
          </BodyText>
        </SectionCard>

        <OrSeparator />

        {/* OPTION 4: MANUAL ENTRY */}
        <SectionCard>
          <BodyText style={styles.sectionHeading}>
            OPTION 4: MANUAL ENTRY
          </BodyText>
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
    gap: 0,
  },
  orRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 16,
    gap: 12,
  },
  orLine: {
    flex: 1,
    height: StyleSheet.hairlineWidth,
    backgroundColor: Colors.bodyText,
  },
  orText: {
    opacity: 0.8,
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
    marginTop: 24,
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
