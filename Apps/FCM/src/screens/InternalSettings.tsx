import React, { useState } from 'react';
import { View, Text, ScrollView } from 'react-native';
import { TextField } from '../components/TextField';
import { FilledButton } from '../components/Button';
import {styles as settingsStyles} from '../styles/stylesheet';

const InternalSettings: React.FC = () => {
    const [apiHost, setApiHost] = useState('');
    const [cdnHost, setCdnHost] = useState('');
    const [flushAt, setFlushAt] = useState('');
    const [flushInterval, setFlushInterval] = useState('');

    const handleSave = () => {

    };
    

    return (
        <View style={settingsStyles.container}>
            <ScrollView contentContainerStyle={settingsStyles.content}>
                <View style={settingsStyles.section}>
                    <TextField
                        style={settingsStyles.textInputContainer}
                        label="CDN Host"
                        value={cdnHost}
                        contentDesc="CDN Host Input"
                        placeholder='CDN Host'
                        onChangeText={text => setCdnHost(text)}
                        textInputProps={{
                            autoCapitalize: 'none',
                            keyboardType: 'default',
                        }}
                    />
                    <TextField
                        style={settingsStyles.textInputContainer}
                        label="API Host"
                        value={apiHost}
                        placeholder='API Host'
                        contentDesc="API Host Input"
                        onChangeText={text => setApiHost(text)}
                        textInputProps={{
                        autoCapitalize: 'none',
                        keyboardType: 'default',
                        }}
                    />
                    <TextField
                        style={settingsStyles.textInputContainer}
                        label="Flush Interval"
                        value={flushInterval}
                        contentDesc="Flush Interval Input"
                        onChangeText={text => setFlushInterval(text)}
                        textInputProps={{
                        autoCapitalize: 'none',
                        placeholder: '30',
                        keyboardType: 'numeric',
                        }}
                    />
                    <TextField
                        style={settingsStyles.textInputContainer}
                        label="Flush At"
                        value={flushAt}
                        contentDesc="Flush At Input"
                        placeholder='20'
                        onChangeText={text => setFlushAt(text)}
                        textInputProps={{
                        autoCapitalize: 'none',
                        keyboardType: 'numeric',
                        }}
                    />
                    <View style={settingsStyles.section}></View>
                    <View style={settingsStyles.buttonContainer}>
                            <FilledButton
                                style={settingsStyles.saveButton}
                                onPress={handleSave}
                                text="Save"
                                contentDesc="Save Settings Button"
                                textStyle={settingsStyles.saveButtonText}
                            />
                    </View>
                </View>
            </ScrollView>
        </View>
    );
};

export default InternalSettings;