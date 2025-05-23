# Current Pressing Issues and Action Items

This document tracks current issues, blockers, and action items for the Waste Segregation App (WasteWise). This is a living document meant to be updated as issues are resolved and new ones emerge.

_Last updated: [Current Date]_

## Pending Approvals

1. **Play Store Review** 
   - **Status**: Waiting for approval of initial submission
   - **Actions**:
     - [ ] Monitor Google Play Console for reviewer feedback
     - [ ] Be ready to respond to rejection reasons if any
   - **Priority**: HIGH
   - **Owner**: Pranay

## Technical Issues

1. **Cross-Platform Data Sync**
   - **Issue**: Data from iOS and Android is not synchronized
   - **Root Cause**: Currently using local-only storage with Hive, not Firestore
   - **Actions**:
     - [ ] Implement Firestore backend for user data
     - [ ] Update StorageService to write/read from both local and cloud
     - [ ] Add data migration for existing users
   - **Priority**: MEDIUM
   - **Dependencies**: Play Store approval

2. **Web Deployment**
   - **Issue**: Web version shows blank screen despite successful build
   - **Actions**: 
     - [ ] Test with simple HTTP server (not flutter run)
     - [ ] Verify Firebase web config matches project ID
     - [ ] Check browser console logs for errors
   - **Priority**: LOW
   - **Dependencies**: Mobile versions stable

## Feature Enhancement

1. **AI Model Improvements**
   - **Issue**: AI classification could be more accurate for certain waste types
   - **Actions**:
     - [ ] Gather user feedback on misclassifications
     - [ ] Consider specialized models for problematic categories
     - [ ] Implement confidence threshold with "Not sure" result
   - **Priority**: LOW
   - **Dependencies**: Initial release and user feedback

2. **User Data Migration**
   - **Issue**: Need to migrate existing local user data to Firestore
   - **Actions**:
     - [ ] Design data migration workflow
     - [ ] Test with various data sets
     - [ ] Implement graceful fallback for failed migrations
   - **Priority**: LOW
   - **Dependencies**: Firestore implementation

## Release Planning

1. **iOS App Store**
   - **Status**: Not started
   - **Actions**:
     - [ ] Complete App Store Connect setup
     - [ ] Prepare screenshots and metadata
     - [ ] Build and submit for TestFlight review
   - **Priority**: MEDIUM
   - **Dependencies**: Play Store feedback

2. **Analytics Implementation**
   - **Status**: Basic Firebase Analytics only
   - **Actions**:
     - [ ] Define key user actions to track
     - [ ] Implement custom event tracking
     - [ ] Set up conversion funnels
   - **Priority**: LOW
   - **Dependencies**: Play Store approval

## Documentation

1. **User Guide**
   - **Status**: Basic documentation complete
   - **Actions**:
     - [ ] Add screenshots from production app
     - [ ] Create video tutorials for key features
     - [ ] Translate to additional languages
   - **Priority**: LOW
   - **Dependencies**: Final UI/UX

## Meeting Notes

_Add summary of discussions and decisions from meetings here._

---

## Resolved Issues

_Move completed items here with resolution date and notes._

1. **Play Store Package Name** - _Resolved: [Date]_
   - Changed from `com.example.waste_segregation_app` to `com.pranaysuyash.wastewise`
   - Updated Firebase configurations
   - Updated MainActivity location and package reference

2. **Release Signing** - _Resolved: [Date]_
   - Created keystore with alias 'wastewise'
   - Configured key.properties and build.gradle
   - Successfully built signed app bundle 

## [Resolved] Play Store Package/Class Name & Versioning Issue (May 2025)
- **Problem:** App crashed on real device due to mismatch between Play Store package name (`com.pranaysuyash.wastewise`) and MainActivity class path (`com.example.waste_segregation_app.MainActivity`).
- **Also:** Versioning started at 0.9.x for internal testing, but was reset to 0.1.x for public clarity.
- **Solution:**
  - Refactored all package references to `com.pranaysuyash.wastewise` in build.gradle, AndroidManifest.xml, google-services.json, and MainActivity.
  - Set versionCode to 92 (higher than previous 91) and versionName to 0.1.0 for Play Console compatibility.
  - Updated documentation and changelog.
- **Status:** Resolved as of 2025-05-19. 