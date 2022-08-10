import {CioLogLevel, Region} from './CustomerioEnum'

/**
 * Configure package using CustomerioConfig
 * 
 * Usecase:
 * 
 * const configData = new CustomerioConfig()
 * configData.logLevel = CioLogLevel.debug
 * configData.autoTrackDeviceAttributes = true
 * CustomerIO.config(data)    
 */
class CustomerioConfig {
    logLevel : CioLogLevel = CioLogLevel.error
    autoTrackDeviceAttributes : boolean = true
    trackingApiUrl : string = ""
    autoTrackPushEvents : boolean = true
    backgroundQueueMinNumberOfTasks : number = 10
    backgroundQueueSecondsDelay : number = 30
}

class CustomerIOEnv {
    siteId: string = ""
    apiKey: string = ""
    region: Region = Region.US
    organizationId: string = ""
}

export {
    CustomerioConfig,
    CustomerIOEnv
}