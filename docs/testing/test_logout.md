# Testing Logout Functionality

## Changes Made

1. **Added imports** in `settings_screen.dart`:
   - `import '../services/google_drive_service.dart';`
   - `import 'auth_screen.dart';`

2. **Added GoogleDriveService provider** to the build method:
   - `final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);`

3. **Added Sign Out / Switch Account ListTile** in the settings screen before the "Clear Data" section:
   - Shows "Sign Out" for authenticated users
   - Shows "Switch to Google Account" for guest users
   - Uses appropriate icons and colors

4. **Added `_handleAccountAction` method** that:
   - Handles sign out confirmation for authenticated users
   - Shows loading dialog during sign out process
   - Navigates back to AuthScreen after successful sign out
   - Handles errors gracefully
   - For guest users, shows option to switch to Google account

## How to Use

### For Guest Users:
1. Go to Settings screen
2. Look for "Switch to Google Account" option
3. Tap it to return to the login screen where you can sign in with Google

### For Signed-In Users:
1. Go to Settings screen
2. Look for "Sign Out" option (with red logout icon)
3. Tap it to see confirmation dialog
4. Confirm to sign out and return to login screen

## Features

- ✅ **Dynamic display** - Shows different options based on authentication status
- ✅ **Confirmation dialogs** - Prevents accidental sign out
- ✅ **Loading indicators** - Shows progress during sign out process
- ✅ **Error handling** - Gracefully handles sign out errors
- ✅ **Proper navigation** - Uses `pushAndRemoveUntil` to clear navigation stack
- ✅ **Guest mode support** - Allows switching from guest to authenticated mode

## Code Quality

- Uses FutureBuilder to check authentication status
- Proper error handling with try-catch blocks
- Loading states for better UX
- Consistent styling with app theme
- Clear and descriptive text for user actions
