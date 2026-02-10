require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'DynamicIslandWidgetExtension'
target = project.targets.find { |t| t.name == target_name }

if target
  target.build_configurations.each do |config|
    # Desativar geração automática para usar apenas o arquivo manual corrigido
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
    puts "Desativado GENERATE_INFOPLIST_FILE para #{config.name} no target #{target_name}"
  end
else
  puts "ERRO: Target #{target_name} não encontrado!"
end

project.save
puts "Configurações de build do Widget atualizadas!"
