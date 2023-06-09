require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "customerio-reactnative"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/customerio/customerio-ios.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"

  s.dependency "React-Core"

  # Syntax of native iOS pods allows for automatically upgrading to the latest major version of the iOS SDK. 
  # Reference: https://guides.cocoapods.org/syntax/podfile.html#pod
  s.dependency "CustomerIO/Tracking", package["cioNativeiOSSdkVersion"]
  s.dependency "CustomerIO/MessagingInApp", package["cioNativeiOSSdkVersion"]

  s.subspec 'apn' do |ss|
    ss.dependency "CustomerIO/MessagingPushAPN", package["cioNativeiOSSdkVersion"]
  end

  s.subspec 'fcm' do |ss|
    ss.dependency "CustomerIO/MessagingPushFCM", package["cioNativeiOSSdkVersion"]
    ss.dependency "FirebaseMessaging"
  end
end
