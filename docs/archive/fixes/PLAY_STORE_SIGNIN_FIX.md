# 🔥 URGENT: Fix Play Store Google Sign-In Error

## ✅ Quick Fix Checklist

### Step 1: Get Play App Signing SHA-1
- [ ] Go to [Google Play Console](https://play.google.com/console)
- [ ] Select "ReLoop" app
- [ ] Navigate to **Release** → **Setup** → **App signing**
- [ ] Copy the **SHA-1 certificate fingerprint** under "App signing key certificate"
- [ ] It looks like: `AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD`

### Step 2: Add SHA-1 to Firebase
- [ ] Go to [Firebase Console](https://console.firebase.google.com)
- [ ] Select project "waste-segregation-app-df523"
- [ ] Click **Project Settings** (gear icon)
- [ ] Select Android app `com.pranaysuyash.wastewise`
- [ ] Scroll to **"SHA certificate fingerprints"**
- [ ] Click **"Add fingerprint"**
- [ ] Paste the Play App Signing SHA-1
- [ ] Click **"Save"**

### Step 3: Update Configuration
- [ ] In Firebase Console, click **"Download google-services.json"**
- [ ] Replace file: `android/app/google-services.json`
- [ ] Run the fix script: `chmod +x fix_play_store_signin.sh && ./fix_play_store_signin.sh`

### Step 4: Upload New Build
- [ ] Build will be created in `build/app/outputs/bundle/release/app-release.aab`
- [ ] Upload to Play Console for internal testing
- [ ] Test Google Sign-In functionality

---

## 🚨 Why This Happens

When you upload to Play Store:
1. **Local testing**: Uses your debug/upload certificate ✅
2. **Play Store**: Google re-signs with Play App Signing certificate ❌
3. **Firebase**: Only knows about your certificates, not Play Store's
4. **Result**: Google Sign-In fails with error code 10

## 🎯 Expected Result

After fixing:
- ✅ Google Sign-In works in Play Store internal testing
- ✅ No more `PlatformException` errors
- ✅ Users can sign in and sync data

---

**⏰ Time to fix: ~10 minutes**
**🔧 Difficulty: Easy**
**📱 Affects: All Play Store deployments**
