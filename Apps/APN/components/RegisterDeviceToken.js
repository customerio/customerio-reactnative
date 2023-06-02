import React, {useState} from "react";
import { StyleSheet, View, Text, Platform } from "react-native";
import FeatureButton from "./common/FeatureButton";
import { SubHeaderText } from "./common/Text";
import { CustomerIO } from 'customerio-reactnative';


const RegisterDeviceToken = (props) => {

    const [deviceToken, setDeviceToken] = useState('')
    const registerDevice = () => {

        // For the sake of testing, we are generating a random
        // alphanumeric string and passing it as a token.
        // Customer.io expects a valid token to send push notifications
        // to the user.
        const token = generateRandomToken()
        // MARK:- REGISTER DEVICE TOKEN 
        CustomerIO.registerDeviceToken(token)
        setDeviceToken(token)
        alert("Device token registered")
    }

    const generateRandomToken = () => {
        let length = 163
        if (Platform.OS == "ios"){
            length = 64
        }
        const char = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
        const random = Array.from(
            {length: 64},
            () => char[Math.floor(Math.random() * char.length)]
        );
        const randomString = random.join("");
        return randomString
      }

    return (
        <View style={styles.container}>
            <SubHeaderText label = "REGISTER DEVICE TOKEN"/>
            <View style={styles.innerContainer}>
                <FeatureButton
                title ="Register token"
                style={{marginBottom: 20}}
                onPress = {() => registerDevice()}></FeatureButton>
            </View>
            <View style={styles.deviceTokenText}>
                <Text>{deviceToken}</Text>
            </View>
        </View>
    )
}

const styles = StyleSheet.create({
    container : {
        backgroundColor: 'white',
        marginTop: 20,
        borderRadius: 25
    },
    innerContainer: {
        marginTop: 5,
    },
    input: {
        height: 40,
        marginLeft: 12,
        marginRight: 12,
        marginBottom: 12,
        borderWidth: 1,
        padding: 10,
        backgroundColor: 'white',
        borderColor: '#e6e6e6',
        borderRadius: 10
      },
      deviceTokenText:{
        flex:1,
        paddingLeft:25,
        paddingRight:25
    }
})

export default RegisterDeviceToken;