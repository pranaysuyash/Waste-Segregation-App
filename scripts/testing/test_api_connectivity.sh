#!/bin/bash

# API Connectivity Test Script for Waste Segregation App
# This script tests OpenAI and Gemini API connectivity and validates API keys

set -e

echo "🔑 API Connectivity Test Script"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f ".env" ]; then
    echo -e "${BLUE}📄 Loading environment variables from .env file...${NC}"
    source .env
else
    echo -e "${RED}❌ .env file not found!${NC}"
    echo "Please create a .env file with your API keys:"
    echo "OPENAI_API_KEY=your_openai_api_key_here"
    echo "GEMINI_API_KEY=your_gemini_api_key_here"
    exit 1
fi

# Function to test OpenAI API
test_openai_api() {
    echo -e "${BLUE}🤖 Testing OpenAI API...${NC}"
    
    if [ -z "$OPENAI_API_KEY" ]; then
        echo -e "${RED}❌ OPENAI_API_KEY not set in .env file${NC}"
        return 1
    fi
    
    # Check if API key format is correct
    if [[ ! "$OPENAI_API_KEY" =~ ^sk-[a-zA-Z0-9-_]{20,}$ ]]; then
        echo -e "${YELLOW}⚠️  OpenAI API key format appears incorrect${NC}"
        echo "Expected format: sk-proj-... or sk-..."
        echo "Current key: ${OPENAI_API_KEY:0:20}..."
    fi
    
    # Test API connectivity with a simple request
    echo "Testing API connectivity..."
    
    response=$(curl -s -w "%{http_code}" -o /tmp/openai_response.json \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "Hello"}],
            "max_tokens": 5
        }' \
        https://api.openai.com/v1/chat/completions)
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ OpenAI API is working correctly!${NC}"
        echo "Response preview:"
        cat /tmp/openai_response.json | head -3
        return 0
    elif [ "$http_code" = "401" ]; then
        echo -e "${RED}❌ OpenAI API authentication failed (401)${NC}"
        echo "This usually means:"
        echo "1. API key is invalid or expired"
        echo "2. API key format is incorrect"
        echo "3. Account has insufficient credits"
        cat /tmp/openai_response.json
        return 1
    elif [ "$http_code" = "429" ]; then
        echo -e "${YELLOW}⚠️  OpenAI API rate limit exceeded (429)${NC}"
        echo "Please wait and try again later"
        return 1
    else
        echo -e "${RED}❌ OpenAI API request failed with HTTP code: $http_code${NC}"
        cat /tmp/openai_response.json
        return 1
    fi
}

# Function to test Gemini API
test_gemini_api() {
    echo -e "${BLUE}🔮 Testing Gemini API...${NC}"
    
    if [ -z "$GEMINI_API_KEY" ]; then
        echo -e "${RED}❌ GEMINI_API_KEY not set in .env file${NC}"
        return 1
    fi
    
    # Check if API key format is correct
    if [[ ! "$GEMINI_API_KEY" =~ ^AIza[a-zA-Z0-9_-]{35}$ ]]; then
        echo -e "${YELLOW}⚠️  Gemini API key format appears incorrect${NC}"
        echo "Expected format: AIza..."
        echo "Current key: ${GEMINI_API_KEY:0:20}..."
    fi
    
    # Test API connectivity
    echo "Testing API connectivity..."
    
    response=$(curl -s -w "%{http_code}" -o /tmp/gemini_response.json \
        -H "Content-Type: application/json" \
        -d '{
            "contents": [{
                "parts": [{"text": "Hello"}]
            }]
        }' \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$GEMINI_API_KEY")
    
    http_code="${response: -3}"
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ Gemini API is working correctly!${NC}"
        echo "Response preview:"
        cat /tmp/gemini_response.json | head -3
        return 0
    elif [ "$http_code" = "400" ]; then
        echo -e "${RED}❌ Gemini API request failed (400)${NC}"
        echo "This usually means:"
        echo "1. API key is invalid"
        echo "2. Request format is incorrect"
        echo "3. API key doesn't have required permissions"
        cat /tmp/gemini_response.json
        return 1
    elif [ "$http_code" = "403" ]; then
        echo -e "${RED}❌ Gemini API access forbidden (403)${NC}"
        echo "This usually means:"
        echo "1. API key is invalid or expired"
        echo "2. API is not enabled for your project"
        echo "3. Billing is not set up"
        return 1
    else
        echo -e "${RED}❌ Gemini API request failed with HTTP code: $http_code${NC}"
        cat /tmp/gemini_response.json
        return 1
    fi
}

