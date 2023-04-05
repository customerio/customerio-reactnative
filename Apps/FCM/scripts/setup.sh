#!/usr/bin/env bash

set -eo pipefail

function main() {
	cat <<EOF
===============================================================================
amiapp-reactnative setup checklist

Follow the steps in to setup dev environment to be able to build and run the
amiapp-reactnative app in the simulator or on a phone.
You can follow along and manually run all the steps, but some do offer you the
option to run the commands for you as well.
===============================================================================
EOF

	step 'Install Xcode from the App Store or the Self Service app'

	step 'Set xcode command line tools
- Open Xcode
- In the menu bar select Xcode -> Settings
- Go to the Locations tab
- Ensure Command Line Tools are set under the dropdown
	- If it mentions "No Xcode Selected" just pick the latest version from the dropdown
https://stackoverflow.com/questions/50404109/unable-to-locate-xcode-please-make-sure-to-have-xcode-installed-on-your-machine/51246596#51246596'

	step 'Install Android Studio from their website or using homebrew by running:
	brew install --cask android-studio' run_install_android_studio

	step 'Set environment variables for java and android tools by running:
	export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
	export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
	export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
	export PATH="$ANDROID_SDK_ROOT/tools:$PATH"
You may want to save these in your ~/.zshrc file so that you do not need to set it again.'

	step 'Optional - Create virtual device
- With Android Studio open 
- In the menu bar select Tools -> Device Manager
- In the Device Manager panel click on Create Device button
- Select phone hardware ex. Pixel 6
- Download a system image by clicking the download icon next to the release name ex. Tiramisu
- Follow prompts to get virtual device setup'

	step 'Clone the "amiapp-reactnative" repository by running:
	git clone git@github.com:customerio/amiapp-reactnative.git' run_clone_repo

	step 'Download google credentials file and save it for android project
- Open 1Password
- Search for "Ami App RN - google-services.json"
- Download the file and save in the "amiapp-reactnative/android/app" directory'

	step 'Download google credentials file and save it for ios project
- Open 1Password
- Search for "Ami App RN - GoogleService-Info.plist"
- Download the file and save in the "amiapp-reactnative/ios/SampleApp" directory'

	step 'Download google credentials and save it.
- Open 1Password
- Search for "gc_keys.json"
- Download the file and save to easily referenced location (eg. ~/code/dev-creds/gc_keys.json)'

	step 'Set environment variable to the saved credential file by running:
	export FASTLANE_GC_KEYS_FILE=[path to file from previous step] ex.
	export FASTLANE_GC_KEYS_FILE=~/code/dev-creds/gc_keys.json
You can also save this in your ~/.zshrc file so that you do not need to set it again.'

	step 'Navigate into the "amiapp-reactnative" repository'

	step 'Copy sample env file by running:
	cp env.sample.js env.js' run_copy_env_file

	step 'Update the credentials in the "env.js" file'

	step 'Install/Switch to ruby version specified in the .ruby-version file.
Syntax depends on the version manager tool you are using.
Some tools: rbenv, rvm, chruby, asdf, rtx, frum'

	step 'Install bundler tool to manage ruby gems for project by running:
	gem install bundler' run_install_bundler

	step 'Use bundler to install tools for the project by running:
	bundle install' run_install_gems

	step 'Install certificates & profiles for development by running:
	bundle exec fastlane ios dev_setup' run_fastlane_setup

	step 'Install/Switch to nodejs version specified in the .node-version file.
Syntax depends on the version manager tool you are using.
Some tools: nodeenv, nvm, n, asdf, rtx'

	step 'Install tools for the project by running:
	npx yarn install' run_install_yarn

	step 'Install iOS project dependencies using cocoapods by running:
	npx pod-install' run_install_pods

	step 'Run the react-native project by running:
	npx react-native start
Note if you run from the script you will need to open a new terminal and run the setup script again to continue' run_start_project

	step 'Optional - Check iOS devices and simulators avaialbe by running:
	xcrun xctrace list devices' run_list_ios_targets

	step 'Optional - Run app on an iOS device by running:
	npx react-native run-ios --device "Device Name"
or on the simulator by running:
	npx react-native run-ios --simulator "Simulator Name"'

	step 'Optional - Check android devices avaialbe by running:
	adb devices' run_list_android_targets

	step 'Optional - Run app on an android device by running:
	npx react-native run-android --deviceId "Device ID"
or on the simulator by running:
	npx react-native run-android
to run on the simulator make sure android studio is open and the simulator device is up'

}

