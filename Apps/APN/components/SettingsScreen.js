import React, {useLayoutEffect, useState, useEffect, useRef} from 'react'
import { View, StyleSheet, Text, Alert, Image, Switch, Linking, AppState, TouchableOpacity } from 'react-native';
import Clipboard from '@react-native-clipboard/clipboard';
import { ScrollView, TextInput } from 'react-native-gesture-handler';
import Env from '../env';
import PushNotification from "react-native-push-notification";
import ThemedButton from './common/Button';
import CioKeyValueStorage from '../manager/KeyValueStorage';
import { CustomerIO } from 'customerio-reactnative';
import { set } from 'react-native-reanimated';


const SettingsScreen = ({navigation}) => {
const [deviceToken, setDeviceToken] = useState('')
const [trackUrl, setTrackUrl] = useState('')
const [isDebugModeEnabled, setIsDebugModeEnabled] = useState(true)
const [pushStatus, setPushStatus] = useState('')
const [isPushEnabled, setIsPushEnabled] = useState(false)
const [isTrackDeviceAttributesEnabled, setIsTrackDeviceAttributesEnabled] = useState(true)
const [isTrackScreensEnabled, setIsTrackScreensEnabled] = useState(false)
const [bgQDelay, setBgQDelay] = useState("30")
const [bgQMinNumTasks, setBgQMinNumTasks] = useState("10")

useLayoutEffect(() => {
    navigation.setOptions({
      headerShadowVisible: false,
    })
  }, [navigation])

  const appState = useRef(AppState.currentState);

  // This useEffect registeres an event listener to notify the states of the app
  useEffect(() => {
    const subscription = AppState.addEventListener('change', nextAppState => {
      if (
        appState.current.match(/inactive|background/) &&
        nextAppState === 'active'
      ) {
        getPushStatus()
      }
      appState.current = nextAppState;
    });

    return () => {
      subscription.remove();
    };
  }, []);

  
  
  useEffect(() => {
    getConfigurationsFromStorage()
    getPushStatus()
  }, [])
  
  const getConfigurationsFromStorage = async () => {
    const keyStorageObj = new CioKeyValueStorage()

    // Tracking url
    const trackingUrl = await keyStorageObj.getTrackingUrl()
    setTrackUrl(trackingUrl)

    // Screen track
    const screenTrackStatus = await keyStorageObj.getScreenTrack()
    setIsTrackScreensEnabled(JSON.parse(screenTrackStatus))

    // Track device attribute
    const deviceTrackStatus = await keyStorageObj.getDeviceAttributesTrack()
    setIsTrackDeviceAttributesEnabled(JSON.parse(deviceTrackStatus))

    // Debug mode
    const debugModeStatus = await keyStorageObj.getDebugModeConfig()
    setIsDebugModeEnabled(JSON.parse(debugModeStatus))

    // BGQ Seconds delay
    const bgDelayValue = await keyStorageObj.getBGQSecondsDelay()
    setBgQDelay(bgDelayValue)

    // BGQ min tasks
    const minTasksValue = await keyStorageObj.getBGQMinTasksInQueue()
    setBgQMinNumTasks(minTasksValue)
  }

  const getPushStatus = () => {
    CustomerIO.getPushPermissionStatus().then((status) => {
      setPushStatus(status)
      if (status == "Granted") {
        setIsPushEnabled(true)
        return
      }
      setIsPushEnabled(false)
    })
  }

  const toggleSwitch = async (type) => {
    switch(type) {
      case "Push":
        // Case 1: Open settings to update push permissions
        if (isPushEnabled === true || pushStatus == 'Denied') {
            Linking.openSettings()
          return
        }
        // Case 2: Show prompt if permissions have not been determined yet
        if (pushStatus == "Notdetermined") {
          var options = {ios : {sound : true, badge: true}}
          CustomerIO.showPromptForPushNotifications(options).then((status) => {
              alert("Push permission " + status)
              console.log("Push permission " + status)
          }).catch(error => {
              alert("Could not show prompt.")
          })
        }
        break
      case "Debug":
        setIsDebugModeEnabled(previousState => !previousState);
        break
      case "DeviceAttr":
        setIsTrackDeviceAttributesEnabled(previousState => !previousState);
        break
      case "Screens":
        setIsTrackScreensEnabled(previousState => !previousState);
        break
      default:
        break
    }
  }

  const copyToClipboard = () => {
    Clipboard.setString(deviceToken)
    alert("Copied device token to clipboard.")
  }

  PushNotification.configure({
    onRegister: function (token) {
      setDeviceToken(token["token"])
    }
  });

  const saveSettings = async () => {
    const keyStorageObj = new CioKeyValueStorage()
    if(trackUrl != null) { await keyStorageObj.saveTrackingUrl(trackUrl.trim()) }
    
    await keyStorageObj.saveBGQSecondsDelay(bgQDelay)
    await keyStorageObj.saveBGQMinTasksInQueue(bgQMinNumTasks)
    await keyStorageObj.saveIsPushEnabledConfig(isPushEnabled)
    await keyStorageObj.saveScreenTrack(!isTrackScreensEnabled)
    await keyStorageObj.saveDebugModeConfig(!isDebugModeEnabled)
    await keyStorageObj.saveDeviceAttributesTrack(!isTrackDeviceAttributesEnabled)

    Alert.alert('Info', 'Settings have been updated successfully.', [
      {text: 'OK', onPress: () => navigation.goBack()},
    ]);
  }

  const alertUserBeforeSaving = () => {
    Alert.alert('Info', 'Saving settings will require an app restart.', [
      {text: 'OK', onPress: () => saveSettings()},
      {
        text: 'Cancel',
        onPress: () => console.log('Saving cancelled by the user'),
        style: 'cancel',
      },
    ]);
  }
 
  return (
    <ScrollView style={styles.container}>
       <View style={styles.innerContainer}>
              <View style={styles.headerView}>
                  <Text style={styles.textHeaderLabel}>Settings</Text>
            </View>
            <View style={[styles.rowView, {marginTop: 10}]}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>Device Token</Text>
                  <TextInput
                    style={styles.input}
                    value={deviceToken}
                    placeholder="device token"
                    editable={false}
                  />
                  <TouchableOpacity
                  style={styles.copyToClipboardButton}
                      onPress={() => copyToClipboard()}>
                          <Image 
                          style={styles.copyToClipboardImage}
                          source={require('../assets/images/paper.png')}>

                          </Image>
                  </TouchableOpacity>
                </View>
              </View>
            {/* CIO Track URL */}
              <View style={styles.rowView}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>CIO Track URL</Text>
                  <TextInput
                    style={styles.input}
                    onChangeText={(e) => setTrackUrl(e)}
                    value={trackUrl}
                    placeholder="track.customer.io"
                    editable={true}
                />
                <View style={styles.copyToClipboardButton}></View>
                </View>
              </View>

            {/* Gist Environment
              <View style={styles.rowView}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>Gist Environment</Text>
                  <TextInput
                    style={styles.input}
                    // value={deviceToken}
                    placeholder="Gist"
                    editable={false}
                />
                <View style={styles.copyToClipboardButton}></View>
                </View>
            </View> */}


            {/* Section #2 */}
            <View style={[styles.rowView, {marginTop: 30}]}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>Site Id</Text>
                  <TextInput
                    style={styles.input}
                    value={Env.siteId}
                    placeholder="siteId"
                    editable={false}
                  />
                  <View style={styles.copyToClipboardButton}></View>
                </View>
              </View>
              {/* API Key */}
              <View style={styles.rowView}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>API Key</Text>
                  <TextInput
                    style={styles.input}
                    value={Env.apiKey}
                    placeholder="Api key"
                    editable={false}
                  />
                  <View style={styles.copyToClipboardButton}></View>
                </View>
              </View>
              {/* Section #3 */}
            <View style={[styles.rowView, {marginTop: 30}]}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>backgroundQueueSecondsDelay</Text>
                  <TextInput
                    style={styles.input}
                    value={bgQDelay}
                    editable={true}
                    onChangeText={(e) => setBgQDelay(e)}
                  />
                  <View style={styles.copyToClipboardButton}></View>
                </View>
              </View>
              {/* Org Id */}
              <View style={styles.rowView}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>backgroundQueueMinNumberOfTasks</Text>
                  <TextInput
                    style={styles.input}
                    value={bgQMinNumTasks}
                    onChangeText={(e) => setBgQMinNumTasks(e)}
                  />
                  <View style={styles.copyToClipboardButton}></View>
                </View>
              </View>

            {/* Features Header */}
            <View style={[styles.headerView, {paddingTop: 50}]}>
                  <Text style={styles.textHeaderLabel}>Features</Text>
            </View>
            <View style={[styles.rowView, {marginTop: 10}]}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>Enable Push Notifications</Text>
                  <Switch
                    trackColor={styles.trackColor}
                    thumbColor={isPushEnabled ? "#ffffff" : "#f4f3f4"}
                    ios_backgroundColor="#3e3e3e"
                    onValueChange={() => toggleSwitch('Push')}
                    value={isPushEnabled}
                  />
                </View>
              </View>
            {/* CIO Track Screen */}
              <View style={styles.rowView}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>Track Screens</Text>
                  <Switch
                    trackColor={styles.trackColor}
                    thumbColor={isTrackScreensEnabled ? "#ffffff" : "#f4f3f4"}
                    ios_backgroundColor="#3e3e3e"
                    onValueChange={() => toggleSwitch('Screens')}
                    value={isTrackScreensEnabled}
                  />
                </View>
              </View>

              <View style={styles.rowView}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>Track Device Attributes</Text>
                  <Switch
                    trackColor={styles.trackColor}
                    thumbColor={isTrackDeviceAttributesEnabled ? "#ffffff" : "#f4f3f4"}
                    ios_backgroundColor="#3e3e3e"
                    onValueChange={() => toggleSwitch('DeviceAttr')}
                    value={isTrackDeviceAttributesEnabled}
                  />
                </View>
                </View>
                <View style={styles.rowView}>
                <View style={styles.stackColumnView}>
                  <Text style={styles.textLabel}>Debug mode</Text>
                  <Switch
                    trackColor={styles.trackColor}
                    thumbColor={isDebugModeEnabled ? "#ffffff" : "#f4f3f4"}
                    ios_backgroundColor="#3e3e3e"
                    onValueChange={() => toggleSwitch('Debug')}
                    value={isDebugModeEnabled}
                  />
                
              </View>
              </View>
        </View> 
        <View>
          <ThemedButton onPress={() => alertUserBeforeSaving()} title="SAVE"/>
          <Text style={styles.settingsInfoText}>Editing settings will require an app restart.</Text>
        </View>
    </ScrollView>
  )
}
const styles = StyleSheet.create({
    container: {
        flex:1,
        backgroundColor: "white",
    },
    sectionView: {
      flexDirection: 'row',
      marginTop: 30
    },
    trackColor: {
      false: "#32BD54",
      true: "#32BD54"
    },
    copyToClipboardButton:{
      alignContent: 'flex-end',
      justifyContent: 'flex-end',
      alignSelf:'flex-end',
      height: 30,
      width: 25
    },
    copyToClipboardImage: {
      width: 20,
      height: 20,
  },
    rowView:{
      flexDirection: 'row',
      paddingTop: 10
    },
    stackColumnView: {
      flexDirection: 'row',
      justifyContent:'space-between',
      alignItems: 'stretch',
      alignSelf: 'stretch',
      width: '100%',
    },
    textLabel:{
      fontSize: 14,
      alignContent: 'flex-end',
      justifyContent: 'flex-end',
      alignSelf:'flex-end',
      color: "#404040"
    },
    headerView:{
      justifyContent:'space-around',
    },
    textHeaderLabel: {
        color: '#000',
        fontSize: 18,
        fontWeight: 'bold'
      },
    innerContainer:{
      flex:1,
      backgroundColor:'white',
      padding: 20
    },
    input: {
      flex: 1,
      borderWidth: 1,
      padding:  5,
      marginLeft: 10,
      backgroundColor: 'white',
      borderColor: '#fff',
      borderBottomColor: '#e6e6e6',
      borderRadius: 10,
    },
    settingsInfoText: {
      alignSelf: 'center'
    }
})
export default SettingsScreen;