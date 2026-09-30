#!/usr/bin/env ruby

app_env_path, template_path, output_path = ARGV
abort 'usage: configure_nse_env.rb APP_ENV TEMPLATE OUTPUT' unless output_path

app_env = File.read(app_env_path)
primary_config = app_env.match(/primary:\s*\{(?<config>.*?)\}\s+satisfies/m)
abort 'APN sample primary config was not found' unless primary_config

api_key = primary_config[:config].match(/API_KEY:\s*'(?<value>[^']+)'/)&.[](:value)
abort 'APN sample CDP API key was not found' if api_key.nil? || api_key.empty? || api_key.include?('<')

template = File.read(template_path)
abort 'notification service extension template placeholder was not found' unless template.include?('<API_KEY>')

File.write(output_path, template.sub('<API_KEY>', api_key))
