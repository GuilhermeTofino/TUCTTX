#!/bin/sh

# Fail this script if any instruction fails
set -e

# The default execution directory of this script is the ci_scripts directory.
# Traverse up the directory tree to find the root of the project.
cd "$(dirname "$0")/../../"

echo "📦 Installed Flutter..."

# Install Flutter using git
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "✅ Flutter installed"

# Install artifacts
echo "📦 Precaching iOS artifacts..."
flutter precache --ios

# Install dependencies
echo "📦 Installing depedencies..."
flutter pub get

# Install CocoaPods
echo "📦 Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew update to save time
brew install cocoapods

# Install Pods
echo "📦 Running pod install..."
cd ios
pod install

echo "🎉 Setup complete!"
