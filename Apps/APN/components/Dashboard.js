import React, {useState} from 'react'
import { View, Text, FlatList, StyleSheet, Image, Alert, TouchableOpacity} from 'react-native'
import CioManager from '../manager/CioManager'
import ThemedButton from './common/Button'
import PushNotification from "react-native-push-notification";
import CioKeyValueStorage from '../manager/KeyValueStorage'
import { CustomerIO } from 'customerio-reactnative'

const Dashboard = ({navigation}) => {

    const [deviceToken, setDeviceToken] = useState(null)
    // To get device token
    PushNotification.configure({
        onRegister: function (token) {
          setDeviceToken(token["token"])
        }
    });
    
    
    const sendRandomEventTapped = () => {
        const cioManager = new CioManager()
        cioManager.randomEvent()
        alert("Random event tracked successfully.")
    }

    const settingsTapped = () => {
        navigation.navigate("SettingsScreen")
    }
    const sendCustomEventTapped = () => {
        navigation.navigate("CustomDataScreen", {
            featureType : "Custom Event"
        })
    }

    const setDeviceAttributesTapped = () => {
        navigation.navigate("CustomDataScreen", {
            featureType : "Device Attributes"
        })
    }

    const setProfileAttributesTapped = () => {
        navigation.navigate("CustomDataScreen", {
            featureType : "Profile Attributes"
        })
    }

    const logoutTapped = async() => {
        const cioManager = new CioManager()
        cioManager.clearUserIdentity()

        const keyStorageObj = new CioKeyValueStorage()
        await keyStorageObj.saveLoginStatus(false)
        navigation.navigate("Login")
    }

    const renderDashboardButtons = (item) => {
        return (
            <ThemedButton onPress={ item.onClick} title={item.key}/>
        )
    }

    const showPushPrompt = () => {
        var options = {"ios" : {"sound" : true, "badge" : true}}

        CustomerIO.showPromptForPushNotifications(options).then(status => {
            alert("Push permission " + status)
            console.log("Push permission " + status)
        }).catch(error => {
            alert("Could not show prompt.")
        })
    }

    const getCurrentPushPermission = () => {
        CustomerIO.getPushPermissionStatus().then(status => {
            alert("Push permission status is - " + status)
            console.log("Push permission status is - " + status)
          })
    }

    const registerDeviceToken = () => {
        if(deviceToken !== null) {
            CustomerIO.registerDeviceToken(deviceToken)
            alert("Device token registered successfully")
            return
        }
        alert("Could not register device. Device token unavailable.")
    }

    const userIconTapped = async () => {
        const keyStorageObj = new CioKeyValueStorage()
        const userDetail = JSON.parse(await keyStorageObj.getLoginDetail())

        Alert.alert('User Info', "Name - " + userDetail.name + "\n\nEmailId - " + userDetail.id, [
            {text: 'OK'}
          ]);
    }

    PushNotification.configure({
        /**
         * (optional) default: true
         * - Specified if permissions (ios) and token (android and ios) will requested or not,
         * - if not, you must call PushNotificationsHandler.requestPermissions() later
         * - if you are not using remote notification or do not have Firebase installed, use this:
         *     requestPermissions: Platform.OS === 'ios'
         */
        requestPermissions: true,
    })
      
    return (
        <View style={styles.container}>
            <View style={{flex:1,backgroundColor:'white', paddingTop: 50}}>
                <View style={{justifyContent:'space-around', flexDirection: 'row'}}>
                    <View style={{height:50,alignSelf:'stretch',margin:5, flex: 1}}>
                        <View style={styles.userIconView}>
                            <TouchableOpacity
                                onPress={() => userIconTapped()}>
                                    <Image 
                                    style={styles.settingsImage}
                                    source={require('../assets/images/userIcon.png')}>
                                    </Image>
                            </TouchableOpacity>
                            </View>
                        </View> 

                            <View style={{height:50,alignSelf:'stretch',margin:5, flex: 1}}>
                        <View style={styles.settingsView}>
                            <TouchableOpacity
                                onPress={() => settingsTapped()}>
                                    <Image 
                                    style={styles.settingsImage}
                                    source={require('../assets/images/black-settings-button.png')}>

                                    </Image>
                            </TouchableOpacity>
                            </View>
                        </View>  
                </View>
                <View style={styles.innerContainer}>
                    <Text style={styles.title}>
                        What would you like to test?
                    </Text>

                    <View style={styles.featuresView}>
                    <FlatList
                        data={[
                        {key: 'Show push prompt', onClick: () => showPushPrompt()},
                        {key: 'Get current push permissions', onClick: () => getCurrentPushPermission()},
                        {key: 'Register device token', onClick: () => registerDeviceToken()},
                        {key: 'Send Random Event', onClick: () => sendRandomEventTapped()},
                        {key: 'Send Custom Event', onClick: () => sendCustomEventTapped()},
                        {key: 'Set Device Attributes', onClick: () => setDeviceAttributesTapped()},
                        {key: 'Set Profile Attributes', onClick: () => setProfileAttributesTapped()},
                        {key: 'Logout', onClick: () => logoutTapped()},
                        ]}
                        renderItem={({item}) => renderDashboardButtons(item)}
                    />
                    </View>
                </View>
            </View>
        </View>
    )
}

const styles = StyleSheet.create({
    container : {
        flex : 1
    },
    innerContainer: {
        flex:1,
        alignItems:'center',
        alignSelf:'stretch',
        margin:5,
        marginTop: 15
    },
    title: {
        fontSize: 22
    },
    featuresView: {
        width: '80%'
    },
    featureTitleText:{
        color:'#fff',
        textAlign:'center',
        fontWeight: '600',
        paddingLeft : 10,
        fontSize: 17,
        paddingRight : 10
    },
    settingsView: {    
        alignItems: 'flex-end',
        height: 50,
        flex: 1,
        paddingRight: 10,
    },
    settingsImage: {
        width: 40,
        height: 40
    },
    flexRow: {
        top: 75,
        flexDirection: 'row',
    },
    userIconView: {
        paddingLeft: 10
    }
})

export default Dashboard;