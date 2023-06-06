require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

cio_native_version = "= 2.6.1"

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
  s.dependency "CustomerIO/Tracking", cio_native_version
  s.dependency "CustomerIO/MessagingInApp", cio_native_version

  s.subspec 'richpush-apn' do |ss|
    ss.dependency "CustomerIO/MessagingPushAPN", cio_native_version
  end

  s.subspec 'richpush-fcm' do |ss|
    ss.dependency "CustomerIO/MessagingPushFCM", cio_native_version
  end
end
