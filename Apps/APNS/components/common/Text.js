import React from "react";
import { Text, StyleSheet, View } from "react-native";

const SubHeaderText = (props) => {
    return (
            <Text style={styles.subHeaderText}>
            {props.label}
        </Text>
    )
}

const SimpleText = (props) => {
    return(
        <Text style={styles.simpleText}>
            {props.label}
        </Text>
    )
}

const styles = StyleSheet.create({
    subHeaderText : {
        padding : 20,
        fontSize: 15,
        fontWeight : 'bold'
      },
      simpleText: {
        fontSize: 15,
        paddingLeft : 20,
        paddingRight: 20
      }
})

export {SubHeaderText, SimpleText};
