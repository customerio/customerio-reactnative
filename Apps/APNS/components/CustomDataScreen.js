import React, {useLayoutEffect, useState, useEffect} from 'react'
import { View, Text, TextInput, StyleSheet} from 'react-native'
import CioManager from '../manager/CioManager'
import ThemedButton from './common/Button'

const CustomDataScreen = ({route, navigation}) => {
    const { featureType } = route.params

    // Labels
    const [title, setTitle] = useState('')
    const [propertyLabel, setPropertyLabel] = useState('')
    const [showEventName, setShowEventName] = useState(true)
    const [buttonText, setButtonText] = useState('')

    // Values
    const [eventName, setEventName] = useState('')
    const [propertyName, setPropertyName] = useState('')
    const [propertyValue, setPropertyValue] = useState('')

    useEffect(() => {
        switch (featureType){
            case "Custom Event":
                setTitle("Send Custom Events")
                setPropertyLabel("Property")
                setShowEventName(true)  
                setButtonText("event")
                break
            case "Device Attributes":
                setTitle("Set Custom Device Attributes")
                setPropertyLabel("Attribute")
                setShowEventName(false)  
                setButtonText("device attributes")
                break
            case "Profile Attributes":
                setTitle("Set Custom Profile Attributes")
                setPropertyLabel("Attribute")
                setShowEventName(false)  
                setButtonText("profile attributes")
                break
            default: 
                break
        }
    }, [featureType])

    useLayoutEffect(() => {
        navigation.setOptions({
          headerShadowVisible: false,
        })
      }, [navigation])
    
    const sendEventTapped = () => {
        if (!IsFormValid()) {
            alert("Please fill in all fields")
            return
        }

        const cioManager = new CioManager()
        switch (featureType){
            case "Custom Event":
                sendCustomEvent(cioManager)
                break
            case "Device Attributes":
                sendDeviceAttributes(cioManager)
                break
            case "Profile Attributes":
                sendProfileAttributes(cioManager)
                break
            default:
                break
        }
        alert(`${featureType} sent`)
        resetValues()
    }

    const sendCustomEvent = (cioManager) => {
        const data = {propertyName: propertyValue}
        cioManager.customEvent(eventName, data)
    }

    const sendDeviceAttributes = (cioManager) => {
        const data = {propertyName: propertyValue}
        cioManager.deviceAttributes(data)
    }

    const sendProfileAttributes = (cioManager) => {
        const data = {propertyName: propertyValue}
        cioManager.profileAttributes(data)
    }

    const resetValues = () => {
        setEventName("")
        setPropertyName("")
        setPropertyValue("")
    }

    const IsFormValid = () => {
        if (featureType == "Custom Event" && eventName.trim() == "") {
            return false
        }
        if (propertyName.trim() == "" || propertyValue.trim() == "")
        {
            return false
        }
        return true
    }


    return (
        <View style={styles.container}>
            <View style={styles.innerContainer}>
                <View style={styles.eventView}>
                    <Text style={styles.title}>
                            {title}
                    </Text>
                    
                    { showEventName && 
                    <View style={styles.eventRowView}>
                    <View style={{flex: 0.5}}>
                        <Text style={styles.eventTitle}>Event Name</Text>
                        </View>
                        <View style={{flex: 0.5,alignItems:'flex-end'}}>
                        <TextInput
                            style={styles.input}
                            onChangeText={(e) => setEventName(e)}
                            value={eventName}
                            placeholder='purchase'
                            />
                        </View>
                    </View>
                    }
                    <View style={styles.eventRowView}>
                    <View style={{flex: 0.5}}>

                        <Text style={styles.eventTitle}>{propertyLabel} Name</Text>
                        </View>
                        <View style={{flex: 0.5,alignItems:'flex-end'}}>
                        <TextInput
                            style={styles.input}
                            onChangeText={(e) => setPropertyName(e)}
                            value={propertyName}
                            placeholder='item'
                            />
                        </View>
                    </View>
                    <View style={styles.eventRowView}>
                        <View style={{flex: 0.5}}>
                            <Text style={styles.eventTitle}>{propertyLabel} Value</Text>
                        </View>
                        <View style={{flex: 0.5, alignItems:'flex-end'}}>
                        <TextInput
                            style={styles.input}
                            onChangeText={(e) => setPropertyValue(e)}
                            value={propertyValue}
                            placeholder='socks'
                            />
                        </View>
                    </View>
                    <ThemedButton
                    title ={`Send ${buttonText}`}
                    onPress={() => sendEventTapped()}></ThemedButton>
                </View>
                
            </View>
        </View>
    )
}

const styles = StyleSheet.create({
    container : {
        flex : 1,
        backgroundColor: '#fff'
    },
    innerContainer: {
        flex: 1,
        alignContent: 'center',
        alignItems: 'center',
        justifyContent: 'center',
    },
    title: {
        fontSize: 22,
        fontWeight: '700',
        paddingBottom: 40
    },
    eventView:{
        width: '80%',
        alignContent:'center',
        justifyContent:"center",
        bottom: 50
    },
    eventRowView: {
        flexDirection: 'row',
        alignItems:'center',
        paddingBottom: 9,
    },
    input: {
        height: 40,
        marginLeft: 20,
        marginTop:3,
        borderWidth: 1,
        borderRadius:5,
        borderColor:"#ebecf2",
        padding: 10,
        fontFamily:'Avenir',
        color: '#4b4b60',
        width: '100%',
      },
      eventTitle: {
        fontSize: 15
      }
})


export default CustomDataScreen;