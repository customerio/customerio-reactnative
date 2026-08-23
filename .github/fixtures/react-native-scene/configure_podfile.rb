podfile_path = ARGV.fetch(0)
podfile = File.read(podfile_path)

helper = <<~'RUBY'
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
RUBY

platform_line = "platform :ios, min_ios_version_supported\n"
raise 'missing React Native platform declaration' unless podfile.include?(platform_line)

target_line = "target 'CioRnSceneHost' do\n"
raise 'missing React Native application target' unless podfile.include?(target_line)

apn_pod = "  pod 'customerio-reactnative', :path => customer_io_package_root, :subspecs => ['apn']\n"

post_install_end = <<~'RUBY'
      )
    end
  end
RUBY
normalizer = <<~'RUBY'
      )

      CustomerIO::CocoaPodsDeploymentTarget.normalize!(
        installer,
        minimum_ios_version: customer_io_minimum_ios_version
      )
    end
  end
RUBY
raise 'unexpected React Native post_install block' unless podfile.end_with?(post_install_end)

podfile.sub!(platform_line, "#{helper}\n#{platform_line}")
podfile.sub!(target_line, "#{target_line}#{apn_pod}")
podfile.delete_suffix!(post_install_end)
podfile << normalizer
File.write(podfile_path, podfile)
