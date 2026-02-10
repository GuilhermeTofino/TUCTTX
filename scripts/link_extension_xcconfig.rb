require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

extension_target = project.targets.find { |t| t.name == 'DynamicIslandWidgetExtension' }

if extension_target
  puts "Target encontrado: #{extension_target.name}"
  
  extension_target.build_configurations.each do |config|
    config_name = config.name
    # Mapping logic:
    # Debug -> Pods-DynamicIslandWidgetExtension.debug.xcconfig
    # Release -> Pods-DynamicIslandWidgetExtension.release.xcconfig
    # Profile -> Pods-DynamicIslandWidgetExtension.profile.xcconfig
    # Debug-tucttxDev -> Pods-DynamicIslandWidgetExtension.debug-tucttxdev.xcconfig
    
    # Convert config name to lowercase for the file suffix
    suffix = config_name.downcase
    xcconfig_filename = "Pods-DynamicIslandWidgetExtension.#{suffix}.xcconfig"
    
    # Path inside the project group structure (usually implicit or under Pods)
    # But we need to find the FileReference in the project.
    
    # Pods usually puts these in a group "Pods" -> "Target Support Files" -> "Pods-DynamicIslandWidgetExtension"
    # But 'pod install' should have already added these file references to the project.
    
    # Let's search for the file reference by name globally
    files = project.files.select { |f| f.path && f.path.include?(xcconfig_filename) }
    
    if files.empty?
        puts "⚠️ Arquivo xcconfig não encontrado no projeto para #{config_name}: #{xcconfig_filename}"
        # Tenta achar sem caminho completo, apenas pelo nome
        files = project.files.select { |f| f.name == xcconfig_filename || (f.path && File.basename(f.path) == xcconfig_filename) }
    end

    if files.any?
      file_ref = files.first
      config.base_configuration_reference = file_ref
      puts "✅ #{config_name} -> #{file_ref.path}"
    else
      puts "❌ ERRO: Xcconfig não encontrado para #{config_name} (#{xcconfig_filename})"
    end
  end
  
  project.save
  puts "Projeto salvo com sucesso!"
else
  puts "Target DynamicIslandWidgetExtension não encontrado."
end
