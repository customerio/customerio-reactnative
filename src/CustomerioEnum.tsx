/**
 * Enum to define the log levels.
 * Logs can be viewed in Xcode or Android studio.
 */
enum CioLogLevel{
    none = 1,
    error,
    info,
    debug
}

/**
 * Use this enum to specify the region your customer.io workspace is present in.
 * US - for data center in United States
 * EU - for data center in European Union 
 */
 enum Region {
    US = "US",
    EU = "EU",
  }

/**
 * Enum to represent the type of event triggered by in-app event callback.
 */
enum InAppEventType {
  errorWithMessage = "errorWithMessage",
  messageActionTaken = "messageActionTaken",
  messageDismissed = "messageDismissed",
  messageShown = "messageShown",
}

export { CioLogLevel, Region, InAppEventType };
