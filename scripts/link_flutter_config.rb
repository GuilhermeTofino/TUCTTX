require 'xcodeproj'
require 'fileutils'

# Function to patch an xcconfig file
def patch_xcconfig(file_path)
  content = File.read(file_path)
  
  # Path to Generated.xcconfig relative to the Pods xcconfig
  # Pods xcconfigs are usually in `ios/Pods/Target Support Files/Pods-DynamicIslandWidgetExtension/`
  # Generated.xcconfig is in `ios/Flutter/Generated.xcconfig`
  # Rel path: `../../../Flutter/Generated.xcconfig`
  
  include_line = '#include "../../../Flutter/Generated.xcconfig"'
  
  unless content.include?(include_line)
    puts "Patching #{File.basename(file_path)}..."
    # Configs often set FLUTTER_ROOT etc, so we want Generated to potentially override or be available
    # Actually, Generated.xcconfig sets FLUTTER_BUILD_NAME/NUMBER.
    # We should add it at the end or beginning.
    # Let's add it at the top, but after other includes if any?
    # Actually, appending is safer to override or provide values if not set.
    
    File.open(file_path, 'a') do |f|
      f.puts ""
      f.puts include_line
    end
    print "✅ Patched\n"
  else
    puts "ℹ️ #{File.basename(file_path)} already patched."
  end
end

puts "Searching for Pods xcconfigs for DynamicIslandWidgetExtension..."

Dir.glob('ios/Pods/Target Support Files/Pods-DynamicIslandWidgetExtension/*.xcconfig').each do |file|
  patch_xcconfig(file)
end

puts "Done patching xcconfigs."
