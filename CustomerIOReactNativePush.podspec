require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "CustomerIOReactNativePush"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => min_ios_version_supported }
  s.source       = { :git => "https://github.com/customerio/customerio-reactnative.git", :tag => "#{s.version}" }

  s.pod_target_xcconfig = {
    "DEFINES_MODULE" => "YES",
  }

  s.default_subspec = 'APN'

  s.subspec 'APN' do |ss|
    ss.dependency "CustomerIO/MessagingPushAPN"
    ss.source_files = "ios/apn/**/*.{h,m,mm,swift}"
  end

  s.subspec 'FCM' do |ss|
    ss.dependency "CustomerIO/MessagingPushFCM"
    ss.source_files = "ios/fcm/**/*.{h,m,mm,swift}"
  end

end
