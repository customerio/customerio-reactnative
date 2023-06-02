import React, {useEffect, useRef, useState} from 'react';
import { ActivityIndicator,Linking,StyleSheet} from 'react-native';
import Login from './components/Login';
import { NavigationContainer, useNavigationContainerRef } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { CustomerIO, CustomerioConfig, CioLogLevel, CustomerIOEnv } from "customerio-reactnative";
import Dashboard from './components/Dashboard';
import CustomDataScreen from './components/CustomDataScreen';
import SettingsScreen from './components/SettingsScreen'
import Env from "./env";
import CioManager from './manager/CioManager';
import CioKeyValueStorage from './manager/KeyValueStorage';
import Deeplinks from './components/Deeplink';
import DefaultConstants from './util/DefaultConstants';

const Stack = createNativeStackNavigator();

export default function App() {

  const [firstScreen, setFirstScreen] = useState(undefined)
  const [loading, setLoading] = useState(true);
const [isScreenTrackEnabled, setIsScreenTrackEnabled] = useState(null)
const [isDeviceAttrTrackEnabled, setIsDeviceAttrTrackEnabled] = useState(null)
const [isDebugModeEnabled, setIsDebugModeEnabled] = useState(null)
const [bgDelayValue, setBgDelayValue] = useState(null)
const [bgTasksValue, setBgTasksValue] = useState(null)
const [trackingUrl, setTrackingUrl] = useState(null)

  useEffect(() => {
    (async () => {
      const keyStorageObj = new CioKeyValueStorage()
      const status = await keyStorageObj.getLoginStatus()
      setLoading(false)
      if (JSON.parse(status)) {
        setFirstScreen("Dashboard")
        return
      }
      setFirstScreen("Login")
      
    })();
  }, [])

  // Automatic screen tracking
  const navigationRef = useNavigationContainerRef();
  const routeNameRef = useRef();
  const config = {
    screens: {
      Deeplinks: 'deeplink',
    },
  };
  const linking = {
    prefixes: ['apn-rn-sample://'],
    config
  };

  useEffect(() => {
    fetchConfigsOrSetDefault()
  }, [])

  useEffect(() => {
    if(isDeviceAttrTrackEnabled !== null && isScreenTrackEnabled !== null && isDebugModeEnabled != null && bgDelayValue !== null && bgTasksValue !== null)
    initialiseCioPackage()
  }, [isDeviceAttrTrackEnabled, isScreenTrackEnabled, isDebugModeEnabled, bgDelayValue, bgTasksValue])

  const fetchConfigsOrSetDefault = async() => {
    const keyStorageObj = new CioKeyValueStorage()
    const bgDelayValue  = await keyStorageObj.getBGQSecondsDelay()
    const bgTasksValue = await keyStorageObj.getBGQMinTasksInQueue()
    const screenTrackValue = await keyStorageObj.getScreenTrack()
    const deviceAttrValue = await keyStorageObj.getDeviceAttributesTrack()
    const debugModeValue = await keyStorageObj.getDebugModeConfig()
    const trackUrl = await keyStorageObj.getTrackingUrl()

    // Setting values here to show default values on Settings screens
    if (screenTrackValue === null) {
      await keyStorageObj.saveScreenTrack(DefaultConstants.SCREEN_TRACK_STATUS)
    }
    if (bgDelayValue === null) {
      await keyStorageObj.saveBGQSecondsDelay(`${DefaultConstants.BGQ_SECONDS_DELAY}`)
    }
    if (bgTasksValue === null) {
      await keyStorageObj.saveBGQMinTasksInQueue(`${DefaultConstants.BGQ_MIN_TASKS_IN_QUEUE}`)
    }
    if (deviceAttrValue === null) {
      await keyStorageObj.saveDeviceAttributesTrack(`${DefaultConstants.TRACK_DEVICE_ATTRIBUTES_STATUS}`)
    }
    if (debugModeValue === null) {
      await keyStorageObj.saveDebugModeConfig(`${DefaultConstants.DEBUG_MODE_STATUS}`)
    }
    setIsDeviceAttrTrackEnabled(deviceAttrValue === null ? true : JSON.parse(deviceAttrValue))
    setIsScreenTrackEnabled(screenTrackValue === null ? true : JSON.parse(screenTrackValue))
    setIsDebugModeEnabled(debugModeValue === null ? true : JSON.parse(debugModeValue))
    setBgDelayValue(bgDelayValue === null ? DefaultConstants.BGQ_SECONDS_DELAY : parseInt(bgDelayValue))
    setBgTasksValue(bgTasksValue === null ? DefaultConstants.BGQ_MIN_TASKS_IN_QUEUE : parseInt(bgTasksValue))
    setTrackingUrl(trackUrl)
  }

  const initialiseCioPackage = () => {

    const configuration = new CustomerioConfig()
    configuration.logLevel = isDebugModeEnabled === null ? CioLogLevel.debug : isDebugModeEnabled
    configuration.autoTrackDeviceAttributes = isDeviceAttrTrackEnabled === null ? true : isDeviceAttrTrackEnabled 
    configuration.backgroundQueueMinNumberOfTasks = bgTasksValue
    configuration.backgroundQueueSecondsDelay = bgDelayValue
    if(trackingUrl != null) {
      configuration.trackingApiUrl = trackingUrl
    }
    
    const env = new CustomerIOEnv()
    env.siteId = Env.siteId
    env.apiKey = Env.apiKey

    const cioManager = new CioManager()
    cioManager.initializeCio(env, configuration)
  }

  useEffect(() => {
    const getUrlAsync = async () => {
      const initialUrl = await Linking.getInitialURL();

      setTimeout(() => {
        if (initialUrl !== null) {
          alert(initialUrl);
        }
        // Setting 1000 only to add some delay to show alert, otherwise pops up immediately
      }, 1000);
    };

    getUrlAsync();
  }, []);

  if (loading == true ) {
    return (
      <ActivityIndicator/>
    ) 
  } else {
  return (
    
      // MARK:- AUTO SCREEN TRACKING
      // Start
      <NavigationContainer
        ref={navigationRef}
        linking={linking}
        onReady={() => {
          routeNameRef.current = navigationRef.getCurrentRoute().name;
        }}
        onStateChange={async () => {
          if (isScreenTrackEnabled) {
            const previousRouteName = routeNameRef.current;
            const currentRouteName = navigationRef.getCurrentRoute().name;
    
            if (previousRouteName !== currentRouteName) {
              CustomerIO.screen(currentRouteName)
            }
            routeNameRef.current = currentRouteName;
          }
        }}
        // End
        >
        
      <Stack.Navigator initialRouteName={firstScreen}>
        <Stack.Screen name="Login"
        component={Login}
        options={{
          headerShown : false,
          gestureEnabled: false,
          gestureDirection: 'vertical',
        }}/>
        <Stack.Screen name="Dashboard" component={Dashboard}
        options={{
          headerShown : false,
          gestureEnabled: false,
          
        }}
       />
       <Stack.Screen name="CustomDataScreen" component={CustomDataScreen}
       options={{
          title:"",
          headerStyle: {
            backgroundColor: '#ffffff'},
        }}
       />
       <Stack.Screen name="Deeplinks" component={Deeplinks}
       options={{
          title:"",
        }}
       />
       <Stack.Screen name="SettingsScreen" component={SettingsScreen}
       options={{
          title:"",
          headerStyle: {
            // backgroundColor: '#ffffff'
          },
        }}
       />
       </Stack.Navigator>
    
    </NavigationContainer>
    );
    }
}
const styles = StyleSheet.create({
  mainView: {
    flex: 1,
    flexDirection: 'row',
    paddingTop : 50,
    justifyContent:'center'
  },
});

