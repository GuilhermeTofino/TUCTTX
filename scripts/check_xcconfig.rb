require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'DynamicIslandWidgetExtension'
target = project.targets.find { |t| t.name == target_name }

if target
  target.build_configurations.each do |config|
    ref = config.base_configuration_reference
    puts "Config: #{config.name}"
    puts "  Base Config: #{ref ? ref.path : 'NIL'}"
    puts "  Base Config ID: #{ref ? ref.uuid : 'NIL'}"
  end
else
  puts "Target not found"
end
