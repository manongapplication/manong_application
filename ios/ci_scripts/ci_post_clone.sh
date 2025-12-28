#!/bin/bash
# Install Flutter and CocoaPods dependencies

# Navigate to the ios directory
cd ios

# Run flutter pub get to fetch dependencies and generate the xcconfig file
flutter pub get

# Install CocoaPods
pod install
