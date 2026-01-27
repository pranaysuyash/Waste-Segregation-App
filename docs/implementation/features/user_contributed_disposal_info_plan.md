# User-Contributed Disposal Information: Detailed Implementation Plan

**Version:** 1.0
**Date:** Jun 03, 2024
**Status:** PLANNING COMPLETE

## 1. Overview & Goals

This document outlines the detailed implementation plan for the User-Contributed Disposal Information feature. The primary goal is to empower users to improve the accuracy and completeness of local disposal facility information within the Waste Segregation App. This feature will allow users to suggest edits to existing facilities, propose new facilities, and (in later phases) contribute to community verification of data.

**Key Objectives:**
*   Enable users to submit corrections for facility details (hours, contact, accepted materials).
*   Allow users to suggest new disposal facilities not yet in the database.
*   Provide an administrative interface for reviewing and integrating these contributions.
*   Enhance data accuracy and local relevance through community-driven efforts.
*   Increase user engagement by allowing them to actively contribute.

## 2. Core Components & Data Models

### 2.1. Firestore Collections

#### A. `user_contributions` Collection
This collection will store all contributions submitted by users.

*   **Document ID:** Auto-generated (e.g., `contributionId`)
*   **Fields:**
    *   `userId` (String): Firebase Auth UID of the contributor.
    *   `facilityId` (String, Nullable): ID of the existing facility being edited. Null if suggesting a new facility.
    *   `contributionType` (String Enum):
        *   `NEW_FACILITY`: Suggesting an entirely new facility.
        *   `EDIT_HOURS`: Modifying operating hours.
        *   `EDIT_CONTACT`: Updating contact information (phone, email, website).
        *   `EDIT_ACCEPTED_MATERIALS`: Changing the list of accepted waste materials.
        *   `ADD_PHOTO`: Submitting a photo for a facility.
        *   `REPORT_CLOSURE`: Reporting a facility as permanently closed.
        *   `OTHER_CORRECTION`: For miscellaneous corrections with a description.
    *   `suggestedData` (Map<String, dynamic>): Contains the actual data being suggested. Structure varies by `contributionType`.
        *   Example for `EDIT_HOURS`: `{"operatingHours": {"monday": "9am-5pm", "tuesday": "9am-5pm"}, "notesForAdmin": "Updated Monday hours based on call."}`
        *   Example for `NEW_FACILITY`: `{ "name": "New Community Drop-off", "address": "123 Main St", "coordinates": { "latitude": ..., "longitude": ... }, "operatingHours": {...}, ... }`
    *   `userNotes` (String, Nullable): Additional comments or rationale from the user.
    *   `photoUrls` (List<String>, Nullable): URLs to photos uploaded by the user (e.g., of new facility, updated signage), stored in Firebase Storage.
    *   `timestamp` (Timestamp): Server-generated timestamp of submission.
    *   `status` (String Enum):
        *   `PENDING_REVIEW`: Awaiting admin review.
        *   `APPROVED_INTEGRATED`: Approved by admin and data integrated into main facility list.
        *   `REJECTED`: Contribution rejected by admin.
        *   `NEEDS_MORE_INFO`: Admin requires more information from the user (future enhancement for user interaction).
    *   `reviewNotes` (String, Nullable): Comments from the admin during the review process.
    *   `reviewerId` (String, Nullable): Firebase Auth UID of the admin who reviewed the contribution.
    *   `reviewTimestamp` (Timestamp, Nullable): Timestamp of when the review was conducted.
    *   `upvotes` (Integer, Default: 0): For future community verification.
    *   `downvotes` (Integer, Default: 0): For future community verification.

#### B. `disposal_locations` Collection (or existing equivalent)
This is the primary collection holding the curated list of disposal facilities displayed in the app. If a robust version doesn't exist, it will be created/enhanced.

