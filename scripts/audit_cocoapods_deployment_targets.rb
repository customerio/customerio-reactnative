#!/usr/bin/env ruby
# frozen_string_literal: true

require "optparse"
require "xcodeproj"
require_relative "../ios/cocoapods_deployment_target"

options = { minimum: "15.0" }
parser = OptionParser.new do |arguments|
  arguments.banner =
    "Usage: audit_cocoapods_deployment_targets.rb [options] PROJECT_OR_DIRECTORY [...]"
  arguments.on("--minimum VERSION", "Required numeric iOS deployment target (default: 15.0)") do |version|
    options[:minimum] = version
  end
end

parser.parse!
if ARGV.empty?
  warn parser
  exit 2
end

begin
  project_paths = ARGV.uniq.sort.flat_map do |path|
    unless File.directory?(path)
      raise CustomerIO::CocoaPodsDeploymentTarget::AuditError,
            "CocoaPods deployment-target audit path does not exist: #{path}"
    end

    if File.extname(path) == ".xcodeproj"
      [path]
    else
      Dir.glob(File.join(path, "**", "*.xcodeproj")).sort
    end
  end.uniq
  if project_paths.empty?
    raise CustomerIO::CocoaPodsDeploymentTarget::AuditError,
          "CocoaPods deployment-target audit found no .xcodeproj under: #{ARGV.join(', ')}"
  end

  projects = project_paths.map { |path| Xcodeproj::Project.open(path) }
  CustomerIO::CocoaPodsDeploymentTarget.audit_projects!(
    projects,
    minimum_ios_version: options[:minimum]
  )
rescue CustomerIO::CocoaPodsDeploymentTarget::AuditError, Xcodeproj::Informative => error
  warn error.message
  exit 1
end
