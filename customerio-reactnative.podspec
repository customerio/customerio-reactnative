require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

# Used by customers to install native iOS dependencies inside their host iOS app. 
Pod::Spec.new do |s|
  s.name         = "customerio-reactnative"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/customerio/customerio-ios.git", :tag => "#{s.version}" }

  s.source_files = "ios/wrappers/**/*.{h,m,mm,swift}"

  s.dependency "React-Core"

  # Syntax of native iOS pods allows for automatically upgrading to the latest major version of the iOS SDK. 
  # Reference: https://guides.cocoapods.org/syntax/podfile.html#pod
  s.dependency "CustomerIO/DataPipelines", package["cioNativeiOSSdkVersion"]
  s.dependency "CustomerIO/MessagingInApp", package["cioNativeiOSSdkVersion"]

  # If we do not specify a default_subspec, then *all* dependencies inside of *all* the subspecs will be downloaded by cocoapods. 
  # We want customers to opt into push dependencies especially because the FCM subpsec downloads Firebase dependencies. APN customers should not install Firebase dependencies at all. 
  s.default_subspec = "nopush"

  s.subspec 'nopush' do |ss|
    # This is the default subspec designed to not install any push dependencies. Customer should choose APN or FCM.
    # The SDK at runtime currently requires the MessagingPush module so we do include it here. 
    ss.dependency "CustomerIO/MessagingPush", package["cioNativeiOSSdkVersion"]
  end 

  # Note: Subspecs inherit all dependencies specified the parent spec (this file). 
  s.subspec 'apn' do |ss|
    ss.dependency "CustomerIO/MessagingPushAPN", package["cioNativeiOSSdkVersion"]
  end

  s.subspec 'fcm' do |ss|
    ss.dependency "CustomerIO/MessagingPushFCM", package["cioNativeiOSSdkVersion"]
  end
end
