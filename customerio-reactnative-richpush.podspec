require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

# Used by customers to install native iOS dependencies inside their Notification Service Extension (NSE) target to setup rich push. 
# Note: We need a unique podspec for rich push because the other podspecs in this project install too many dependencies that should not be installed inside of a NSE target. We need this podspec which installs minimal dependencies that are only included in the NSE target. 
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

  # s.dependency "X", "X"
  # Careful when declaring dependencies here. All dependencies will be included in the App Extension target in Xcode, not the host iOS app.   

  # Subspecs allow customers to choose between multiple options of what type of version of this rich push package they would like to install. 
  s.subspec 'apn' do |ss|
    ss.dependency "CustomerIO/MessagingPushAPN", package["cioNativeiOSSdkVersion"]
  end

  s.subspec 'fcm' do |ss|
    ss.dependency "CustomerIO/MessagingPushFCM", package["cioNativeiOSSdkVersion"]
  end
end
