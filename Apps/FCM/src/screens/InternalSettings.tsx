import React, { useState } from 'react';
import { View, TextInput, Button, StyleSheet } from 'react-native';

const InternalSettings: React.FC = () => {
    const [apiHost, setApiHost] = useState('');
    const [cdnHost, setCdnHost] = useState('');

    const handleSave = () => {
        // Save the API Host and CDN Host values
        console.log('API Host:', apiHost);
        console.log('CDN Host:', cdnHost);
    };

    return (
        <View style={styles.container}>
            <TextInput
                style={styles.input}
                placeholder="API Host"
                value={apiHost}
                onChangeText={setApiHost}
            />
            <TextInput
                style={styles.input}
                placeholder="CDN Host"
                value={cdnHost}
                onChangeText={setCdnHost}
            />
            <Button title="Save" onPress={handleSave} />
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        padding: 16,
        justifyContent: 'center',
    },
    input: {
        marginBottom: 16,
        padding: 8,
        borderWidth: 1,
        borderColor: '#ccc',
        borderRadius: 4,
    },
});

export default InternalSettings;