# automated run functions to run the specified step

function run_clone_repo() {
	read -p "Directory where the repository should be cloned to: " dir
	if [[ ! -d "$dir" ]]; then
		echo "The directory $dir does not exist."
		exit 1
	fi

	repo_dir="$dir/amiapp-reactnative"
	if [[ ! -d "$repo_dir" ]] ; then
	  git clone git@github.com:customerio/amiapp-reactnative.git $repo_dir
	fi
}

function run_install_android_studio() {
	if [[ ! "$(command -v brew)" ]]; then
		echo "automated setup uses homebrew which is missing. install using:"
		echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
		exit 1
	fi 

	brew install --cask android-studio
}

function run_install_bundler() {
	check_ruby_version
	gem install bundler
}

function run_install_gems() {
	check_ruby_version

	if [[ ! -f "$repo_dir/Gemfile" ]]; then
		echo "Missing Gemfile recheck path to repository."
		exit 1
	fi

	bundle install
}

function run_fastlane_setup() {
	check_ruby_version

	if [[ -z "$FASTLANE_GC_KEYS_FILE" ]]; then
		read -p "Path to the gc_keys.json file: " keys_file
		export FASTLANE_GC_KEYS_FILE=$keys_file
	fi

	bundle exec fastlane ios dev_setup
}

function run_copy_env_file() {
	set_repo_dir
	cd $repo_dir

	if [[ ! -f "env.js" ]] ; then
	  cp "env.sample.js" "env.js"
	fi
}

function run_install_yarn() {
	check_node_version
	npx yarn install
}

function run_install_pods() {
	check_node_version
	npx pod-install
}

function run_start_project() {
	set_repo_dir
	cd $repo_dir

	npx react-native start
}

function run_list_ios_targets() {
	if [[ ! "$(command -v xcrun)" ]]; then
		echo "xcrun is missing make sure xcode and command line tools are configured"
		exit 1
	fi 

	xcrun xctrace list devices
}

function run_list_android_targets() {
	local adb_binary=adb

	if [[ ! "$(command -v adb)" ]]; then
		if [[ -f "$HOME/Library/Android/sdk/platform-tools/adb" ]]; then
			adb_binary="$HOME/Library/Android/sdk/platform-tools/adb"
		else
			echo "adb is missing make sure android studio is configured along with android sdk"
			exit 1
		fi
	fi

	$adb_binary devices
}

# helper functions

# helper utility to check node version matches from .node-version file.
# 
function check_node_version() {
	set_repo_dir

	cd $repo_dir

	if ! node -v | grep -q $(cat .node-version); then
		echo "Detected different node version
	got: $(node -v)
	expected: $(cat .node-version)
May need to switch to the node version in the shell and rerun this script."
		exit 1
	fi
}

# helper utility to check ruby version matches from .ruby-version file.
# 
function check_ruby_version() {
	set_repo_dir

	cd $repo_dir

	if ! ruby -v | grep -q $(cat .ruby-version); then
		echo "Detected different ruby version
	got: $(ruby -v)
	expected: $(cat .ruby-version)
May need to switch to the ruby version in the shell and rerun this script."
		exit 1
	fi
}


# helper utility to check if repo_dir variable exists or prompt for it.
# 
function set_repo_dir() {
	if [[ ! -d "$repo_dir" ]]; then
		read -p "Path to the repository: " repo_dir
	fi

	if [[ ! -d "$repo_dir" ]] ; then
		echo "Repository not found."
		exit 1
	fi
}

# helper utility to print the step and handle the user input.
# params:
# 	$1 - description of the step
# 	$2 - function to call if step can be run within the script if user opts for it
# 
function step() {
	((step_idx++))
	cat <<EOF

Step $step_idx: $1

EOF

	handle_input $2
}

# helper utility to ask for user input.
# params:
# 	$1 - if provided enables run option and calls function if selected
# 
function handle_input() {
	local prompt=''
	if [[ -n $1 ]]; then
		while true; do
			read -p "Choose [c]ontinue, [q]uit or [r]un: " answer
			case $answer in
				[Qq]* ) exit 0 ;;
				[Cc]* ) break ;;
				[Rr]* ) $1 && break ;;
			esac
		done
	else
		while true; do
			read -p "Choose [c]ontinue or [q]uit: " answer
			case $answer in
				[Qq]* ) exit 0 ;;
				[Cc]* ) break ;;
			esac
		done
	fi
}

main "$@"
