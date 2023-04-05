import React from 'react'
import { View, StyleSheet, Text} from 'react-native';

const Deeplinks = () => {
  return (
    <View style={styles.container}>
        <Text style={styles.textLabel}>
        Welcome! You see this screen because you tapped on a push notification that had a deep link in it's payload. 
    </Text>
    </View>
  )
}
const styles = StyleSheet.create({
    container: {
        flex:1,
        backgroundColor: "#e3e3e3"
    },
    textLabel: {
        padding: 20,
        color: '#000',
        lineHeight: 25
    }
})
export default Deeplinks;