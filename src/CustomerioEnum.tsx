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

export {CioLogLevel, Region}