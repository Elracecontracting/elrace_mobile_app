#!/bin/bash

echo "🧪 Testing Deep Link - El Race App"
echo ""
echo "Choose test method:"
echo "1) Force open app (bypass verification)"
echo "2) Test with intent scheme"
echo "3) Check if assetlinks.json exists on server"
echo ""
read -p "Enter choice (1-3): " choice

case $choice in
  1)
    echo "🚀 Opening app directly..."
    adb shell am start -W -a android.intent.action.VIEW \
      -c android.intent.category.BROWSABLE \
      -d "https://elrace.com/RCC4/Requirements/qrcodeapp" \
      com.el_race.app/.MainActivity
    ;;
  2)
    echo "🚀 Using intent scheme..."
    adb shell am start -W -a android.intent.action.VIEW \
      -d "intent://elrace.com/RCC4/Requirements/qrcodeapp#Intent;scheme=https;package=com.el_race.app;end"
    ;;
  3)
    echo "🔍 Checking server files..."
    echo ""
    echo "📄 assetlinks.json:"
    curl -I https://elrace.com/.well-known/assetlinks.json
    echo ""
    echo "�� qrcodeapp.php:"
    curl -I https://elrace.com/RCC4/Requirements/qrcodeapp.php
    ;;
  *)
    echo "❌ Invalid choice"
    ;;
esac
