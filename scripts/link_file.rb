require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Encontrar os targets
runner_target = project.targets.find { |t| t.name == 'Runner' }
extension_target = project.targets.find { |t| t.name == 'DynamicIslandWidgetExtension' }

if runner_target && extension_target
  # Encontrar ou criar referência para o arquivo
  group = project.main_group.find_subpath(File.join('Runner'), true)
  file_ref = group.find_file_by_path('AppAttributes.swift')
  
  if file_ref
    puts "Arquivo já existe no projeto: #{file_ref.path}"
  else
    file_ref = group.new_reference('AppAttributes.swift')
    puts "Criada referência para: #{file_ref.path}"
  end
  
  # Adicionar ao Runner Target
  unless runner_target.source_build_phase.files_references.include?(file_ref)
    runner_target.add_file_references([file_ref])
    puts "Adicionado ao target Runner"
  else
    puts "Já está no target Runner"
  end

  # Adicionar ao Extension Target
  unless extension_target.source_build_phase.files_references.include?(file_ref)
    extension_target.add_file_references([file_ref])
    puts "Adicionado ao target Extension"
  else
    puts "Já está no target Extension"
  end

  project.save
  puts "Projeto salvo com sucesso!"
else
  puts "ERRO: Targets não encontrados"
end
