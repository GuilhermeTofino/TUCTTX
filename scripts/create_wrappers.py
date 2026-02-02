import os
import re

configs = ['tucttxDev', 'tucttxProd', 'tu7eDev', 'tu7eProd', 'tusvaDev', 'tusvaProd']
base_dir = 'ios/Flutter'

# 1. Create the files
for c in configs:
    for mode in ['Debug', 'Release']:
        fname = f'{c}{mode}.xcconfig'
        pods_mode = mode.lower()
        pods_flavor = c.lower()
        
        # Note: the Pods path is relative to ios/Flutter/
        content = f'#include? \"../Pods/Target Support Files/Pods-Runner/Pods-Runner.{pods_mode}-{pods_flavor}.xcconfig\"\n'
        content += f'#include \"{mode}.xcconfig\"\n'
        
        with open(os.path.join(base_dir, fname), 'w') as f:
            f.write(content)
        print(f"Created {fname}")

# 2. Update pbxproj references
project_path = 'ios/Runner.xcodeproj/project.pbxproj'
with open(project_path, 'r') as f: pbx_content = f.read()

# Add new file references to pbxproj
# We need unique IDs. I'll use WRA...
for c in configs:
    for mode in ['Debug', 'Release']:
        fname = f'{c}{mode}.xcconfig'
        # Check if already present in pbx_content
        if fname in pbx_content: continue
        
        # Find a good place to insert (PBXFileReference section)
        # I'll just use a simple append and trust the user to cleanup if needed, 
        # but better to use a proper script.
        pass

# Actually, I'll just reuse the IDs of the previous custom xcconfigs if possible, 
# or use my script to update the configuration references.
