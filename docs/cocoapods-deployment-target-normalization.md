# CocoaPods deployment-target normalization

Xcode validates the deployment target of every generated CocoaPods target, including dependency,
aggregate, privacy-manifest, and resource-bundle targets. Xcode 27 rejects targets below the build
range supported by its iOS SDK even when the dependency itself is source-compatible with your app.

The `customerio-reactnative` package includes an opt-in Podfile helper. It raises low or missing
generated settings to the greater of React Native's current minimum and iOS 15.0. For React Native
0.83 that value is iOS 15.1. It also covers integrated application, Notification Service
Extension, and widget targets, while preserving higher numeric deployment targets. When a target
setting is absent, the helper resolves its target xcconfig and then the same-named project build
configuration, preserving a higher inherited app or extension floor. The helper changes local build
settings in the generated Pods project and CocoaPods-integrated app or extension projects. It does
not rewrite a podspec or change runtime API availability.

> [!WARNING]
> This is an opt-in build migration. Integrated app and extension targets below the computed floor
> are raised to that floor. With React Native 0.83, shipping the resulting iOS 15.1 application
> means users on iOS 15.0 and earlier cannot install subsequent app updates. Adopt the helper only
> when your product has intentionally moved its application and extension deployment targets.

Resolve the helper through Node so hoisted and monorepo installations work, then call it after
`react_native_post_install` in the one existing `post_install` block:

```ruby
def node_resolve(script)
  Pod::Executable.execute_command('node', ['-p',
    "require.resolve('#{script}', {paths: [process.argv[1]]})",
    __dir__
  ]).strip
end

customer_io_package_root = File.dirname(node_resolve('customerio-reactnative/package.json'))
require File.join(customer_io_package_root, 'ios', 'cocoapods_deployment_target')

customer_io_minimum_ios_version = CustomerIO::CocoaPodsDeploymentTarget.maximum(
  min_ios_version_supported,
  '15.0'
)

post_install do |installer|
  react_native_post_install(
    installer,
    config[:reactNativePath],
    :mac_catalyst_enabled => false
  )

  CustomerIO::CocoaPodsDeploymentTarget.normalize!(
    installer,
    minimum_ios_version: customer_io_minimum_ios_version
  )
end
```

Remove the generated `ios/Pods` directory and run `pod install` again. The helper resolves target
xcconfig settings and the matching project configuration before adding an override. For each
change, it prints a stable project, target, and configuration line with the original effective
value and final value. It fails the install if the selected effective value is non-numeric, such as
`$(CUSTOM_IOS_FLOOR)`, because the generated-project audit cannot prove its resolved value. A
non-numeric value at a lower precedence does not fail when an explicit numeric target setting
already determines the effective value.

If an error says an xcconfig cannot be read or parsed, repair or remove the reported base
configuration file reference for the reported project, target, and configuration. Run the helper
in the CocoaPods Ruby environment so the public `Xcodeproj::Config` parser is available.
Synchronized-group xcconfig references are not resolved by that public parser; if the helper
reports one, replace it with a standard xcconfig file reference, then run `pod install` again.
These cases fail before any project mutation.

## Remove the helper

Treat the helper as a temporary compatibility layer. Remove it only when a clean install without
the helper proves that every target/configuration in every supported resolved dependency graph
declares an effective numeric deployment target at or above the host application's minimum. Check
each supported React Native and push-provider graph, and keep the audit in CI when removing the
helper so a later dependency update cannot silently reintroduce a lower target.

The repository also includes a deterministic CI audit that prints the target, matching project,
and effective value for every generated target/configuration pair in stable order. It examines
every target in each passed project, including non-integrated targets that the normalizer
intentionally does not change; set those targets to the host minimum explicitly. Pass the `Pods`
directory so the audit recursively discovers every `.xcodeproj`, including CocoaPods multi-project
output. It fails if a supplied path is missing or contains no projects.

```sh
bundle exec ruby scripts/audit_cocoapods_deployment_targets.rb \
  --minimum 15.1 \
  example/ios/Pods \
  example/ios/SampleApp.xcodeproj
```

Keep this audit next to the React Native simulator build and unsigned generic-device archive.
Passing those checks does not prove real-device push delivery, signed archive export, or App Store
submission.
