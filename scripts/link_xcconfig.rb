require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'DynamicIslandWidgetExtension'
target = project.targets.find { |t| t.name == target_name }

# ID do Generated.xcconfig encontrado via grep
xcconfig_ref_id = '9740EEB31CF90195004384FC'
xcconfig_file = project.files.find { |f| f.uuid == xcconfig_ref_id }

if target && xcconfig_file
  target.build_configurations.each do |config|
    # Define a base configuration reference para o Generated.xcconfig
    config.base_configuration_reference = xcconfig_file
    puts "Vinculado Generated.xcconfig para #{config.name} no target #{target_name}"
  end
  project.save
  puts "Projeto atualizado: Widget agora herda configurações do Flutter!"
else
  puts "ERRO: Target #{target_name} ou Generated.xcconfig não encontrado!"
end
