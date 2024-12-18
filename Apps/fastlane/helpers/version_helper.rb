require_relative 'github_helper.rb'
require_relative 'utils.rb'

# Lane to generate new version
lane :generate_new_version do |options|
  current_time = Time.now
  github = GitHub.new()

  if github.is_pull_request
    branch_name = github.pr_source_branch
  elsif github.is_commit_pushed
    branch_name = github.push_branch
  end

  # Replace '/' with '-' to avoid issues with unsupported characters in version name
  branch_name = branch_name.gsub('/', '-')
  # Extract ticket number from branch name
  ticket_number_in_branch_name = branch_name.scan(/\d+/).join
  # If no ticket number found, set it to 0
  ticket_number_in_branch_name = ticket_number_in_branch_name.empty? ? "0" : ticket_number_in_branch_name

  # Format the components individually and remove leading zeros
  year = current_time.year.to_s
  month = current_time.month.to_s
  day = current_time.day.to_s
  hour = current_time.hour.to_s
  minute = current_time.min.to_s
  second = current_time.sec.to_s
  
  # Combine them into the desired format
  major = "#{year}#{month}#{day}"
  minor = "#{hour}#{minute}#{second}"
  patch = ticket_number_in_branch_name.to_s

  sdk_version_name = "#{major}.#{minor}.#{patch}"

  if github.is_pull_request
    app_version_name = "#{github.pr_number}.#{github.pr_commits}.0"
  else
    app_version_name = "#{sdk_version_name}-#{branch_name}"
  end
  app_version_code = (current_time.to_f / 60).to_i

  UI.message("Generated new versions => SDK: #{sdk_version_name}, App: #{app_version_name} (#{app_version_code})")
  sh("echo SDK_VERSION_NAME=#{sdk_version_name} >> $GITHUB_ENV")
  sh("echo APP_VERSION_NAME=#{app_version_name} >> $GITHUB_ENV")
  sh("echo APP_VERSION_CODE=#{app_version_code} >> $GITHUB_ENV")
end

# Helper method to update Android version
def update_android_version(project_path, version_name, version_code)
  build_gradle_path = File.join(project_path, 'android/app/build.gradle')

  unless File.exist?(build_gradle_path)
    UI.user_error!("build.gradle not found at #{build_gradle_path}")
  end

  android_set_version_name(
    gradle_file: build_gradle_path,
    version_name: version_name
  )
  android_set_version_code(
    gradle_file: build_gradle_path,
    version_code: version_code
  )
  UI.message("Updated versionName and versionCode to #{version_name} and #{version_code} in #{build_gradle_path}")
end

# Helper method to update iOS version
def update_ios_version(project_path, version_name, build_number)
  # Load all configurations from Gymfile so they can be reused
  gym_config = read_gymfile()
  gymfile_scheme = gym_config["scheme"]
  
  unless gymfile_scheme
    UI.user_error!("No scheme found in Gymfile configuration: #{gym_config}")
  end

  xcodeproj_name = "#{gymfile_scheme}.xcodeproj"
  xcodeproj_path = File.join(project_path, 'ios', xcodeproj_name)

  UI.message("Checking for #{xcodeproj_name} at #{xcodeproj_path} with version #{version_name} and build number #{build_number}")
  unless File.exist?(xcodeproj_path)
    UI.user_error!("#{xcodeproj_name} not found at #{xcodeproj_path}")
  end

  ios_set_version(
    xcodeproj: xcodeproj_path,
    version: version_name
  )
  ios_set_build_number(
    xcodeproj: xcodeproj_path,
    build_number: build_number
  )
  UI.message("Updated version and build number to #{version_name} and #{build_number} in #{xcodeproj_path}")
end
