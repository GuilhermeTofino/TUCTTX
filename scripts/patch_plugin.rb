#!/usr/bin/env ruby

require 'fileutils'

# Path to the plugin source file
plugin_path = "ios/.symlinks/plugins/live_activities/ios/live_activities/Sources/live_activities/LiveActivitiesPlugin.swift"

unless File.exist?(plugin_path)
  puts "Plugin source file not found at: #{plugin_path}"
  exit 1
end

content = File.read(plugin_path)
original_content = content.dup

# Make struct public
content.gsub!(/^\s*struct LiveActivitiesAppAttributes/, "    public struct LiveActivitiesAppAttributes")

# Make ContentState public
content.gsub!(/^\s*public struct ContentState/, "        public struct ContentState") # It might already be public? No, wait.
# In my manual edit I made it public.
# The original code was: `public struct ContentState: Codable, Hashable`?
# Let's check my manual edit.
# Original: `public struct ContentState` (Line 482). It was public!
# Wait, line 482 in previous `view_file` showed `public struct ContentState`.
# So only `LiveActivitiesAppAttributes` struct itself was internal (Line 479 `struct ...`).
# And `appGroupId` inside ContentState was `var appGroupId`.

# Let's refine the regex.

# 1. Make struct public
content.gsub!(/^\s*struct LiveActivitiesAppAttributes/, "    public struct LiveActivitiesAppAttributes")

# 2. Make appGroupId public
content.gsub!(/^\s*var appGroupId: String/, "            public var appGroupId: String")

# 3. Add public init to ContentState if missing
unless content.include?("public init(appGroupId: String)")
  content.gsub!(/var appGroupId: String\s*}/, "var appGroupId: String\n            \n            public init(appGroupId: String) {\n                self.appGroupId = appGroupId\n            }\n        }")
end

# 4. Make id public
content.gsub!(/^\s*var id = UUID\(\)/, "        public var id = UUID()")

# 5. Add public init to Struct if missing
unless content.include?("public init(id: UUID = UUID())")
    content.gsub!(/var id = UUID\(\)\s*}/, "var id = UUID()\n        \n        public init(id: UUID = UUID()) {\n            self.id = id\n        }\n    }")
end

if content != original_content
  File.write(plugin_path, content)
  puts "✅ Patched LiveActivitiesPlugin.swift to make attributes public."
else
  puts "ℹ️ LiveActivitiesPlugin.swift already patched."
end
