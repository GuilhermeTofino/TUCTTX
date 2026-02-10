require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

extension_target_name = 'DynamicIslandWidgetExtension'
extension_target = project.targets.find { |t| t.name == extension_target_name }

if extension_target
  puts "Found target: #{extension_target.name}"
  
  # Path to Generated.xcconfig relative to the project
  flutter_config_path = 'Flutter/Generated.xcconfig'
  
  # Find or create file reference
  flutter_config_ref = project.files.find { |f| f.path == flutter_config_path }
  unless flutter_config_ref
    group = project.main_group.find_subpath('Flutter', false) || project.main_group.new_group('Flutter')
    flutter_config_ref = group.new_file(flutter_config_path)
    puts "Created reference for #{flutter_config_path}"
  end

  extension_target.build_configurations.each do |config|
    # Check if base configuration is already set
    if config.base_configuration_reference
      puts "Base config already set for #{config.name}: #{config.base_configuration_reference.path}"
      
      # config.base_configuration_reference.path is relative to the project setup.
      # It seems Xcodeproj returns it as "Target Support Files/..." but on disk it is in "Pods/Target Support Files/..."
      # OR it is "Pods/Target Support Files/..." in the ref, but we are in root.
      # Let's check if it exists at ios/Pods + path first.
      
      pods_config_path = File.join('ios', 'Pods', config.base_configuration_reference.path)
      
      unless File.exist?(pods_config_path)
         # Fallback: maybe the ref already includes "Pods"?
         pods_config_path = File.join('ios', config.base_configuration_reference.path)
      end
      
      if File.exist?(pods_config_path)
        content = File.read(pods_config_path)
        old_directive = '#include "../../Flutter/Generated.xcconfig"'
        new_directive = '#include "../../../Flutter/Generated.xcconfig"'
        
        # Check if old directive exists and replace it, or append new one if neither exists
        if content.include?(old_directive)
           puts "Replacing incorrect include path in #{pods_config_path}"
           new_content = content.gsub(old_directive, new_directive)
           File.write(pods_config_path, new_content)
        elsif !content.include?(new_directive)
           puts "Injecting include into #{pods_config_path}"
           File.open(pods_config_path, 'a') do |f|
             f.puts ""
             f.puts new_directive
           end
        else
           puts "Correct include already present in #{pods_config_path}"
        end
      else
        puts "Warning: Config file not found at #{pods_config_path}"
      end
    else
      config.base_configuration_reference = flutter_config_ref
      puts "Set base configuration for #{config.name} to #{flutter_config_path}"
    end
  end
  
  project.save
  puts "Project saved."
else
  puts "Target #{extension_target_name} not found!"
  exit 1
end
