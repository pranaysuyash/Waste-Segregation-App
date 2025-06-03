# Image Classification User Feedback & Learning Loop Plan

## 1. Introduction & Goals

This document outlines the plan for implementing a robust user feedback mechanism for the core image classification feature. The primary goals are:

*   **Improve Classification Accuracy:** Allow users to correct misclassifications, providing valuable data for refining the AI system.
*   **Enhance User Trust & Engagement:** Empower users to contribute to the app's intelligence and see the impact of their feedback (even if indirectly).
*   **Create a Learning Loop:** Establish a process (initially manual, potentially semi-automated later) to use aggregated feedback to improve prompts, identify challenging items, and guide future model improvements.
*   **Better Manage AI Uncertainty:** Provide clearer communication when the AI has low confidence and guide users on how to proceed or provide feedback.

## 2. User Interface (UI) & User Experience (UX) for Submitting Corrections

Details on how users will interact with the feedback system from within the app.

### 2.1. Initiating a Correction

*   **Location:** On the `ResultScreen` where classification results are displayed.
*   **Trigger:** A clearly visible button or icon, e.g., "Incorrect Result?" or a thumbs down icon next to the primary classified item name, or a "Suggest a Correction" link.
*   **Context:** This button should be easily accessible if the user disagrees with the AI's primary classification (item name, category, or material).
*   **Alternative Trigger (Low Confidence):** If the AI's confidence is below a certain threshold (see Section 6), the UI might proactively display a more prominent "Is this correct? Help us improve!" prompt that leads to the correction flow.

### 2.2. Correction Input Form/Interface

Upon tapping the correction trigger, a modal dialog or a new dedicated screen will appear.

*   **Display Original Classification:** Briefly show what the AI originally suggested (e.g., "AI said: Plastic Bottle").
*   **Input Fields for Correction:**
    1.  **Correct Item Name (Optional Text Input):** Allow users to type what they believe the item is. (e.g., `User-provided Item Name: "Milk Carton"`)
    2.  **Correct Category (Required Dropdown/Selector):** User MUST select from the app's predefined list of main waste categories (e.g., Paper, Plastic, Glass, Metal, Organic, E-waste, Other).
        *   This ensures structured feedback.
        *   The dropdown should ideally default to the AI's original category to make minor corrections easier.
    3.  **Correct Material (Optional Dropdown/Selector, dependent on Category):** If applicable for the selected category, allow users to specify material (e.g., if Category is "Plastic", Material could be "PET", "HDPE", "Mixed").
        *   This list would also be predefined.
    4.  **Disposal Instruction Override (More Advanced - Potentially Phase 2):** For MVP, focus on item/category/material. Allowing users to correct disposal instructions adds complexity unless it's a simple "This should be recycled, not landfill" flag.
    5.  **Notes (Optional Text Area):** A small text box for users to add any other comments or context (e.g., "This is a [brand name] coffee cup, which my local council says is not recyclable due to lining.").
*   **Image Review:** Display the original image that was classified so the user has context while providing feedback.
*   **Button:** "Submit Correction" or "Send Feedback".

### 2.3. Confirmation and User Acknowledgement

*   **Upon Submission:**
    *   Display a brief success message (e.g., "Thank you for your feedback! It helps us improve.").
    *   The dialog/screen should then close, returning the user to the previous screen or a relevant part of the app.
*   **No Immediate Change in App:** For Phase 1, submitting feedback does **not** immediately change the classification result shown in the user's current view or history for that specific instance. The correction goes to the backend for review.
*   **Managing Expectations:** It should be clear (perhaps in a FAQ or a one-time info tooltip for the feature) that feedback is used to improve the system over time and individual corrections may not always result in direct, immediate changes visible to that user for that specific past item, though future classifications of similar items should get better.
*   **(Future Consideration):** If a user's feedback is reviewed and leads to a significant change in how an item is generally classified, a *future* enhancement could be to notify the user (e.g., "Thanks! Your feedback on [item] helped us update our system."), but this is out of scope for the initial feedback submission mechanism.

## 3. Data Model for Storing User Feedback

This section defines the Firestore schema for capturing and managing user-submitted corrections to image classifications.

### 3.1. New Collection: `classification_feedback`

A new top-level Firestore collection will be created to store all user feedback on classifications.

*   **Collection Name:** `classification_feedback`
*   **Document ID:** Auto-generated unique ID for each feedback submission.

