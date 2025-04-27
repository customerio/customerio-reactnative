
# Updates the symlinks in the BuildSettings folder for the app and NSE targets
# based on the push provider.
# The symlinks point to the xcconfig files that contain the app name, app id, provisioning profile, etc.

def update_project_build_settings(installation_root, app_target_name, nse_target_name, push_provider)

  # Create a symlink to the GoogleService-Info.plist file in the root of the project
  # This file contains the configs for Firebase app distribution
  src_google_service_info = "#{installation_root}/#{app_target_name}/GoogleService-Info_#{push_provider}.plist"
  dest_google_service_info = "#{installation_root}/#{app_target_name}/GoogleService-Info.plist"
  system("ln -f #{src_google_service_info} #{dest_google_service_info}")

  [app_target_name, nse_target_name].each do |target|
    ["Debug", "Release"].each do |config|
      # This will create a symlink to the xcconfig file in the build settings folder
      # The xcconfig file contains the app id, provisioning profile, and other settings
      # that are specific to the sample app we build for testing
      build_settings_path = "#{installation_root}/#{target}/BuildSettings"
      
      src_config = "#{build_settings_path}/#{push_provider}/#{config}.xcconfig"
      dest_config = "#{build_settings_path}/.#{config}.xcconfig"
      system("ln -f #{src_config} #{dest_config}")
    end
  end
end

def create_project_file_if_not_exists(project_ios_dir, app_name)
  project_path = "#{project_ios_dir}/#{app_name}.xcodeproj"
  unless File.exist?(project_path)
    FileUtils.cp_r("#{project_path}.tracked", project_path)
  end
end
