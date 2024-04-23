Pod::Spec.new do |spec|
  spec.name         = "CustomerIOMessagingPushFCM-DashboardEarth"
  spec.version      = "2.13.0-modified" # Don't modify this line - it's automatically updated
  spec.summary      = "Official Customer.io SDK for iOS."
  spec.homepage     = "https://github.com/customerio/customerio-ios"
  spec.documentation_url = 'https://customer.io/docs/sdk/ios/'
  spec.changelog    = "https://github.com/customerio/customerio-ios/blob/#{spec.version.to_s}/CHANGELOG.md"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "CustomerIO Team" => "win@customer.io" }
  spec.source       = { :git => 'https://github.com/customerio/customerio-ios.git', :tag => spec.version.to_s }

  spec.swift_version = '5.3'
  spec.cocoapods_version = '>= 1.11.0'

  spec.platform = :ios # platforms SDK supports. Leave blank and it's assumed SDK supports all platforms. 
  spec.ios.deployment_target = "13.0"
  # spec.osx.deployment_target = "10.15"
  # spec.tvos.deployment_target = '13.0'

  path_to_source_for_module = "Sources/MessagingPushFCM"
  spec.source_files = "#{path_to_source_for_module}/**/*{.swift}"
  spec.resource_bundle = {
    "#{spec.module_name}_Privacy" => "#{path_to_source_for_module}/Resources/PrivacyInfo.xcprivacy"
  }
  
  spec.dependency "CustomerIOMessagingPush-DashboardEarth", "= #{spec.version.to_s}"  

  # Add FCM SDK as a dependency, as our SDK is designed to be compatible with it. 
  # No version is specified which means that by default, the latest version is installed for customers. 
  # Customers can override this by adding the pod to their Podfile themselves to specify a version they want to use. 
  spec.dependency "FirebaseMessaging", ">= 8.7.0", "< 11"
end