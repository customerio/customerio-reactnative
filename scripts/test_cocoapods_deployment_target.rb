# frozen_string_literal: true

require "minitest/autorun"
require "pathname"
require "stringio"
require "tmpdir"

begin
  require "xcodeproj"
rescue LoadError
  # Pure helper tests still run when Xcodeproj is unavailable. Real-object coverage is skipped.
end
require_relative "../ios/cocoapods_deployment_target"

class CocoaPodsDeploymentTargetTest < Minitest::Test
  Configuration = Struct.new(:name, :build_settings, :base_configuration_reference)
  ConfigurationReference = Struct.new(:real_path)
  OpaqueConfiguration = Struct.new(:name, :build_settings, :base_configuration_reference)
  OpaqueSynchronizedConfiguration = Struct.new(
    :name,
    :build_settings,
    :base_configuration_reference_anchor,
    :base_configuration_reference_relative_path
  )
  Project = Struct.new(:path, :targets, :save_count, :build_configurations) do
    def save
      self.save_count = save_count.to_i + 1
    end
  end
  Target = Struct.new(:name, :uuid, :project, :build_configurations)
  AggregateTarget = Struct.new(:user_targets, :user_project)
  Installer = Struct.new(:generated_projects, :pods_project, :aggregate_targets)

  def test_normalize_covers_generated_and_integrated_targets_and_preserves_higher_floors
    pods_project = Project.new(Pathname("Pods/Pods.xcodeproj"), [], 0)
    app_project = Project.new(Pathname("App.xcodeproj"), [], 0)
    privacy = target(pods_project, "CustomerIOCommon-CustomerIOCommon_Privacy", "13.0")
    aggregate = target(pods_project, "Pods-App", nil)
    app = target(app_project, "App", "16.0")
    extension = target(app_project, "NotificationServiceExtension", "14.0")
    widget = target(app_project, "LiveActivityWidget", "15.0")
    unrelated = target(app_project, "UnintegratedTarget", "12.0")
    pods_project.targets.concat([privacy, aggregate])
    app_project.targets.concat([app, extension, widget, unrelated])
    installer = Installer.new(
      [pods_project],
      nil,
      [AggregateTarget.new([app, extension], app_project), AggregateTarget.new([widget, app], app_project)]
    )

    records = CustomerIO::CocoaPodsDeploymentTarget.normalize!(
      installer,
      minimum_ios_version: "15.0",
      io: nil
    )

    assert_equal "15.0", deployment_target(privacy)
    assert_equal "15.0", deployment_target(aggregate)
    assert_equal "16.0", deployment_target(app)
    assert_equal "15.0", deployment_target(extension)
    assert_equal "15.0", deployment_target(widget)
    assert_equal "12.0", deployment_target(unrelated)
    assert_equal 10, records.length
    assert_equal 6, records.count(&:changed)
    assert_equal 1, app_project.save_count
  end

  def test_normalize_reports_each_changed_original_effective_value_in_stable_order
    pods_project = Project.new(Pathname("Pods/Pods.xcodeproj"), [], 0)
    missing = target(pods_project, "Missing", nil)
    pods_project.targets << missing
    app_project = project_with_floor("App.xcodeproj", "14.0")
    app = target(app_project, "App", nil)
    app_project.targets << app
    installer = Installer.new(
      [pods_project],
      nil,
      [AggregateTarget.new([app], app_project)]
    )
    output = StringIO.new

    CustomerIO::CocoaPodsDeploymentTarget.normalize!(
      installer,
      minimum_ios_version: "15.0",
      io: output
    )

    assert_equal(
      [
        "Customer.io CocoaPods deployment target normalized: App.xcodeproj: target App, configuration Debug: 14.0 -> 15.0\n",
        "Customer.io CocoaPods deployment target normalized: App.xcodeproj: target App, configuration Release: 14.0 -> 15.0\n",
        "Customer.io CocoaPods deployment target normalized: Pods/Pods.xcodeproj: target Missing, configuration Debug: missing -> 15.0\n",
        "Customer.io CocoaPods deployment target normalized: Pods/Pods.xcodeproj: target Missing, configuration Release: missing -> 15.0\n",
        "Customer.io CocoaPods deployment-target audit passed: 4 target configurations at iOS 15.0 or newer (4 normalized).\n"
      ],
      output.string.lines
    )
  end

  def test_normalize_fails_before_mutating_when_a_setting_is_not_numeric
    project = Project.new(Pathname("Pods.xcodeproj"), [], 0)
    low = target(project, "Low", "13.0")
    inherited = target(project, "Inherited", "$(inherited)")
    project.targets.concat([low, inherited])
    installer = Installer.new([project], nil, [])

    error = assert_raises(CustomerIO::CocoaPodsDeploymentTarget::AuditError) do
      CustomerIO::CocoaPodsDeploymentTarget.normalize!(
        installer,
        minimum_ios_version: "15.0",
        io: nil
      )
    end

    assert_includes error.message, "non-numeric"
    assert_equal "13.0", deployment_target(low)
  end

  def test_normalize_preserves_a_higher_inherited_project_floor
    pods_project = Project.new(Pathname("Pods.xcodeproj"), [], 0)
    dependency = target(pods_project, "Dependency", "14.0")
    pods_project.targets << dependency
    project = project_with_floor("App.xcodeproj", "16.0")
    app = target(project, "App", nil)
    project.targets << app
    installer = Installer.new([pods_project], nil, [AggregateTarget.new([app], project)])

    records = CustomerIO::CocoaPodsDeploymentTarget.normalize!(
      installer,
      minimum_ios_version: "15.0",
      io: nil
    )

    refute app.build_configurations.first.build_settings.key?(
      CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING
    )
    assert_equal "16.0", records.find { |record| record.target == "App" }.current
    assert_equal "15.0", deployment_target(dependency)
    assert_equal 2, records.count(&:changed)
    assert_equal 0, project.save_count
  end

  def test_normalize_raises_a_lower_inherited_project_floor
    project = project_with_floor("App.xcodeproj", "14.0")
    app = target(project, "App", nil)
    project.targets << app
    installer = Installer.new([], nil, [AggregateTarget.new([app], nil)])

    records = CustomerIO::CocoaPodsDeploymentTarget.normalize!(
      installer,
      minimum_ios_version: "15.0",
      io: nil
    )

    assert_equal "15.0", deployment_target(app)
    assert_equal "15.0", records.first.current
    assert_equal 2, records.count(&:changed)
    assert_equal 1, project.save_count
  end

  def test_normalize_sets_the_floor_when_target_and_project_settings_are_missing
    project = Project.new(Pathname("App.xcodeproj"), [], 0, project_configurations(nil))
    app = target(project, "App", nil)
    project.targets << app
    installer = Installer.new([], nil, [AggregateTarget.new([app], project)])

    records = CustomerIO::CocoaPodsDeploymentTarget.normalize!(
      installer,
      minimum_ios_version: "15.0",
      io: nil
    )

    assert_equal "15.0", deployment_target(app)
    assert_equal "15.0", records.first.current
    assert_equal 2, records.count(&:changed)
    assert_equal 1, project.save_count
  end

  def test_normalize_fails_before_mutating_a_non_numeric_inherited_project_floor
    project = project_with_floor("App.xcodeproj", "$(inherited)")
    low = target(project, "Low", "14.0")
    inherited = target(project, "Inherited", nil)
    project.targets.concat([low, inherited])
    installer = Installer.new(
      [],
      nil,
      [AggregateTarget.new([low, inherited], project)]
    )

    error = assert_raises(CustomerIO::CocoaPodsDeploymentTarget::AuditError) do
      CustomerIO::CocoaPodsDeploymentTarget.normalize!(
        installer,
        minimum_ios_version: "15.0",
        io: nil
      )
    end

    assert_includes error.message, "non-numeric"
    assert_equal "14.0", deployment_target(low)
    assert_nil deployment_target(inherited)
  end

  def test_normalize_ignores_a_non_numeric_lower_precedence_project_floor
    project = project_with_floor("App.xcodeproj", "$(CUSTOM_IOS_FLOOR)")
    app = target(project, "App", "16.0")
    project.targets << app
    installer = Installer.new([], nil, [AggregateTarget.new([app], project)])

    records = CustomerIO::CocoaPodsDeploymentTarget.normalize!(
      installer,
      minimum_ios_version: "15.0",
      io: nil
    )

    assert_equal %w[16.0 16.0], records.map(&:current)
    assert_equal 0, records.count(&:changed)
    assert_equal 0, project.save_count
  end

  def test_standalone_audit_reports_the_effective_inherited_project_floor
    project = project_with_floor("App.xcodeproj", "16.0")
    app = target(project, "App", nil)
    project.targets << app
    output = StringIO.new

    records = CustomerIO::CocoaPodsDeploymentTarget.audit_projects!(
      [project],
      minimum_ios_version: "15.0",
      io: output
    )

    assert_equal "16.0", records.first.current
    assert_includes output.string, "project_IPHONEOS_DEPLOYMENT_TARGET"
    assert_includes output.string, "effective_IPHONEOS_DEPLOYMENT_TARGET"
    assert_includes output.string, "target_xcconfig_IPHONEOS_DEPLOYMENT_TARGET"
    assert_includes output.string, "\t\t\t16.0\t16.0\n"
  end

  def test_normalize_preserves_a_higher_target_xcconfig_floor
    skip "Xcodeproj is unavailable" unless xcodeproj_available?

    Dir.mktmpdir do |directory|
      xcconfig_path = Pathname(directory).join("Target.xcconfig")
      File.write(xcconfig_path, "#{CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING} = 17.0\n")
      project = project_with_floor("App.xcodeproj", "14.0")
      app = target(project, "App", nil)
      app.build_configurations.each do |configuration|
        configuration.base_configuration_reference = ConfigurationReference.new(xcconfig_path)
      end
      project.targets << app
      installer = Installer.new([], nil, [AggregateTarget.new([app], project)])

      records = CustomerIO::CocoaPodsDeploymentTarget.normalize!(
        installer,
        minimum_ios_version: "15.0",
        io: nil
      )

      assert_nil deployment_target(app)
      assert_equal %w[17.0 17.0], records.map(&:current)
      assert_equal 0, records.count(&:changed)
      assert_equal 0, project.save_count
    end
  end

  def test_normalize_uses_public_xcodeproj_config_parser_with_real_project_objects
    skip "Xcodeproj is unavailable" unless xcodeproj_available?

    Dir.mktmpdir do |directory|
      project_path = Pathname(directory).join("App.xcodeproj")
      xcconfig_path = Pathname(directory).join("Target.xcconfig")
      File.write(xcconfig_path, "#{CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING} = 17.0\n")
      project = Xcodeproj::Project.new(project_path)
      app = project.new_target(:application, "App", :ios, "14.0")
      reference = project.main_group.new_file(xcconfig_path)
      app.build_configurations.each do |configuration|
        configuration.build_settings.delete(CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING)
        configuration.base_configuration_reference = reference
      end
      project.build_configurations.each do |configuration|
        configuration.build_settings[CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING] = "14.0"
      end
      installer = Installer.new([], nil, [AggregateTarget.new([app], project)])

      records = CustomerIO::CocoaPodsDeploymentTarget.normalize!(
        installer,
        minimum_ios_version: "15.0",
        io: nil
      )

      assert app.build_configurations.all? do |configuration|
        !configuration.build_settings.key?(CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING)
      end
      assert_equal %w[17.0 17.0], records.map(&:current)
      assert_equal 0, records.count(&:changed)
    end
  end

  def test_normalize_fails_closed_for_a_non_numeric_target_xcconfig_floor
    skip "Xcodeproj is unavailable" unless xcodeproj_available?

    Dir.mktmpdir do |directory|
      xcconfig_path = Pathname(directory).join("Target.xcconfig")
      File.write(xcconfig_path, "#{CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING} = $(CUSTOM_IOS_FLOOR)\n")
      project = project_with_floor("App.xcodeproj", "16.0")
      app = target(project, "App", nil)
      app.build_configurations.each do |configuration|
        configuration.base_configuration_reference = ConfigurationReference.new(xcconfig_path)
      end
      project.targets << app
      installer = Installer.new([], nil, [AggregateTarget.new([app], project)])

      error = assert_raises(CustomerIO::CocoaPodsDeploymentTarget::AuditError) do
        CustomerIO::CocoaPodsDeploymentTarget.normalize!(
          installer,
          minimum_ios_version: "15.0",
          io: nil
        )
      end

      assert_includes error.message, "non-numeric"
      assert_nil deployment_target(app)
      assert_equal 0, project.save_count
    end
  end

  def test_normalize_fails_closed_when_a_referenced_xcconfig_cannot_be_inspected
    project = project_with_floor("App.xcodeproj", "16.0")
    app = Target.new(
      "App",
      "App-uuid",
      project,
      [OpaqueConfiguration.new("Debug", {}, ConfigurationReference.new(Pathname("Missing.xcconfig")))]
    )
    project.targets << app
    installer = Installer.new([], nil, [AggregateTarget.new([app], project)])

    error = assert_raises(CustomerIO::CocoaPodsDeploymentTarget::AuditError) do
      CustomerIO::CocoaPodsDeploymentTarget.normalize!(
        installer,
        minimum_ios_version: "15.0",
        io: nil
      )
    end

    assert_includes error.message, "Cannot read xcconfig"
    assert_includes error.message, "App.xcodeproj: target App, configuration Debug"
    assert_includes error.message, "Missing.xcconfig"
    refute app.build_configurations.first.build_settings.key?(
      CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING
    )
    assert_equal 0, project.save_count
  end

  def test_normalize_fails_closed_when_a_synchronized_group_xcconfig_cannot_be_inspected
    project = project_with_floor("App.xcodeproj", "16.0")
    app = Target.new(
      "App",
      "App-uuid",
      project,
      [OpaqueSynchronizedConfiguration.new("Debug", {}, Object.new, "App.xcconfig")]
    )
    project.targets << app
    installer = Installer.new([], nil, [AggregateTarget.new([app], project)])

    error = assert_raises(CustomerIO::CocoaPodsDeploymentTarget::AuditError) do
      CustomerIO::CocoaPodsDeploymentTarget.normalize!(
        installer,
        minimum_ios_version: "15.0",
        io: nil
      )
    end

    assert_includes error.message, "Cannot inspect synchronized-group xcconfig"
    assert_includes error.message, "App.xcodeproj: target App, configuration Debug"
    assert_includes error.message, "App.xcconfig"
    refute app.build_configurations.first.build_settings.key?(
      CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING
    )
    assert_equal 0, project.save_count
  end

  def test_audit_lists_missing_low_and_non_numeric_settings
    project = Project.new(Pathname("Pods.xcodeproj"), [], 0)
    project.targets.concat([
      target(project, "Missing", nil),
      target(project, "Low", "14.0"),
      target(project, "Macro", "$(inherited)")
    ])
    installer = Installer.new([project], nil, [])

    error = assert_raises(CustomerIO::CocoaPodsDeploymentTarget::AuditError) do
      CustomerIO::CocoaPodsDeploymentTarget.audit!(
        installer,
        minimum_ios_version: "15.0",
        io: nil
      )
    end

    assert_includes error.message, "target Missing"
    assert_includes error.message, "target Low"
    assert_includes error.message, "target Macro"
  end

  def test_falls_back_to_pods_project_for_older_cocoapods_installers
    project = Project.new(Pathname("Pods.xcodeproj"), [], 0)
    dependency = target(project, "Dependency", "13.0")
    project.targets << dependency
    installer = Installer.new([], project, [])

    CustomerIO::CocoaPodsDeploymentTarget.normalize!(
      installer,
      minimum_ios_version: "15.0",
      io: nil
    )

    assert_equal "15.0", deployment_target(dependency)
  end

  def test_empty_installer_fails_closed
    installer = Installer.new([], nil, [])

    assert_raises(CustomerIO::CocoaPodsDeploymentTarget::AuditError) do
      CustomerIO::CocoaPodsDeploymentTarget.normalize!(
        installer,
        minimum_ios_version: "15.0",
        io: nil
      )
    end
  end

  def test_maximum_preserves_react_native_floor
    assert_equal "15.1", CustomerIO::CocoaPodsDeploymentTarget.maximum("15.0", "15.1")
    assert_equal "16.0", CustomerIO::CocoaPodsDeploymentTarget.maximum("16.0", "15.1")
  end

  private

  def xcodeproj_available?
    defined?(Xcodeproj::Config) && defined?(Xcodeproj::Project)
  end

  def target(project, name, deployment_target)
    configurations = %w[Debug Release].map do |configuration_name|
      settings = {}
      settings[CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING] = deployment_target unless deployment_target.nil?
      Configuration.new(configuration_name, settings)
    end
    Target.new(name, "#{name}-uuid", project, configurations)
  end

  def deployment_target(target)
    target.build_configurations.first.build_settings[
      CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING
    ]
  end

  def project_with_floor(path, deployment_target)
    Project.new(Pathname(path), [], 0, project_configurations(deployment_target))
  end

  def project_configurations(deployment_target)
    %w[Debug Release].map do |configuration_name|
      settings = {}
      settings[CustomerIO::CocoaPodsDeploymentTarget::BUILD_SETTING] = deployment_target unless deployment_target.nil?
      Configuration.new(configuration_name, settings)
    end
  end
end
