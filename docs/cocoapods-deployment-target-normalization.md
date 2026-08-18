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

The package also ships a source lock beside the helper. That lock identifies the reviewed
`customerio-ios` source commit and digest used for this wrapper copy, and the repository test suite
fails if the packaged helper drifts without an explicit relock.

Customer.io deliberately continues to publish native SDKs that support iOS versions below 15. A
podspec can therefore correctly declare that lower library minimum even when React Native or the
application consuming it requires a newer iOS version. CocoaPods carries deployment metadata from
Customer.io and third-party podspecs into generated build targets, but Xcode 27 no longer accepts
targets below the iOS SDK's supported build range. Raising every published podspec to iOS 15 would
unnecessarily drop older applications and would not control metadata from transitive
dependencies. The helper instead aligns the generated targets with the host application's chosen
minimum while leaving the packages' published runtime compatibility unchanged.
This is the supported integration policy for a React Native application that has moved its own
minimum to the required iOS floor.

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

Remove the generated `ios/Pods` directory and run `pod install` again. When a target build-setting
key is absent, the helper resolves the target xcconfig and matching project configuration before
adding an override. A present target key is authoritative, so lower-precedence xcconfig and project
values are not inspected. This matches Xcode's treatment of an explicitly empty target value: it
is missing and must be normalized, rather than inherited from a lower-precedence value. For each
change, the helper prints a stable project, target, and configuration line with the original
effective value and final value. It fails the install if the selected effective value is
non-numeric, such as `$(CUSTOM_IOS_FLOOR)`, because the generated-project audit cannot prove its
resolved value. A non-numeric value at a lower precedence does not fail when an explicit target
setting already determines the effective value.

If the helper reports a non-numeric selected value, use the project, target, and configuration in
the error to locate the authoritative `IPHONEOS_DEPLOYMENT_TARGET`. Replace the macro or inherited
expression at that precedence with its intended numeric version, then run `pod install` again. Do
not skip that target: continuing with an unresolved expression would leave the generated project
outside the deterministic audit. The helper validates every selected value before changing any
project, so this failure does not leave a partially normalized installation.

If an error says a selected xcconfig cannot be read or parsed, repair or remove the reported base
configuration file reference for the reported project, target, and configuration. Lower-precedence
xcconfigs are not parsed when the target build-setting key is present. Run the helper in the
CocoaPods Ruby environment so the public `Xcodeproj::Config` parser is available.
Synchronized-group xcconfig references are not resolved by that public parser; if the helper
reports one, replace it with a standard xcconfig file reference, then run `pod install` again.
These cases fail before any project mutation.

## When the helper is no longer needed

Keep the helper while a supported dependency graph can validly include deployment metadata below
the host application's minimum. This is expected while Customer.io supports older iOS versions or
supported third-party pods continue to declare lower minimums. A `platform` declaration in the
application's Podfile alone does not guarantee that every generated target uses the same value.

The helper becomes unnecessary only when a clean install without it proves that every
target/configuration in every supported React Native and push-provider graph declares an effective
numeric deployment target at or above the host application's minimum. That state would normally
follow an intentional platform-support change across the SDK, wrappers, and relevant dependencies;
it is not a prerequisite for adopting Xcode 27. Keep the audit in CI after removing the helper so
a later dependency update cannot silently reintroduce a lower target.

The repository also includes a deterministic CI audit that prints the target, matching project,
and effective value for every generated target/configuration pair in stable order. It examines
every target in each passed project, including non-integrated targets that the normalizer
intentionally does not change; set those targets to the host minimum explicitly. Pass the `Pods`
directory so the audit discovers every `.xcodeproj` directly under it, including CocoaPods
multi-project output, while ignoring unrelated example projects vendored inside downloaded pod
sources. It fails if a supplied path is missing or contains no projects.

```sh
cd example
bundle exec ruby ../scripts/audit_cocoapods_deployment_targets.rb \
  --minimum 15.1 \
  ios/Pods \
  ios/SampleApp.xcodeproj
```

Keep this audit next to the React Native simulator build and unsigned generic-device archive.
Passing those checks does not prove real-device push delivery, signed archive export, or App Store
submission.
