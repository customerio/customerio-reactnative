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
        // Save the API Host and CDN Host values
        console.log('API Host:', apiHost);
        console.log('CDN Host:', cdnHost);
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
                        onChangeText={text => setCdnHost(text)}
                        // textInputRef={siteIdRef}
                        // getNextTextInput={() => ({ ref: apiKeyRef, value: cdpApiKey })}
                        textInputProps={{
                            autoCapitalize: 'none',
                            keyboardType: 'default',
                        }}
                    />
                    <TextField
                        style={settingsStyles.textInputContainer}
                        label="API Host"
                        value={apiHost}
                        contentDesc="API Host Input"
                        onChangeText={text => setApiHost(text)}
                        // textInputRef={siteIdRef}
                        // getNextTextInput={() => ({ ref: apiKeyRef, value: cdpApiKey })}
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
                        // textInputRef={siteIdRef}
                        // getNextTextInput={() => ({ ref: apiKeyRef, value: cdpApiKey })}
                        textInputProps={{
                        autoCapitalize: 'none',
                        keyboardType: 'default',
                        }}
                    />
                    <TextField
                        style={settingsStyles.textInputContainer}
                        label="Flush At"
                        value={flushAt}
                        contentDesc="Flush At Input"
                        onChangeText={text => setFlushAt(text)}
                        // textInputRef={siteIdRef}
                        // getNextTextInput={() => ({ ref: apiKeyRef, value: cdpApiKey })}
                        textInputProps={{
                        autoCapitalize: 'none',
                        keyboardType: 'default',
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