require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "customerio-reactnative-richpush"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/customerio/customerio-ios.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"

  s.subspec 'apn' do |ss|
    ss.dependency "CustomerIO/MessagingPushAPN", package["cioNativeiOSSdkVersion"]
  end

  s.subspec 'fcm' do |ss|
    ss.dependency "CustomerIO/MessagingPushFCM", package["cioNativeiOSSdkVersion"]
  end
end
