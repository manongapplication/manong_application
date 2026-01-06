#!/bin/sh

# Stop execution if any command fails. Crucial for debugging.
set -e

echo "=== Starting Xcode Cloud Post-Clone Script ==="

# Print current directory for debugging
echo "Current directory: $(pwd)"

# Define Flutter installation directory
FLUTTER_DIR="/Volumes/workspace/flutter"

# Check if Flutter is already installed
if [ ! -d "$FLUTTER_DIR" ] || [ ! -f "$FLUTTER_DIR/bin/flutter" ]; then
    echo "Installing Flutter..."
    
    # Clone Flutter repository
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_DIR"
    
    # Add Flutter to PATH
    export PATH="$FLUTTER_DIR/bin:$PATH"
    
    # Accept licenses
    flutter doctor --android-licenses --verbose
    
    # Pre-download development binaries
    flutter precache
    
    echo "Flutter installation complete"
else
    echo "Flutter already installed at: $FLUTTER_DIR"
    export PATH="$FLUTTER_DIR/bin:$PATH"
fi

# Verify Flutter installation
echo "Flutter Path: $(command -v flutter)"
echo "Flutter version:"
flutter --version

# Run flutter doctor for diagnostics
echo "Running flutter doctor..."
flutter doctor

# Navigate to project root
cd /Volumes/workspace/repository
echo "Project directory: $(pwd)"

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