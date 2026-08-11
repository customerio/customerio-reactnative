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
  minimum_ios_version = [min_ios_version_supported, "15.0"]
    .map { |version| Pod::Version.new(version) }
    .max
    .to_s
  s.platforms    = { :ios => minimum_ios_version }

  s.source       = { :git => "https://github.com/customerio/customerio-ios.git", :tag => "#{s.version}" }

  # Dependency-only pod: installed into the NSE target, whose job is purely to pull in the minimal
  # CIO push dependency below. It must NOT compile any sources — everything under ios/ is the React
  # Native bridge (React + DataPipelines + InApp + Inbox), none of which the NSE target has or should
  # have. Globbing them here made the NSE compile the whole bridge and fail on React headers.

  # Careful when declaring dependencies here. All dependencies will be included in the App Extension target in Xcode, not the host iOS app.   

  # Subspecs allow customers to choose between multiple options of what type of version of this rich push package they would like to install.
  # Set default subspec to 'apn' to prevent both APN and FCM dependencies from being installed by default.
  # Because attempting to install both will break due to the different linkage requirements of the two different push dependencies.
  # 
  # To override the default subspec, specify the desired subspec in your Podfile. For example:
  # pod 'customerio-reactnative-richpush/fcm'
  
  s.default_subspec = 'apn'
  
  s.subspec 'apn' do |ss|
    ss.dependency "CustomerIO/MessagingPushAPN", package["cioNativeiOSSdkVersion"]
  end

  s.subspec 'fcm' do |ss|
    ss.dependency "CustomerIO/MessagingPushFCM", package["cioNativeiOSSdkVersion"]
  end
end
