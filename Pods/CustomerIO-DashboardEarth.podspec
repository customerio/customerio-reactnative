# Cocoapods projects that provide multiple SDKs have a common naming pattern for installing pods:
# CustomerIO/Tracking 
# This podspec allows that. It publishes aliases for the cocoapods we have already published. 
# Example: CustomerIO/Tracking is an alias for the published pod CustomerIOTracking

Pod::Spec.new do |spec|
  spec.name         = "CustomerIO-DashboardEarth"
  spec.version      = "2.13.0-modified" # Don't modify this line - it's automatically updated
  spec.summary      = "Official Customer.io SDK for iOS."  
  spec.homepage     = "https://github.com/customerio/customerio-ios"
  spec.documentation_url = 'https://customer.io/docs/sdk/ios/'
  spec.changelog    = "https://github.com/customerio/customerio-ios/blob/#{spec.version.to_s}/CHANGELOG.md"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "CustomerIO Team" => "win@customer.io" }
  spec.source       = { :git => 'https://github.com/customerio/customerio-ios.git', :branch => 'master' }

  spec.swift_version = '5.3'
  spec.cocoapods_version = '>= 1.11.0'

  spec.platform = :ios # platforms SDK supports. Leave blank and it's assumed SDK supports all platforms. 
  spec.ios.deployment_target = "13.0"
  # spec.osx.deployment_target = "10.15"
  # spec.tvos.deployment_target = '13.0'

  spec.default_subspec = "Tracking"

  spec.subspec "Tracking" do |ss|
    # Using `= X.X.X` is required for pre-release versions of an SDK (alpha, beta) 
    # In the future, we can use: `~> X.X.X` which matches by semantic version rules. 
    ss.dependency "CustomerIOTracking-DashboardEarth", "= #{spec.version.to_s}"
  end

  spec.subspec "MessagingPush" do |ss|
    ss.dependency "CustomerIOMessagingPush-DashboardEarth", "= #{spec.version.to_s}"
  end

  spec.subspec "MessagingPushAPN" do |ss|
    ss.dependency "CustomerIOMessagingPushAPN-DashboardEarth", "= #{spec.version.to_s}"
  end

  spec.subspec "MessagingPushFCM" do |ss|
    ss.dependency "CustomerIOMessagingPushFCM-DashboardEarth", "= #{spec.version.to_s}"
  end

  spec.subspec "MessagingInApp" do |ss|
    ss.dependency "CustomerIOMessagingInApp-DashboardEarth", "= #{spec.version.to_s}"
  end
end