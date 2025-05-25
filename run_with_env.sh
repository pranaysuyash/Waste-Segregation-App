#!/bin/bash

# Waste Segregation App - Run with Environment Variables
# This script loads environment variables from .env file and runs the Flutter app

echo "🚀 Starting Waste Segregation App with environment variables..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create a .env file with your API keys:"
    echo ""
    echo "OPENAI_API_KEY=your_openai_api_key_here"
    echo "GEMINI_API_KEY=your_gemini_api_key_here"
    echo "OPENAI_API_MODEL_PRIMARY=gpt-4.1-nano"
    echo "OPENAI_API_MODEL_SECONDARY=gpt-4o-mini"
    echo "OPENAI_API_MODEL_TERTIARY=gpt-4.1-mini"
    echo "GEMINI_API_MODEL=gemini-2.0-flash"
    echo ""
    exit 1
fi

# Load environment variables from .env file
source .env

# Validate required environment variables
if [ -z "$OPENAI_API_KEY" ] || [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ Error: Missing required API keys in .env file!"
    echo "Please ensure OPENAI_API_KEY and GEMINI_API_KEY are set."
    exit 1
fi

echo "✅ Environment variables loaded successfully"
echo "📱 Running Flutter app..."

# Run Flutter app with environment variables from .env file
flutter run --dart-define-from-file=.env 