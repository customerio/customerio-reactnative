require 'xcodeproj'

project_path, app_name = ARGV
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |candidate| candidate.name == app_name }
raise "missing application target #{app_name}" unless target

group = project.main_group.find_subpath(app_name, true)
scene_delegate = group.files.find { |file| File.basename(file.path) == 'SceneDelegate.swift' }
scene_delegate ||= group.new_file("#{app_name}/SceneDelegate.swift")
target.source_build_phase.add_file_reference(scene_delegate, true)
project.save
