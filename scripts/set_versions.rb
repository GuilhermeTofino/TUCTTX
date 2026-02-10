require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target_name = 'DynamicIslandWidgetExtension'
target = project.targets.find { |t| t.name == target_name }

if target
  target.build_configurations.each do |config|
    # Mapear variáveis do Flutter para os padrões da Apple
    config.build_settings['MARKETING_VERSION'] = '$(FLUTTER_BUILD_NAME)'
    config.build_settings['CURRENT_PROJECT_VERSION'] = '$(FLUTTER_BUILD_NUMBER)'
    
    # Garantir que a substituição ocorra
    config.build_settings['INFOPLIST_KEY_CFBundleShortVersionString'] = '$(FLUTTER_BUILD_NAME)'
    config.build_settings['INFOPLIST_KEY_CFBundleVersion'] = '$(FLUTTER_BUILD_NUMBER)'

    puts "Configurado versionamento padrão para #{config.name} no target #{target_name}"
  end
else
  puts "ERRO: Target #{target_name} não encontrado!"
end

project.save
puts "Projeto atualizado com configurações de versão padrão!"
