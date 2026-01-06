#!/bin/sh

# Stop execution if any command fails. Crucial for debugging.
set -e

echo "=== Starting Xcode Cloud Post-Clone Script ==="

# Print current directory for debugging
echo "Current directory: $(pwd)"

# Navigate to the project root directory from the ios/ci_scripts folder.
cd ../../
echo "After cd, directory: $(pwd)"

# Verify we can find the Flutter executable and get its path.
FLUTTER_PATH=$(command -v flutter || echo "flutter not found")
echo "Flutter Path: $FLUTTER_PATH"

# Check if flutter exists
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter command not found!"
    exit 1
fi

# Get Flutter version for debugging
echo "Flutter version:"
flutter --version

# Get Flutter dependencies (pubspec.yaml).
echo "Fetching Flutter dependencies..."
flutter pub get

# Navigate into the ios directory where the Podfile is.
cd ios
echo "In ios directory: $(pwd)"

# Check if Podfile exists
if [ ! -f "Podfile" ]; then
    echo "ERROR: Podfile not found in ios directory!"
    ls -la
    exit 1
fi

# Install CocoaPods dependencies.
echo "Installing CocoaPods dependencies..."
pod install

echo "=== Xcode Cloud Post-Clone Script Complete ==="