*   **Document ID:** `facilityId` (String, unique)
*   **Key Fields (Illustrative - to be refined based on existing model if any):**
    *   `name` (String)
    *   `address` (String)
    *   `coordinates` (GeoPoint)
    *   `operatingHours` (Map<String, String> or more structured Map)
    *   `contactInfo` (Map<String, String>: `phone`, `email`, `website`)
    *   `acceptedMaterials` (List<String>)
    *   `photos` (List<Map<String, String>>: `url`, `uploadedByUserId`, `caption`, `uploadTimestamp`)
    *   `lastAdminUpdate` (Timestamp): When an admin last directly modified this record.
    *   `lastVerifiedByAdmin` (Timestamp): When an admin last explicitly verified the data (could be same as update or a separate action).
    *   `source` (String Enum): `ADMIN_ENTERED`, `USER_SUGGESTED_INTEGRATED`, `BULK_IMPORTED`.
    *   `isActive` (Boolean, Default: true): To soft-delete or hide closed facilities.

### 2.2. Firebase Storage
*   User-uploaded photos for facilities will be stored in a dedicated path, e.g., `facility_photos/{facilityId}/{userId}/{filename}` or `contribution_photos/{contributionId}/{filename}`.

## 3. User Interface (Flutter App)

### 3.1. Viewing Facility Details (e.g., `FacilityDetailScreen` or enhanced `DisposalLocationCard`)
*   Clear display of current facility information fetched from `disposal_locations`.
*   A prominent "Suggest an Edit / Report Issue" button or icon.
*   Display user-submitted photos (if available and approved).

### 3.2. Contribution Submission Form/Flow
*   Triggered by "Suggest an Edit" or a dedicated "Add New Facility" button.
*   **Initial Choice:** Ask user if they are: "Suggesting an edit to *this* facility?" or "Adding a new facility not listed?"
*   **For Edits:**
    *   Allow selection of what to edit (Hours, Contact, Materials, Report Closure, Other).
    *   Present current data alongside input fields for new data.
    *   Option to add notes and upload photos (e.g., of new signage).
*   **For New Facility:**
    *   Form to capture: Name, Address (with map pin-drop option), Operating Hours, Accepted Materials, Contact Info, Notes, Photo(s).
*   **Common elements:** Clear instructions, input validation, confirmation before submission.

### 3.3. User's Contribution History (Profile Section - Post-MVP)
*   List of user's past contributions.
*   Display `status` (Pending, Approved, Rejected) and potentially `reviewNotes` from admin.

## 4. Backend Logic (Cloud Functions & Firestore)

### 4.1. `submitUserContribution` (Callable Cloud Function)
*   **Trigger:** Called from the Flutter app when a user submits a contribution.
*   **Input:** `contributionType`, `suggestedData`, `userNotes`, `photoUrls` (if any), `facilityId` (if editing).
*   **Logic:**
    1.  Authenticate the user (get `userId` from `context.auth`).
    2.  Validate input data based on `contributionType`.
    3.  For photo uploads, ensure URLs point to successfully uploaded files in Firebase Storage (client handles upload, passes URL).
    4.  Create a new document in the `user_contributions` collection with `status: 'PENDING_REVIEW'`, `userId`, `timestamp`, and other provided data.
    5.  Return success/failure status to the client.
    6.  (Optional) Trigger a notification (e.g., email or Admin Panel alert) to administrators about the new pending contribution.

### 4.2. Firestore Security Rules
*   Authenticated users can create documents in `user_contributions` (their own `userId` must match).
*   Users cannot edit or delete `user_contributions` once submitted.
*   Admins (identified by custom claim or separate admin user list) have R/W access to `user_contributions` and full R/W to `disposal_locations`.
*   All users have read-only access to `disposal_locations`.

## 5. Admin Panel Integration

A new section in the Admin Panel titled "User Contributions Management".

### 5.1. Dashboard/List View
*   List of all documents from the `user_contributions` collection.
*   Filterable by: `status` (default to PENDING_REVIEW), `contributionType`, `userId`, date range.
*   Sortable by `timestamp`.
*   Quick summary: User, Type, Facility (if edit), Date.