# Function to validate environment configuration
validate_env_config() {
    echo -e "${BLUE}🔧 Validating environment configuration...${NC}"
    
    # Check model configurations
    models=(
        "OPENAI_API_MODEL_PRIMARY:$OPENAI_API_MODEL_PRIMARY"
        "OPENAI_API_MODEL_SECONDARY:$OPENAI_API_MODEL_SECONDARY" 
        "OPENAI_API_MODEL_TERTIARY:$OPENAI_API_MODEL_TERTIARY"
        "GEMINI_API_MODEL:$GEMINI_API_MODEL"
    )
    
    for model_config in "${models[@]}"; do
        IFS=':' read -r model_name model_value <<< "$model_config"
        if [ -z "$model_value" ]; then
            echo -e "${YELLOW}⚠️  $model_name not set${NC}"
        else
            echo -e "${GREEN}✅ $model_name: $model_value${NC}"
        fi
    done
}

# Function to provide troubleshooting tips
provide_troubleshooting_tips() {
    echo -e "${BLUE}🛠️  Troubleshooting Tips${NC}"
    echo "================================"
    echo ""
    echo "If OpenAI API fails:"
    echo "1. Check your API key at: https://platform.openai.com/api-keys"
    echo "2. Ensure you have sufficient credits"
    echo "3. Verify the key format: sk-proj-... or sk-..."
    echo "4. Make sure the key has the required permissions"
    echo ""
    echo "If Gemini API fails:"
    echo "1. Check your API key at: https://makersuite.google.com/app/apikey"
    echo "2. Ensure the Generative Language API is enabled"
    echo "3. Verify billing is set up in Google Cloud Console"
    echo "4. Check the key format: AIza..."
    echo ""
    echo "Common fixes:"
    echo "1. Regenerate API keys if they're old"
    echo "2. Check for extra spaces or newlines in .env file"
    echo "3. Ensure .env file is in the project root"
    echo "4. Restart the Flutter app after changing .env"
}

# Main execution
main() {
    echo "Starting API connectivity tests..."
    echo ""
    
    # Validate environment configuration
    validate_env_config
    echo ""
    
    # Test APIs
    openai_success=false
    gemini_success=false
    
    if test_openai_api; then
        openai_success=true
    fi
    echo ""
    
    if test_gemini_api; then
        gemini_success=true
    fi
    echo ""
    
    # Summary
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "==============="
    
    if [ "$openai_success" = true ]; then
        echo -e "${GREEN}✅ OpenAI API: Working${NC}"
    else
        echo -e "${RED}❌ OpenAI API: Failed${NC}"
    fi
    
    if [ "$gemini_success" = true ]; then
        echo -e "${GREEN}✅ Gemini API: Working${NC}"
    else
        echo -e "${RED}❌ Gemini API: Failed${NC}"
    fi
    
    if [ "$openai_success" = true ] && [ "$gemini_success" = true ]; then
        echo -e "${GREEN}🎉 All APIs are working correctly!${NC}"
        echo "You can now run your Flutter app with working AI classification."
    else
        echo -e "${YELLOW}⚠️  Some APIs are not working. See troubleshooting tips below.${NC}"
        echo ""
        provide_troubleshooting_tips
    fi
    
    # Cleanup
    rm -f /tmp/openai_response.json /tmp/gemini_response.json
}

# Run the main function
main 