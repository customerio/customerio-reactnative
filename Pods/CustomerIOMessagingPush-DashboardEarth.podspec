Pod::Spec.new do |spec|
  spec.name         = "CustomerIOMessagingPush-DashboardEarth"
  spec.version      = "2.13.0-modified" # Don't modify this line - it's automatically updated
  spec.summary      = "Official Customer.io SDK for iOS."
  spec.homepage     = "https://github.com/dashboardearth/customerio-ios"
  spec.documentation_url = 'https://customer.io/docs/sdk/ios/'
  spec.changelog    = "https://github.com/dashboardearth/customerio-ios/blob/#{spec.version.to_s}/CHANGELOG.md"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "CustomerIO Team" => "win@customer.io" }
  spec.source       = { :git => 'https://github.com/customerio/customerio-ios.git', :tag => spec.version.to_s }

  spec.swift_version = '5.3'
  spec.cocoapods_version = '>= 1.11.0'

  spec.platform = :ios # platforms SDK supports. Leave blank and it's assumed SDK supports all platforms. 
  spec.ios.deployment_target = "13.0"
  # spec.osx.deployment_target = "10.15"
  # spec.tvos.deployment_target = '13.0'

  spec.source_files  = "Sources/MessagingPush/**/*"
  spec.exclude_files = "Sources/**/*{.md}"
  spec.module_name = "CioMessagingPush"  # the `import X` name when using SDK in Swift files
  
  spec.dependency "CustomerIOTracking-DashboardEarth", "= #{spec.version.to_s}"
end