*   **Fields within each document:**
    *   `userId`: (String) The ID of the user who submitted the feedback. (Indexed for querying feedback by user).
    *   `originalClassificationId`: (String) The document ID of the original classification entry in the `user_classifications/{userId}/classifications/{classificationId}` collection (or your equivalent user history collection). This is crucial for linking.
    *   `originalImageHash`: (String, Optional) The perceptual hash of the image that was classified, if available from the original classification record. Useful for grouping feedback on visually similar images even if they are different classification instances.
    *   `originalAIItemName`: (String) The item name as originally classified by the AI.
    *   `originalAICategory`: (String) The category as originally classified by the AI.
    *   `originalAIMaterial`: (String, Optional) The material as originally classified by the AI.
    *   `originalAIConfidence`: (Number, Optional) The AI's confidence score for the original classification.
    *   `userSuggestedItemName`: (String, Optional) The item name suggested by the user.
    *   `userSuggestedCategory`: (String) The category selected by the user from the predefined list. (Required field in the feedback form).
    *   `userSuggestedMaterial`: (String, Optional) The material selected by the user from the predefined list (if applicable to the category).
    *   `userNotes`: (String, Optional) Any additional notes or comments provided by the user.
    *   `feedbackTimestamp`: (Timestamp) Server timestamp when the feedback was submitted.
    *   `reviewStatus`: (String) The status of the review process for this feedback. (Indexed for admin panel filtering).
        *   Possible values: "pending_review" (default), "under_review", "reviewed_accepted_impacted_ai", "reviewed_accepted_informational", "reviewed_rejected_incorrect", "reviewed_rejected_duplicate", "archived".
    *   `adminReviewerId`: (String, Optional) ID of the admin who reviewed the feedback.
    *   `adminReviewTimestamp`: (Timestamp, Optional) When the feedback was last reviewed/actioned by an admin.
    *   `adminNotes`: (String, Optional) Any notes added by the admin during the review.
    *   `appVersion`: (String, Optional) App version when feedback was submitted.
    *   `deviceInfo`: (Map, Optional) Basic device info (OS, model) if helpful for context.

### 3.2. Linking Feedback to Original Classification

*   The `originalClassificationId` field in the `classification_feedback` document is the primary link back to the specific classification event in the user's history.
*   When displaying an item from user history that has associated feedback (perhaps indicated by a flag on the original classification document or by querying `classification_feedback`), the app could potentially show that feedback was submitted.
*   The Admin Panel will heavily rely on `originalClassificationId` to pull up the original classification details alongside the user's feedback for comparison during review.

### 3.3. Considerations for User History (`user_classifications`)

Consider adding a field to the original classification document in `user_classifications/{userId}/classifications/{classificationId}`:
*   `hasFeedback`: (Boolean) Set to `true` if a user submits feedback for this classification.
*   `feedbackId`: (String, Optional) The ID of the corresponding document in `classification_feedback`.
This can simplify querying for classifications that have received feedback, though it requires an extra write when feedback is submitted.

## 4. Admin Panel - Feedback Review & Management Workflow

This section describes the functionalities within the Admin Panel (referencing `docs/technical/admin_panel_design.md`) for managing user-submitted classification feedback.

### 4.1. Feedback Listing & Prioritization View

*   **New Admin Panel Section:** "Classification Feedback" or similar, accessible from the main navigation.
*   **Default View:** A paginated, sortable, and filterable table/list of all feedback entries from the `classification_feedback` collection.
*   **Key Columns Displayed:**
    *   Feedback Submission Date (`feedbackTimestamp`)
    *   User ID (link to user profile view in Admin Panel)
    *   Original AI Item Name & Category
    *   User Suggested Item Name & Category
    *   Review Status (`reviewStatus`)
    *   Original Image Thumbnail (if feasible to display a small thumbnail)
    *   Admin Reviewer (if reviewed)
*   **Filtering Options:**
    *   By `reviewStatus` (e.g., show all "pending_review") - **Most important filter for workflow.**
    *   By `feedbackTimestamp` (date range).
    *   By `originalAICategory` or `userSuggestedCategory`.
    *   By `userId`.
*   **Sorting Options:** By `feedbackTimestamp`, `reviewStatus`, `originalAIConfidence` (if available and useful to sort by).
*   **Bulk Actions (Future):** Select multiple feedback items to change status (e.g., archive multiple low-priority ones).

### 4.2. Detailed Feedback Review Interface

Clicking on a feedback entry in the list view opens a detailed review screen/modal.

*   **Layout:** Two-column or clearly sectioned layout for easy comparison.
*   **Left Side (Original Classification):**
    *   Display the original image submitted by the user (larger view).
    *   Original AI Classification Details: `originalAIItemName`, `originalAICategory`, `originalAIMaterial`, `originalAIConfidence`, original disposal instructions.
    *   Link to the full original classification record/log if more context is needed.
*   **Right Side (User Feedback):**
    *   User Details: `userId`.
    *   User's Suggestions: `userSuggestedItemName`, `userSuggestedCategory`, `userSuggestedMaterial`.
    *   User Notes: `userNotes`.
    *   Feedback Timestamp: `feedbackTimestamp`.
