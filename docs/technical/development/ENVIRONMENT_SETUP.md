# Environment Setup for Development

## ⚠️ CRITICAL: Environment Variables Required

**The Waste Segregation App MUST be run with environment variables loaded from the `.env` file during development until production deployment.**

### Why This Matters

The app uses AI services (OpenAI and Gemini) that require valid API keys. Without proper environment configuration:
- ❌ AI analysis will fail
- ❌ All classifications will return "unknown item" 
- ❌ Images may not display properly in history
- ❌ App functionality will be severely limited

### Required Setup

1. **Ensure `.env` file exists** in the project root with valid API keys:
   ```bash
   # API Keys for Waste Segregation App
   OPENAI_API_KEY=sk-proj-your-actual-openai-key-here
   GEMINI_API_KEY=AIzaSy-your-actual-gemini-key-here
   
   # Model Configuration
   OPENAI_API_MODEL_PRIMARY=gpt-4.1-nano
   OPENAI_API_MODEL_SECONDARY=gpt-4o-mini
   OPENAI_API_MODEL_TERTIARY=gpt-4.1-mini
   GEMINI_API_MODEL=gemini-2.0-flash
   ```

2. **ALWAYS run the app using one of these methods:**

   **Option A: Use the provided script (Recommended)**
   ```bash
   ./run_with_env.sh
   ```

   **Option B: Manual flutter run with env file**
   ```bash
   flutter run --dart-define-from-file=.env
   ```

   **Option C: For specific devices**
   ```bash
   flutter run --dart-define-from-file=.env -d <device-id>
   ```

### ❌ DO NOT Use These Commands

```bash
# ❌ WRONG - Will use placeholder API keys
flutter run

# ❌ WRONG - Will use placeholder API keys  
flutter run --debug

# ❌ WRONG - Will use placeholder API keys
flutter run --release
```

### Verification

When the app starts correctly with environment variables, you should see:
```
flutter: Environment variables loaded via --dart-define-from-file
```

### Troubleshooting

**Problem: Getting "unknown item" classifications**
- **Cause**: App is running without proper API keys
- **Solution**: Stop the app and restart using `./run_with_env.sh`

**Problem: Images not showing in history**
- **Cause**: May be related to running without environment variables
- **Solution**: Ensure you're using the proper run command with `.env` file

**Problem: API errors in logs**
- **Cause**: Invalid or missing API keys
- **Solution**: Check that your `.env` file has valid API keys

### Production Deployment

This requirement is **only for development**. In production:
- Environment variables will be injected through the deployment pipeline
- CI/CD will handle proper configuration
- No manual `.env` file management required

### Security Note

- **Never commit the `.env` file to version control**
- The `.env` file is already in `.gitignore`
- API keys are sensitive and should be kept secure

---

**Remember: Until production deployment, ALWAYS use `./run_with_env.sh` or `flutter run --dart-define-from-file=.env`** 