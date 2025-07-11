#!/bin/bash

echo "🔍 Running Supabase Connection Test..."
echo ""

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "❌ Dart is not installed. Please install Dart first:"
    echo "https://dart.dev/get-dart"
    exit 1
fi

# Create a temporary directory for the test
echo "📁 Setting up test environment..."
mkdir -p temp_test
cd temp_test

# Copy the test files
cp ../test_supabase_connection.dart .
cp ../test_pubspec.yaml pubspec.yaml

# Get dependencies
echo "📦 Getting dependencies..."
dart pub get

# Run the test
echo ""
echo "🚀 Running connection test..."
echo "=================================="
dart run test_supabase_connection.dart
echo "=================================="

# Clean up
echo ""
echo "🧹 Cleaning up..."
cd ..
rm -rf temp_test

echo ""
echo "✅ Test completed!" 