*   **Admin Action Section (Below or alongside feedback details):**
    *   Current `reviewStatus`.
    *   Dropdown to change `reviewStatus` (e.g., "Mark as Accepted - AI Impacted", "Mark as Rejected - Incorrect User Input").
    *   Text area for `adminNotes`.
    *   "Save Review" button.

### 4.3. Actions on Feedback (Review Statuses)

These statuses, set by the admin, help track the feedback lifecycle and its impact.

*   `pending_review`: Default status for new submissions.
*   `under_review`: Admin has opened it but not yet made a decision.
*   `reviewed_accepted_impacted_ai`: User feedback was correct and directly led to a change in AI prompt, a new rule, or is a strong signal for model retraining for this item type.
*   `reviewed_accepted_informational`: User feedback was correct/helpful, but may not directly change AI logic immediately (e.g., unique item, very specific local context not generalizable, noted for general awareness).
*   `reviewed_rejected_incorrect`: User feedback was deemed incorrect after review.
*   `reviewed_rejected_duplicate`: User feedback is a duplicate of an already processed item or known issue.
*   `archived`: Feedback item closed without specific action, or after action, moved out of active review queue.

### 4.4. Analytics & Pattern Identification (Basic for MVP Admin)

*   **Dashboard Widget (Future Enhancement to Admin Dashboard):**
    *   Count of feedback items by `reviewStatus` (e.g., "X items pending review").
*   **Basic Reporting/Views within Feedback Section:**
    *   Ability to group or count feedback by `originalAIItemName` or `originalAICategory` to see which items/categories are most frequently corrected by users.
    *   Identify items with a high number of "reviewed_accepted_impacted_ai" statuses to prioritize for AI prompt adjustments.
    *   This doesn't need to be complex charts for MVP, even just sortable counts could be insightful.

## 5. Strategy for "Closing the Loop" - Utilizing Feedback to Improve AI

This section outlines how the collected and reviewed user feedback will be used to make the AI classification system smarter and more accurate over time.

### 5.1. Manual Review & Prompt Refinement (Short-Term & Ongoing)

This is the primary method for a solo developer to act on feedback initially.

*   **Process:**
    1.  Regularly review feedback items in the Admin Panel, especially those marked `pending_review`.
    2.  For feedback items marked `reviewed_accepted_impacted_ai` or `reviewed_accepted_informational`, analyze the discrepancy between the AI's original classification and the user's (correct) suggestion.
    3.  **Identify Patterns:** Look for recurring themes:
        *   Are specific item types consistently misidentified as something else?
        *   Is a particular material often confused?
        *   Are there nuances in user descriptions (from `userNotes`) that highlight AI blind spots?
        *   Do certain image characteristics (lighting, angle, background) correlate with misclassifications that users correct?
    4.  **Refine System Prompts:** Based on these patterns, manually adjust the system prompts used for the LLM-based classification (e.g., OpenAI, Gemini) in `ai_service.dart` or your prompt configuration files.
        *   **Example:** If users frequently correct "plastic cup" to "paper cup with plastic lining" and provide notes about non-recyclability, the prompt could be augmented with instructions to pay closer attention to such distinctions or to ask clarifying questions if visual cues are ambiguous.
        *   Add examples of common confusions to the prompt as few-shot examples, if supported and effective for the LLM.
        *   Emphasize differentiation between visually similar but materially different items.
    5.  **Test Changes:** After prompt updates, test with known problematic images to see if accuracy improves.
    6.  **Iterate:** This is an ongoing cycle of review, analysis, prompt refinement, and testing.
*   **Tooling:** The Admin Panel's filtering and sorting for feedback (Section 4.4) will be key to identifying these patterns.

### 5.2. Identifying Consistently Misclassified Items & Edge Cases

*   **Process:**
    *   Use the Admin Panel to specifically look for items/categories that have a high volume of user corrections, especially those accepted by the admin.
    *   Maintain a separate internal list or document (e.g., "AI Challenge Log") of these consistently problematic items or types of images.
*   **Potential Actions:**
    *   **Targeted Prompt Engineering:** Create very specific prompt segments or rules for these known difficult items if the general prompt isn't sufficient.
    *   **Educational Content Creation:** If an item is genuinely ambiguous or disposal rules are complex, create new educational content about it and link to it from classification results.
    *   **Data Augmentation (Future):** If you were to train/fine-tune a custom model, these items would be prime candidates for collecting more training examples.
    *   **Consider Heuristics/Rules (Sparingly):** For very specific, reliably identified misclassifications, a simple post-processing rule *could* be a temporary fix, but this should be used with caution as it can become complex to maintain (e.g., "IF AI says X AND user image contains Y visual cue THEN override to Z"). Direct prompt improvement is generally preferred.

