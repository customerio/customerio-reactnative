require 'json'
require 'xcodeproj'
require_relative 'github_helper.rb'
require_relative 'utils.rb'

platform :android do
  lane :build do |values|
    app_package_name = CredentialsManager::AppfileConfig.try_fetch_value(:package_name) # get package_name from Appfile

    firebase_app_id = find_firebase_app_id(app_identifier: app_package_name)
    UI.important(firebase_app_id)

    # Build release APK using Fastlane's Gradle tool
    gradle(
      project_dir: "./android",
      task: "assemble",
      build_type: "Release"
    )

    # Path to the APK generated by gradle (relative to project root)
    distribution_apk_path = "android/app/build/outputs/apk/release/app-release.apk"

    # Adjusted path for checking the APK from the Fastlane directory
    relative_apk_path = "../#{distribution_apk_path}"

    UI.message("Current working directory: #{Dir.pwd}, Looking for APK at: #{relative_apk_path}")
    # Check if the APK exists
    unless File.exist?(relative_apk_path)
      UI.user_error!("Couldn't find the APK at #{relative_apk_path}")
    end

    # function 'setup_google_bucket_access' is a re-usable function inside of apple-code-signing Fastfile that we imported.
    # This allows you to create a temporary file from a GitHub secret for added convenience.
    # When uploading the build to Firebase App Distribution, the CI server needs to authenticate with Firebase. This is done with a
    # Google Cloud Service Account json creds file. The base64 encoded value of this service account file is stored as this secret.
    service_credentials_file_path = setup_google_bucket_access(
      environment_variable_key: "FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT_CREDS_B64"
    )

    firebase_app_distribution(
      apk_path: distribution_apk_path,
      app: firebase_app_id, # Firebase app id is required. Get it from google-services.json file
      service_credentials_file: service_credentials_file_path,
      groups: get_build_test_groups(distribution_groups: values[:distribution_groups]),
      release_notes: get_build_notes()
    )
  end
end

platform :ios do
  lane :build do |arguments|
    if ENV["CI"]
      download_ci_code_signing_files
    else
      download_development_code_signing
    end

    # prevents builds from being flaky. As app sizes get bigger, it takes fastlane longer to initialize the build process. Increase this value to compensate for that.
    ENV["FASTLANE_XCODEBUILD_SETTINGS_RETRIES"] = "10"

    # Load all configurations from Gymfile so they can be reused
    gym_config = read_gymfile()
    gymfile_scheme = gym_config["scheme"]
    UI.message("Building scheme: #{gymfile_scheme}")

    # Build IPA using gym (Fastlane's built-in tool for building iOS apps)
    gym(scheme: gymfile_scheme)

    are_environment_variables_set_for_build_uploading = ENV["FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT_CREDS_B64"]

    environment_variables_required_for_build_uploading = ["FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT_CREDS_B64"] # array of keys
    are_environment_variables_set_for_build_uploading = environment_variables_required_for_build_uploading.all? { |key| ENV[key] != nil && !ENV[key].empty? } # check if all environment variables are set and not empty
    if !are_environment_variables_set_for_build_uploading
      UI.important("Environment variables required for uploading QA builds are not set. Therefore, not uploading build to Firebase App Distribution.")
    else
      # function 'setup_google_bucket_access' is a re-usable function inside of apple-code-signing Fastfile that we imported.
      # This allows you to create a temporary file from a GitHub secret for added convenience.
      # When uploading the build to Firebase App Distribution, the CI server needs to authenticate with Firebase. This is done with a
      # Google Cloud Service Account json creds file. The base64 encoded value of this service account file is stored as this secret.
      service_credentials_file_path = setup_google_bucket_access(
        environment_variable_key: "FIREBASE_APP_DISTRIBUTION_SERVICE_ACCOUNT_CREDS_B64"
      )

      firebase_app_distribution(
        service_credentials_file: service_credentials_file_path,
        groups: get_build_test_groups(distribution_groups: arguments[:distribution_groups]),
        release_notes: get_build_notes()
      )
    end
  end
end

# Firebase App Distribution allows you to attach notes to each build uploaded. These notes are searchable so we use the notes
# field to allow QA to quickly find builds they should install. We populate the notes with metadata from GitHub.
# GitHub Actions is the CI product we use to create builds of our apps. GitHub Actions provides metadata about the build
# via a JSON file. We parse this JSON file and pull out fields from it to populate the notes.
lane :get_build_notes do
  build_notes = []
  github = GitHub.new()

  if github.is_pull_request
    build_notes.append(
      "build type: pull request",
      "pr title: #{github.pr_title}",
      "pr number: #{github.pr_number}",
      "pr author: #{github.pr_author}",
      "commit hash: #{github.pr_commit_hash}",
      "source branch: #{github.pr_source_branch}",
      "destination branch: #{github.pr_destination_branch}"
    )
  elsif github.is_commit_pushed
    build_notes.append(
      "build type: commit pushed to branch",
      "branch: #{github.push_branch}",
      "commit hash: #{github.push_commit_hash}"
    )
  end

  build_notes = build_notes.join("\n")

  UI.important("Build notes for this build:\n#{build_notes}")

  build_notes # return value
end

lane :get_build_test_groups do |arguments|
  # Firebase App Distribution expects a comma separated string of test group names.
  # If no groups are passed in, then set test groups to an empty string.
  test_groups = arguments[:distribution_groups] || ""

  UI.important("Test group names that will be added to this build: #{test_groups}")

  test_groups # return value
end

