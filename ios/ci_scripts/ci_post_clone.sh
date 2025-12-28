#!/bin/sh

# Stop execution if any command fails. Crucial for debugging.
set -e

echo "=== Starting Xcode Cloud Post-Clone Script ==="

# Navigate to the project root directory from the ios/ci_scripts folder.
cd ../../

# Verify we can find the Flutter executable and get its path.
FLUTTER_PATH=$(command -v flutter)
echo "Flutter Path: $FLUTTER_PATH"

# Get Flutter dependencies (pubspec.yaml).
echo "Fetching Flutter dependencies..."
flutter pub get

# Navigate into the ios directory where the Podfile is.
cd ios

# Install CocoaPods dependencies.
echo "Installing CocoaPods dependencies..."
pod install

echo "=== Xcode Cloud Post-Clone Script Complete ==="