#!/bin/sh

# Fail this script if any instruction fails
set -e

# The default execution directory of this script is the ci_scripts directory.
# Traverse up the directory tree to find the root of the project.
cd "$(dirname "$0")/../../"

echo "🔍 Debug: Environment Variables"
echo "TENANT: ${TENANT:-<not set>}"
echo "ENV: ${ENV:-<not set>}"
echo "GEMINI_API_KEY: ${GEMINI_API_KEY:+<set>}${GEMINI_API_KEY:-<not set>}"
echo ""

# Create .env file from environment variable
echo "📦 Generating .env file..."
if [ -z "$GEMINI_API_KEY" ]; then
  echo "⚠️  WARNING: GEMINI_API_KEY is not set in the environment!"
else
  echo "GEMINI_API_KEY=$GEMINI_API_KEY" > .env
  echo "✅ .env file created"
fi

# Inject Tenant Config into Generated.xcconfig
echo "📦 Injecting Tenant Config..."
if [ -z "$TENANT" ]; then
  echo "❌ ERROR: TENANT environment variable is missing!"
  echo "Please configure TENANT in Xcode Cloud environment variables."
  exit 1
else
  # Encodings keys and values to Base64 logic akin to how Flutter does internaly for dart-defines
  # However, for simplicity in shell, we will just pass them as raw defines if possible, 
  # OR we append to DART_DEFINES if we want to mimic flutter run.
  # But since we are likely not running "flutter build ios" directly (Xcode does the build via the script phase),
  # we need to ensure these values are available to the App.
  
  # The app reads: const String.fromEnvironment('TENANT')
  # This comes from DART_DEFINES in Generated.xcconfig.
  
  # Helper to encoded
  encode_define() {
    echo -n "$1" | base64
  }
  
  TENANT_DEF="TENANT=$TENANT"
  ENV_DEF="ENV=${ENV:-prod}" # default to prod if ENV not set
  
  TENANT_B64=$(encode_define "$TENANT_DEF")
  ENV_B64=$(encode_define "$ENV_DEF")
  
  # Note: Generated.xcconfig might explicitly overwrite DART_DEFINES. 
  # We should append to it.
  
  XCCONFIG_PATH="ios/Flutter/Generated.xcconfig"
  
  # Append comma + new defines to the end of the existing DART_DEFINES line
  # This is a bit hacky but works for Xcode Cloud's post-processing of this file
  
  if grep -q "DART_DEFINES" "$XCCONFIG_PATH"; then
      # Append to existing line (using sed to replace end of line)
      # We assume the line doesn't end with a comma, so we add one.
      sed -i '' "s/^DART_DEFINES.*/\&,$TENANT_B64,$ENV_B64/" "$XCCONFIG_PATH"
      echo "✅ Appended TENANT ($TENANT) and ENV ($ENV_DEF) to DART_DEFINES"
  else
     # Create line if not exists
     echo "DART_DEFINES=$TENANT_B64,$ENV_B64" >> "$XCCONFIG_PATH"
     echo "✅ Created DART_DEFINES with TENANT ($TENANT) and ENV ($ENV_DEF)"
  fi
fi

# Install Flutter using git
echo "📦 Installing Flutter..."
if [ -d "$HOME/flutter" ]; then
  echo "ℹ️  Flutter directory already exists, skipping clone..."
  export PATH="$PATH:$HOME/flutter/bin"
else
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
  export PATH="$PATH:$HOME/flutter/bin"
  echo "✅ Flutter cloned successfully"
fi

# Verify Flutter installation
flutter --version
echo "✅ Flutter is ready"

# Install artifacts
echo "📦 Precaching iOS artifacts..."
flutter precache --ios

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Install CocoaPods
echo "📦 Installing CocoaPods..."
export HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew update to save time

if command -v pod >/dev/null 2>&1; then
  echo "ℹ️  CocoaPods already installed: $(pod --version)"
else
  brew install cocoapods
  echo "✅ CocoaPods installed"
fi

# Install Pods
echo "📦 Running pod install..."
pod install --project-directory=ios

echo "🎉 Setup complete!"
