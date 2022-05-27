import {CioLogLevel} from './CustomerioEnum'

class CustomerioConfig {
    logLevel : CioLogLevel = CioLogLevel.error
    autoTrackDeviceAttributes : boolean = true
    trackingApiUrl : string = ""
    autoTrackPushEvents : boolean = true
    backgroundQueueMinNumberOfTasks : number = 10
    backgroundQueueSecondsDelay : number = 30
}

export {
    CustomerioConfig
}