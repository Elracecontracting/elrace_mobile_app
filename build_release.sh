#!/bin/bash

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔧 Building release APK..."
flutter build apk --release

echo "✅ Build completed!"
echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"

# Optional: Install on connected device
if [ "$1" = "--install" ]; then
    echo "📱 Installing on connected device..."
    flutter install --release
fi 