import React from 'react'
import { StyleSheet, Text, FlatList, View, Image, Button, ImageBackground, TouchableHighlight} from 'react-native';

const ThemedButton = (props) => {
  return (
    <View style={styles.container}>
        <TouchableHighlight
        style={[styles.button, props.style]}
        underlayColor='#f194ff'
        onPress={props.onPress}>
            <Text style={styles.text}>{props.title}</Text>
    </TouchableHighlight>
  </View>
  )
}

const styles = StyleSheet.create({
    container: {
      alignItems: 'center',
    },
    button: {
        padding:10,
        alignSelf:'center',
        paddingBottom:10,
        backgroundColor:'#3C437D',
        borderRadius:10,
        borderWidth: 1,
        borderColor: '#fff',
        marginTop: 20,
        marginBottom: 10,
        minWidth: '75%'
    },
    text : {
        color:'#fff',
        textAlign:'center',
        fontWeight: '600',
        paddingLeft : 10,
        fontSize: 17,
        paddingRight : 10
    }
})

export default ThemedButton;