### 5.3. Data Export for Future Model Fine-Tuning (Long-Term Vision)

*   **Purpose:** While Phase 1 relies on LLM prompting, the collected, reviewed, and validated user feedback is a valuable dataset.
*   **Process:**
    *   Periodically (e.g., quarterly), export data from the `classification_feedback` collection, particularly items where `reviewStatus` indicates an accepted correction.
    *   This dataset would include the original image (or its hash/URL), the AI's original (incorrect) prediction, and the user's (verified correct) labels (item name, category, material).
    *   Format this data into a structure suitable for machine learning (e.g., CSV, JSONL).
*   **Future Use:**
    *   If you decide to train a custom image classification model (e.g., using TensorFlow, PyTorch) for common items or as a specialized first-pass filter, this curated dataset would be invaluable for training or fine-tuning.
    *   Some LLM providers may offer fine-tuning capabilities in the future where such structured feedback data could be used.
*   **Admin Panel Support:** A simple "Export Feedback Data" button in the Admin Panel (filtered by date range and review status) would facilitate this.

This multi-faceted approach allows for immediate, iterative improvements via prompt engineering while building a valuable dataset for more advanced AI enhancements in the future.

## 6. Handling and Communicating AI Uncertainty to Users

This section details how the app will communicate AI uncertainty to users and leverage these situations to encourage feedback.

### 6.1. UI Cues for Low Confidence Results

*   **Confidence Score Threshold:** Define a threshold (e.g., if `originalAIConfidence < 0.75` or a similar empirically determined value) below which the AI's classification is considered "low confidence."
*   **Visual Indicators on `ResultScreen`:**
    *   Next to the classified item name, display the confidence score if it's low (e.g., "Plastic Bottle (68% confident)").
    *   Use a distinct color (e.g., amber/yellow instead of green) for the result text or background when confidence is low.
    *   A small icon (e.g., a question mark, an unsure emoji) could also be displayed.
    *   Phrasing could change: Instead of "This is a Plastic Bottle," it might say, "This looks like a Plastic Bottle?" or "Possible item: Plastic Bottle."
*   **Subtle but Clear:** The goal is to inform the user that the AI is not entirely sure, without undermining trust in correct high-confidence classifications.

### 6.2. Prompting for Feedback on Low Confidence Classifications

*   **Proactive Feedback Solicitation:** When a low confidence result is displayed, the UI should more actively encourage user input.
*   **Call to Action:** Instead of just the standard "Incorrect Result?" button, display a more prominent message like:
    *   "Not quite sure about this one. Can you help us identify it?" (leading to the correction form - Section 2.2).
    *   "Is this a [AI Suggested Item]? Let us know!"
*   **Simplified Feedback for Confirmation:** If the AI suggests "Plastic Bottle (65% confident)", an option could be quick confirmation buttons: "Yes, it is" / "No, it's something else".
    *   "Yes, it is" could simply boost an internal counter for that classification without requiring the full form, or flag it as "user-confirmed low confidence."
    *   "No, it's something else" would lead to the full correction form (Section 2.2).

### 6.3. "Request Manual Review" Option (Considerations for MVP)

This is a more advanced feature that needs careful expectation management for a solo developer.

*   **Scenario:** For very low confidence results, or if the user is particularly unsure and the item is complex.
*   **UI Element:** A button like "Request Expert Review" or "Flag for Review."
*   **Action:**
    1.  Submitting this would create a specific type of entry in the `classification_feedback` collection, perhaps with a `reviewStatus` of "pending_expert_review" or a flag `expertReviewRequested: true`.
    2.  The user is informed: "Thanks! We've flagged this item for a closer look by our team. We appreciate your help!"
*   **MVP Consideration (Solo Dev):**
    *   **No Guaranteed Individual Follow-up:** For MVP, it's crucial **not** to promise individual users that their specific flagged item will be personally reviewed *and reported back to them*. This is not scalable for a solo developer.
    *   **Admin Panel Prioritization:** The admin (you) can filter for these "expertReviewRequested" items in the Admin Panel and prioritize them if they seem particularly challenging or interesting.
    *   **General System Improvement:** The value is still in identifying items that even users find hard to correct directly, which can inform AI development or educational content creation.
*   **Alternative for MVP:** Instead of a dedicated "Request Manual Review" button, the `userNotes` field in the standard correction form (Section 2.2) can be used. If a user is unsure, they can describe their uncertainty in the notes. The admin can then filter/search for notes containing keywords like "unsure," "don't know," etc.

By transparently communicating uncertainty and making it easy for users to provide input, especially in these ambiguous cases, the app can build a stronger collaborative relationship with its users and gather richer data for improvement. 