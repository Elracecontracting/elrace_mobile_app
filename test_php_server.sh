#!/bin/bash

# Test PHP file locally
# This script helps you test the qrcodeapp.php file before uploading to server

echo "🚀 Starting local PHP server for testing..."
echo "📁 Serving qrcodeapp.php on port 8000"
echo ""

# Check if PHP is installed
if ! command -v php &> /dev/null; then
    echo "❌ PHP is not installed. Please install PHP first."
    echo "   On macOS: brew install php"
    exit 1
fi

# Start PHP built-in server
echo "✅ PHP found: $(php --version | head -n 1)"
echo ""
echo "🌐 Local URLs for testing:"
echo "   • http://localhost:8000/qrcodeapp.php"
echo "   • http://127.0.0.1:8000/qrcodeapp.php"
echo ""
echo "📱 Test Instructions:"
echo "   1. Open the URL above in your browser"
echo "   2. For mobile testing, find your local IP:"
echo "      ifconfig | grep 'inet ' | grep -v 127.0.0.1"
echo "   3. Access from mobile: http://YOUR_IP:8000/qrcodeapp.php"
echo ""
echo "🛑 Press Ctrl+C to stop the server"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Start server
php -S localhost:8000

