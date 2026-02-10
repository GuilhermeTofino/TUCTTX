require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Encontrar os targets
runner_target = project.targets.find { |t| t.name == 'Runner' }
extension_target = project.targets.find { |t| t.name == 'DynamicIslandWidgetExtension' }

file_name = 'AppAttributes.swift'
group = project.main_group.find_subpath(File.join('Runner'), true)
file_ref = group.find_file_by_path(file_name)

if file_ref
  # Remover do Runner Target
  if runner_target
    build_file = runner_target.source_build_phase.files.find { |f| f.file_ref == file_ref }
    if build_file
      build_file.remove_from_project
      puts "Removido do target Runner"
    end
  end

  # Remover do Extension Target
  if extension_target
    build_file = extension_target.source_build_phase.files.find { |f| f.file_ref == file_ref }
    if build_file
      build_file.remove_from_project
      puts "Removido do target Extension"
    end
  end

  # Remover referência do arquivo
  file_ref.remove_from_project
  puts "Referência do arquivo removida"
  
  project.save
  puts "Projeto salvo com sucesso!"
else
  puts "Arquivo não encontrado no projeto"
end
