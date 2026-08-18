# frozen_string_literal: true

# Keep this helper byte-identical across customerio-ios, customerio-flutter, and
# customerio-reactnative so every wrapper applies the same CocoaPods contract.

require "rubygems/version"

module CustomerIO
  # Normalizes every CocoaPods-generated target and every integrated application or extension
  # target to a numeric iOS deployment target that the selected Xcode toolchain supports.
  module CocoaPodsDeploymentTarget
    BUILD_SETTING = "IPHONEOS_DEPLOYMENT_TARGET"
    VERSION_PATTERN = /\A\d+(?:\.\d+){0,2}\z/.freeze

    Record = Struct.new(
      :project,
      :target,
      :configuration,
      :original_effective,
      :target_configuration_value,
      :project_value,
      :current,
      :changed,
      :configuration_object,
      keyword_init: true
    )

    class AuditError < StandardError; end

    module_function

    # Raises low effective deployment settings to +minimum_ios_version+. A missing target setting
    # resolves through its xcconfig and then the same-named project configuration. Numeric effective
    # settings above the minimum are preserved. A selected non-numeric effective setting fails
    # closed because its resolved value cannot be audited deterministically from the project.
    def normalize!(installer, minimum_ios_version:, io: $stdout)
      minimum = parse_version!(minimum_ios_version, context: "minimum iOS version")
      targets = installer_targets(installer)
      records = records_for(targets)
      ensure_records!(records)
      validate_numeric_settings!(records)

      records = records.map do |record|
        normalize_record!(record, minimum)
      end

      audit_records!(records, minimum)
      save_integrated_user_projects!(installer, records)
      write_changes(io, records)
      write_summary(io, records, minimum)
      records
    end

    # Audits an installer without modifying it. This is useful from a second post-install check.
    def audit!(installer, minimum_ios_version:, io: $stdout)
      minimum = parse_version!(minimum_ios_version, context: "minimum iOS version")
      records = records_for(installer_targets(installer))
      ensure_records!(records)

      audit_records!(records, minimum)
      write_summary(io, records, minimum)
      records
    end

    # Audits projects loaded by Xcodeproj. The caller owns loading the projects so this helper does
    # not add a runtime dependency on Xcodeproj to the normal Podfile integration path.
    def audit_projects!(projects, minimum_ios_version:, io: $stdout)
      minimum = parse_version!(minimum_ios_version, context: "minimum iOS version")
      targets = projects.flat_map { |project| project.targets }
      records = records_for(targets)
      ensure_records!(records)

      audit_records!(records, minimum)
      write_records(io, records, minimum)
      records
    end

    # Returns the greater of two numeric iOS deployment targets. React Native integrations use
    # this to preserve React Native's own floor when it is higher than Customer.io's floor.
    def maximum(first, second)
      first_version = parse_version!(first, context: "iOS version")
      second_version = parse_version!(second, context: "iOS version")
      [first_version, second_version].max.to_s
    end

    def installer_targets(installer)
      generated_projects = if installer.respond_to?(:generated_projects)
                             Array(installer.generated_projects).compact
                           else
                             []
                           end
      if generated_projects.empty? && installer.respond_to?(:pods_project)
        generated_projects = [installer.pods_project].compact
      end

      pod_targets = generated_projects.flat_map { |project| project.targets }
      user_targets = if installer.respond_to?(:aggregate_targets)
                       Array(installer.aggregate_targets).flat_map do |aggregate_target|
                         aggregate_target.respond_to?(:user_targets) ? Array(aggregate_target.user_targets) : []
                       end
                     else
                       []
                     end

      deduplicate_targets(pod_targets + user_targets)
    end
    private_class_method :installer_targets

    def save_integrated_user_projects!(installer, records)
      return unless installer.respond_to?(:aggregate_targets)

      changed_project_paths = records.select(&:changed).map(&:project).uniq
      return if changed_project_paths.empty?

      projects = Array(installer.aggregate_targets).each_with_object([]) do |aggregate_target, result|
        if aggregate_target.respond_to?(:user_project)
          user_project = aggregate_target.user_project
          result << user_project unless user_project.nil?
        end
        next unless aggregate_target.respond_to?(:user_targets)

        Array(aggregate_target.user_targets).each do |target|
          result << target.project if target.respond_to?(:project) && !target.project.nil?
        end
      end.compact

      projects.select { |project| changed_project_paths.include?(project_path(project)) }
              .uniq { |project| project_path(project) }
              .each do |project|
        unless project.respond_to?(:save)
          raise AuditError, "Cannot save integrated user project #{project_path(project)}"
        end

        project.save
      end
    end
    private_class_method :save_integrated_user_projects!

    def deduplicate_targets(targets)
      targets.each_with_object({}) do |target, unique|
        project = target.respond_to?(:project) ? target.project : nil
        project_key = project_path(project)
        target_key = target.respond_to?(:uuid) ? target.uuid : target.object_id
        unique[[project_key, target_key]] ||= target
      end.values
    end
    private_class_method :deduplicate_targets

    def normalize_record!(record, minimum)
      current = record.current
      current_version = current.nil? ? nil : parse_version!(current, context: record_context(record))
      return record if current_version && current_version >= minimum

      record.configuration_object.build_settings[BUILD_SETTING] = minimum.to_s
      record.current = minimum.to_s
      record.changed = true
      record
    end
    private_class_method :normalize_record!

    def records_for(targets)
      targets.flat_map do |target|
        project = target.respond_to?(:project) ? target.project : nil
        target.build_configurations.map do |configuration|
          context = configuration_context(project, target, configuration)
          validate_no_conditional_settings!(configuration.build_settings, context: context)
          target_setting_present = configuration.build_settings.key?(BUILD_SETTING)
          target_value = normalized_setting(configuration.build_settings[BUILD_SETTING])
          if target_setting_present
            target_configuration_value = nil
            project_value = nil
            effective_value = target_value
          else
            target_configuration_present, target_configuration_value = configuration_file_setting(
              configuration,
              context: context
            )
            if target_configuration_present
              project_value = nil
              effective_value = target_configuration_value
            else
              project_configuration = matching_project_configuration(project, configuration.name)
              project_value = effective_configuration_value(
                project_configuration,
                context: context
              )
              effective_value = project_value
            end
          end
          Record.new(
            project: project_path(project),
            target: target.name.to_s,
            configuration: configuration.name.to_s,
            original_effective: effective_value,
            target_configuration_value: target_configuration_value,
            project_value: project_value,
            current: effective_value,
            changed: false,
            configuration_object: configuration
          )
        end
      end.sort_by { |record| [record.project, record.target, record.configuration] }
    end
    private_class_method :records_for

    def effective_configuration_value(configuration, context:)
      return nil if configuration.nil?

      validate_no_conditional_settings!(configuration.build_settings, context: context)

      if configuration.build_settings.key?(BUILD_SETTING)
        return normalized_setting(configuration.build_settings[BUILD_SETTING])
      end

      _present, value = configuration_file_setting(configuration, context: context)
      value
    end
    private_class_method :effective_configuration_value

    def configuration_file_setting(configuration, context:)
      synchronized_anchor = if configuration.respond_to?(:base_configuration_reference_anchor)
                              configuration.base_configuration_reference_anchor
                            end
      synchronized_relative_path = if configuration.respond_to?(:base_configuration_reference_relative_path)
                                     configuration.base_configuration_reference_relative_path
                                   end
      if synchronized_anchor || synchronized_relative_path
        raise AuditError,
              "#{context}: Cannot inspect synchronized-group xcconfig " \
              "#{rendered_synchronized_path(synchronized_anchor, synchronized_relative_path)}. " \
              "Use a standard xcconfig file reference before rerunning CocoaPods."
      end

      base_configuration_reference = if configuration.respond_to?(:base_configuration_reference)
                                       configuration.base_configuration_reference
                                     end
      if base_configuration_reference
        xcconfig_path = if base_configuration_reference.respond_to?(:real_path)
                          base_configuration_reference.real_path
                        end
        unless xcconfig_path.respond_to?(:exist?) && xcconfig_path.exist? &&
               xcconfig_path.respond_to?(:readable?) && xcconfig_path.readable?
          rendered_path = xcconfig_path.nil? ? "(unresolved path)" : xcconfig_path.to_s
          raise AuditError, "#{context}: Cannot read xcconfig #{rendered_path}"
        end

        unless defined?(::Xcodeproj::Config)
          raise AuditError,
                "#{context}: Cannot parse xcconfig #{xcconfig_path}; Xcodeproj::Config is unavailable"
        end

        begin
          settings = ::Xcodeproj::Config.new(xcconfig_path).to_hash
        rescue StandardError => error
          raise AuditError,
                "#{context}: Cannot parse xcconfig #{xcconfig_path}: " \
                "#{error.class}: #{error.message}"
        end

        unless settings.respond_to?(:key?)
          raise AuditError, "#{context}: Cannot inspect xcconfig #{xcconfig_path}"
        end
        validate_no_conditional_settings!(
          settings,
          context: "#{context}, xcconfig #{xcconfig_path}"
        )
        return [false, nil] unless settings.key?(BUILD_SETTING)

        return [true, normalized_setting(settings[BUILD_SETTING])]
      end

      [false, nil]
    end
    private_class_method :configuration_file_setting

    def validate_no_conditional_settings!(settings, context:)
      conditional_keys = settings.keys.map(&:to_s).select do |key|
        key.start_with?("#{BUILD_SETTING}[")
      end.sort
      return if conditional_keys.empty?

      raise AuditError,
            "#{context} has conditional #{BUILD_SETTING} settings that cannot be audited deterministically: " \
            "#{conditional_keys.join(', ')}. Replace them with one numeric, unconditional #{BUILD_SETTING} " \
            "before running this helper."
    end
    private_class_method :validate_no_conditional_settings!

    def rendered_synchronized_path(anchor, relative_path)
      anchor_path = if anchor.respond_to?(:path)
                      anchor.path
                    elsif anchor.respond_to?(:display_name)
                      anchor.display_name
                    else
                      "(unknown anchor)"
                    end
      [anchor_path, relative_path].compact.map(&:to_s).reject(&:empty?).join("/")
    end
    private_class_method :rendered_synchronized_path

    def matching_project_configuration(project, configuration_name)
      return nil if project.nil? || !project.respond_to?(:build_configurations)

      Array(project.build_configurations).find do |configuration|
        configuration.name.to_s == configuration_name.to_s
      end
    end
    private_class_method :matching_project_configuration

    def ensure_records!(records)
      return unless records.empty?

      raise AuditError, "CocoaPods iOS deployment-target audit found no target configurations"
    end
    private_class_method :ensure_records!

    def validate_numeric_settings!(records)
      records.each do |record|
        parse_version!(record.current, context: record_context(record)) unless record.current.nil?
      end
    end
    private_class_method :validate_numeric_settings!

    def audit_records!(records, minimum)
      violations = records.each_with_object([]) do |record, result|
        current = record.current
        if current.nil?
          result << "#{record_context(record)} is missing #{BUILD_SETTING}"
        else
          begin
            version = parse_version!(current, context: record_context(record))
            if version < minimum
              result << "#{record_context(record)} is #{current}, below #{minimum}"
            end
          rescue AuditError => error
            result << error.message
          end
        end
      end

      return if violations.empty?

      raise AuditError, "CocoaPods iOS deployment-target audit failed:\n- #{violations.join("\n- ")}"
    end
    private_class_method :audit_records!

    def write_summary(io, records, minimum)
      return if io.nil?

      changed = records.count(&:changed)
      io.puts(
        "Customer.io CocoaPods deployment-target audit passed: " \
        "#{records.length} target configurations at iOS #{minimum} or newer (#{changed} normalized)."
      )
    end
    private_class_method :write_summary

    def write_changes(io, records)
      return if io.nil?

      records.select(&:changed).each do |record|
        original = record.original_effective.nil? ? "missing" : record.original_effective
        io.puts(
          "Customer.io CocoaPods deployment target normalized: " \
          "#{record_context(record)}: #{original} -> #{record.current}"
        )
      end
    end
    private_class_method :write_changes

    def write_records(io, records, minimum)
      return if io.nil?

      io.puts(
        "project\ttarget\tconfiguration\ttarget_#{BUILD_SETTING}\t" \
        "target_xcconfig_#{BUILD_SETTING}\t" \
        "project_#{BUILD_SETTING}\teffective_#{BUILD_SETTING}"
      )
      records.each do |record|
        target_value = normalized_setting(record.configuration_object.build_settings[BUILD_SETTING])
        io.puts(
          [
            record.project,
            record.target,
            record.configuration,
            target_value,
            record.target_configuration_value,
            record.project_value,
            record.current
          ].join("\t")
        )
      end
      write_summary(io, records, minimum)
    end
    private_class_method :write_records

    def parse_version!(value, context:)
      normalized = normalized_setting(value)
      unless normalized&.match?(VERSION_PATTERN)
        rendered = normalized.nil? ? "missing" : normalized.inspect
        raise AuditError, "#{context} has non-numeric #{BUILD_SETTING}: #{rendered}"
      end

      Gem::Version.new(normalized)
    end
    private_class_method :parse_version!

    def normalized_setting(value)
      normalized = value.nil? ? nil : value.to_s.strip
      normalized.nil? || normalized.empty? ? nil : normalized
    end
    private_class_method :normalized_setting

    def record_context(record)
      "#{record.project}: target #{record.target}, configuration #{record.configuration}"
    end
    private_class_method :record_context

    def configuration_context(project, target, configuration)
      "#{project_path(project)}: target #{target.name}, configuration #{configuration.name}"
    end
    private_class_method :configuration_context

    def project_path(project)
      return "unknown-project" if project.nil?
      return project.path.to_s if project.respond_to?(:path) && project.path

      project.to_s
    end
    private_class_method :project_path
  end
end