### 5.2. Contribution Review Interface
*   When an admin selects a contribution:
    *   Display all details from the `user_contributions` document.
    *   If it's an edit (`facilityId` is present), fetch and display the current data from `disposal_locations` for that facility side-by-side with `suggestedData` for easy comparison.
    *   Display any uploaded photos.
    *   Admin Actions:
        *   **Approve & Integrate:**
            *   Admin verifies the information (may involve external checks).
            *   Admin manually updates/creates the relevant document in `disposal_locations` based on `suggestedData`. (Future: Semi-automated integration for simple edits).
            *   Updates the `user_contributions` document: `status: 'APPROVED_INTEGRATED'`, `reviewerId`, `reviewTimestamp`.
            *   (Optional) Add `reviewNotes` like "Verified via phone call."
        *   **Reject:**
            *   Updates the `user_contributions` document: `status: 'REJECTED'`, `reviewerId`, `reviewTimestamp`.
            *   Requires admin to add `reviewNotes` explaining the rejection (e.g., "Could not verify information," "Duplicate suggestion").
        *   **Mark as Needs More Info (Post-MVP):**
            *   Updates `status: 'NEEDS_MORE_INFO'`, adds `reviewNotes` with questions for the user.
            *   (Requires a mechanism for users to see these notes and resubmit, not in MVP).
    *   Logging of admin actions.

### 5.3. Direct Management of `disposal_locations`
*   Admins retain full CRUD capabilities on the `disposal_locations` collection directly, for initial data population and corrections independent of user contributions.

## 6. Phased Rollout & Implementation Steps

### Phase 1: MVP - Core Contribution & Review
1.  **Backend Setup:**
    *   Define and implement Firestore schemas for `user_contributions` and `disposal_locations` (if not already robust).
    *   Implement Firestore Security Rules.
    *   Develop and deploy `submitUserContribution` Cloud Function.
2.  **App UI (Flutter):**
    *   Develop UI for viewing facility details (if not existing).
    *   Implement "Suggest an Edit" button/flow for existing facilities (focus on `EDIT_HOURS`, `EDIT_CONTACT`, `EDIT_ACCEPTED_MATERIALS`).
    *   Develop the contribution submission form for these edit types.
3.  **Admin Panel:**
    *   Develop the list view for pending contributions.
    *   Develop the review interface for approving/rejecting contributions.
    *   Implement manual data integration by admin into `disposal_locations`.
4.  **Testing:** Thorough end-to-end testing of the flow.

### Phase 2: New Facility Suggestions & Photos
1.  **App UI (Flutter):**
    *   Implement "Add New Facility" flow and submission form.
    *   Integrate photo upload capability (client-side upload to Firebase Storage, then pass URL(s) to Cloud Function) for both new facilities and edits.
2.  **Admin Panel:**
    *   Enhance review interface to handle new facility suggestions and display submitted photos.
3.  **Backend:**
    *   Adjust Cloud Function and `user_contributions` model to handle `NEW_FACILITY` type and `photoUrls`.
4.  (Optional) User notifications on contribution status (Approved/Rejected).

### Future Phases (Post MVP & Phase 2)
*   Community verification (upvotes/downvotes on contributions).
*   User reputation system.
*   Admin tools for managing duplicate suggestions.
*   Mechanism for users to respond to "NEEDS_MORE_INFO" requests.
*   More sophisticated admin dashboard with contribution analytics.

## 7. Technical Considerations & Risks
*   **Data Validation:** Robust server-side validation in the Cloud Function is crucial.
*   **Scalability:** Firestore scales well. Consider data structure for efficient querying in Admin Panel (e.g., indexing on `status`).
*   **Admin Workload:** Initially, all contributions require manual admin review and integration. This could be a bottleneck if contribution volume is high. Plan for admin tools to streamline this.
*   **Data Conflicts/Spam:** Potential for incorrect or malicious contributions. Admin review is the primary mitigation for MVP. Community verification can help later.
*   **User Experience:** Keep submission forms simple and intuitive.

This detailed plan provides a roadmap for developing a valuable community-driven feature. Initial focus will be on the MVP to establish the core workflow. 