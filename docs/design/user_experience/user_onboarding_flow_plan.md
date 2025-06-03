# User Onboarding Flow Plan

## 1. Introduction & Goals of Onboarding

This document outlines the design for the user onboarding flow in the Waste Segregation App. The primary goals are:

*   Clearly communicate the app's core value proposition: helping users correctly segregate waste and learn about sustainability through easy-to-use AI-powered tools.
*   Smoothly guide new users through initial setup, including necessary permissions, explaining the "why" behind each request.
*   Introduce key app features (image classification, educational content, gamification) in an engaging, concise, and benefit-oriented way.
*   Allow users to set essential initial preferences to personalize their early experience (e.g., notification preferences, leaderboard visibility).
*   Ensure a positive and motivating first-time user experience (FTUE) that encourages continued app usage and exploration.
*   Set a friendly and helpful tone for the app.

## 2. Onboarding Trigger & Entry Points

*   **Primary Trigger:** Onboarding flow begins automatically immediately after a new user successfully installs and opens the app for the very first time, typically before any authentication or main app interface is shown.
*   **Authentication Timing:** Onboarding can occur *before or after* initial authentication (e.g., social sign-in/registration). If before, ensure any preferences set are linked to the account upon authentication. If after, the welcome is more personalized (e.g., "Welcome, [User Name]!"). For simplicity, let's assume it can start before full auth, focusing on app features, with auth being a final step or integrated if very simple.
*   **Skipping Onboarding:**
    *   A "Skip for Now" or "Skip Intro" option should be available, perhaps after the first or second screen. This is important for users who want to dive in directly or are re-installing.
    *   If skipped, provide a way to access a summary or key feature tutorials later (e.g., from a "Help" or "Settings" menu).
*   **Re-accessing Onboarding:** The full onboarding flow is generally not re-accessed once completed or skipped. However, key feature introductions or tutorials could be made available individually in a "Help" or "Tips" section of the app.
*   **Contextual Onboarding/Feature Tours (Post-Initial Onboarding):** For complex features introduced later or not covered in initial onboarding, use contextual tooltips or short guided tours when the user first encounters them.

## 3. Onboarding Steps & Screens (Sequential Flow)

Detailed breakdown of each screen/step in the onboarding process. This is typically implemented as a horizontal swipe-through carousel or a series of modal screens.

### 3.1. Welcome Screen(s) (1-2 screens)
*   **Purpose:** Greet the user, briefly state the app's main purpose, and create a positive first impression.
*   **Screen 1 (Brand/Logo Splash - Optional but common):**
    *   **Content:** App logo, app name, possibly a tagline (e.g., "Sort Smarter, Live Greener.").
    *   **Visuals:** Clean, appealing, possibly with a subtle animation.
    *   **Action:** Auto-advances after a short delay or on tap.
*   **Screen 2 (Main Welcome & Brief Intro):**
    *   **Headline:** e.g., "Welcome to EcoSnap!" (or app name)
    *   **Brief Pitch (1-2 lines):** "Your smart companion for easy waste sorting and learning about sustainability."
    *   **Visual:** Engaging illustration or photo related to positive environmental action (e.g., clean recycling bins, thriving plant).
    *   **Action:** "Next" or "Continue" button.

### 3.2. Core Value Proposition & Feature Highlights (2-3 screens)
*   **Purpose:** Quickly showcase the main benefits and key features of the app in a digestible way, focusing on what the user will gain.
*   **Format:** Each screen highlights one major benefit/feature with a concise headline, 1-2 lines of descriptive text, and a relevant icon or simple illustration.

    *   **Screen 3: Smart Classification**
        *   **Headline:** "Snap, Sort, Simplify!"
        *   **Text:** "Instantly identify waste items with your camera. Our AI tells you how to dispose of it correctly."
        *   **Visual:** Icon of a camera scanning an item, transforming into recycle/compost symbols.
        *   **Action:** "Next"

    *   **Screen 4: Learn & Discover**
        *   **Headline:** "Become an Eco-Expert!"
        *   **Text:** "Explore easy guides, fun quizzes, and tips to reduce waste and live more sustainably."
        *   **Visual:** Icon of a book/lightbulb or a simple illustration of someone learning.
        *   **Action:** "Next"

    *   **Screen 5: Earn Rewards & Track Progress (Gamification Teaser)**
        *   **Headline:** "Make an Impact, Get Rewarded!"
        *   **Text:** "Earn points, collect badges, and see your positive impact grow as you learn and sort."
        *   **Visual:** Icons of points, a badge, and a simple upward trend graph.
        *   **Action:** "Next" or "Continue"

### 3.3. Permissions Requests (1-2 screens, or integrated with feature intros)
*   **Purpose:** Request necessary app permissions (Camera, Notifications) at the appropriate time, explaining why they are needed.
*   **Best Practice:** Ask for permissions contextually, ideally right before the feature requiring the permission is used or introduced. However, in a streamlined onboarding, they can be grouped after feature highlights.
*   **Screen 6: Camera Permission**
    *   **Headline:** "Enable Your Camera to Scan Waste"
    *   **Text:** "To identify items, EcoSnap needs access to your camera. We only use it when you're actively scanning."
    *   **Visual:** Icon of a camera, perhaps showing a simplified scanning animation.
    *   **Action:** "Allow Camera Access" button (triggers system permission dialog). Include a "Maybe Later" or "Not Now" if skipping is allowed, but clearly state the feature will be limited.
    *   **Rationale Display:** Ensure the text clearly explains *why* the permission is needed.
*   **Screen 7: Notifications Permission (Optional at this stage, could be prompted later contextually)**
    *   **Headline:** "Stay Updated & Motivated!"
    *   **Text:** "Allow notifications for helpful reminders, new challenges, and when you unlock cool badges."
    *   **Visual:** Icon of a notification bell or a sample notification.
    *   **Action:** "Allow Notifications" (triggers system dialog). "Maybe Later" option.
    *   **Note:** Notification permission is often best asked for *after* the user has experienced some value or when a specific feature requiring it is first used (e.g., first badge earned, first streak started).

### 3.4. Introduction to Image Classification (Post-Permission, if camera granted)
*   **Purpose:** Briefly reiterate how to use the core classification feature, now that permission might be granted.
*   **This step might be very short or combined if camera permission was just granted.**
*   **Screen 8 (Optional - or merged with Camera Permission success):**
    *   **Headline:** "Ready to Scan Your First Item?"
    *   **Text:** "Tap the camera icon on the main screen anytime to identify waste."
    *   **Visual:** A simple animation pointing to where the camera/scan button will be in the main app UI, or a very short (few seconds) looping video/GIF of the classification in action.
    *   **Action:** "Got it!" or "Next"

### 3.5. Introduction to Educational Content (Brief Reiteration)
*   **Purpose:** Remind users where to find learning resources.
*   **Screen 9 (Optional - can be part of a summary screen):**
    *   **Headline:** "Explore & Learn"
    *   **Text:** "Find helpful articles, tips, and quizzes in our 'Learn' section."
    *   **Visual:** Icon representing the "Learn" section of the app.
    *   **Action:** "Next"

### 3.6. Introduction to Gamification (Brief Reiteration)
*   **Purpose:** Briefly set expectations for rewards and progress tracking.
*   **Screen 10 (Optional - can be part of a summary screen):**
    *   **Headline:** "Track Your Eco-Journey!"
    *   **Text:** "Check your Profile to see your points, badges, and challenges."
    *   **Visual:** Icon representing the User Profile section.
    *   **Action:** "Next"

### 3.7. Initial User Preferences Setup (1 screen - Optional MVP)
*   **Purpose:** Allow users to set a few key preferences upfront to tailor their experience. For MVP, this can be deferred to app settings to simplify onboarding.
*   **If included:**
    *   **Screen 11: Quick Preferences**
        *   **Headline:** "Personalize Your Experience"
        *   **Options (Examples - keep limited):**
            *   **Leaderboard Visibility:** Toggle: "Show my activity on leaderboards" (Default on, with info about alias/privacy settings later in profile).
            *   **Notification Types (if notifications enabled):** Simple toggles for "General Tips & News", "Gamification Updates". More granular controls in main app settings.
        *   **Visuals:** Simple toggle switches or clear option selectors.
        *   **Action:** "Save & Continue" or "Next"
    *   **Note:** If authentication (sign-up/login) hasn't happened yet, these preferences need to be stored temporarily and applied once the user account is created.

### 3.8. Final "Get Started" Screen
*   **Purpose:** Signal the end of onboarding and transition the user into the main app.
*   **Screen 12: All Set!**
    *   **Headline:** "You're All Set!" or "Let's Make a Difference!"
    *   **Text:** "Start exploring, scanning, and learning. Every small action counts!"
    *   **Visual:** Positive, encouraging graphic (e.g., a green planet, happy people recycling, app's main dashboard preview).
    *   **Action:** "Let's Go!" or "Start Exploring" button, which dismisses onboarding and takes the user to the main app screen (e.g., Home screen or Classification screen).
    *   **Authentication Link (if not yet done):** If sign-up/login is required and hasn't occurred, this screen would also prominently feature "Sign Up / Log In" actions.

## 4. Content & Messaging for Each Step

*(This section can be considered largely covered by the detailed descriptions within Section 3. If specific copywriting or detailed image/icon descriptions are needed later, they can be added here or as an appendix. For now, we will proceed as if Section 3 is sufficient.)*

## 5. UI/UX Considerations for Onboarding

*   **Visual Design & Branding:**
    *   Maintain consistency with the overall app branding (colors, typography, iconography).
    *   Use high-quality, friendly, and positive illustrations or minimalist icons that align with the app's eco-friendly theme.
    *   Ensure visuals are culturally sensitive and appealing to a broad audience.
    *   Employ a clean, uncluttered layout for each screen to prevent cognitive overload.
*   **Interactivity & Engagement:**
    *   Use smooth transitions between screens (e.g., horizontal swipe for carousels).
    *   Consider subtle animations on icons or text to add delight, but avoid overly distracting or slow animations.
    *   Provide clear visual feedback for button taps or interactions.
*   **Progress Indication:**
    *   Clearly show users where they are in the onboarding flow (e.g., dot indicators for swipe carousels, step numbers like "Step 3 of 5").
    *   A visual progress bar can also be effective if the flow has a fixed number of steps.
    *   Ensure the final step feels conclusive.
*   **Clarity & Conciseness:**
    *   Use clear, simple language. Avoid jargon or overly technical terms.
    *   Keep text to a minimum on each screen. Headlines should be impactful, and body text should be scannable (1-3 short sentences).
    *   Ensure calls to action (CTAs) are prominent and clearly state what will happen next (e.g., "Allow Camera Access," "Next," "Get Started").
*   **Accessibility:**
    *   Follow WCAG guidelines. Ensure sufficient color contrast for text and interactive elements.
    *   Support dynamic font sizes (user's system settings).
    *   Provide alternative text for images if possible, or ensure visuals are decorative and information is conveyed through text for screen reader users.
    *   Ensure easy tap targets for buttons and interactive elements.
*   **Skip/Exit Option:**
    *   As mentioned in Section 2, provide a clear and easily accessible way to skip the onboarding flow (e.g., "Skip Intro" text link at the top or bottom corner).
    *   If skipped, ensure the user lands on a logical default screen of the app.
*   **Performance:**
    *   Onboarding screens should load quickly. Optimize images and assets.

## 6. Technical Implementation Notes

*   **State Management:**
    *   Reliably track whether a user has completed the onboarding flow. Typically, a boolean flag (e.g., `hasCompletedOnboarding`) is stored in `SharedPreferences` (Flutter), `UserDefaults` (iOS), or similar local storage once the user finishes or explicitly skips.
    *   If onboarding occurs before authentication, this flag might initially be local. Once the user authenticates, this status should ideally be synced or associated with their user profile in the backend (e.g., a field in `UserProfile`) to ensure consistency across devices or on re-installation if they log in.
*   **Permissions Handling:**
    *   Use a reputable Flutter plugin for requesting permissions (e.g., `permission_handler`).
    *   Handle different permission states gracefully: granted, denied, permanently denied (requires guiding user to settings).
    *   If a permission is denied, the app should still function, but the corresponding feature might be disabled or offer an alternative.
*   **Navigation:**
    *   Use a clear navigation structure for the onboarding flow (e.g., Flutter's `PageView` for a swipeable carousel or a series of `Navigator.push` for modal screens).
    *   Ensure the back button behavior is logical (e.g., goes to the previous onboarding screen, or exits app if on the first screen and no skip option is taken).
*   **Analytics/Tracking:**
    *   Implement analytics (e.g., Firebase Analytics) to track user progression through the onboarding flow.
    *   Key events to track: `onboarding_started`, `onboarding_step_viewed` (with step_id/name), `onboarding_permission_requested` (with permission_type and status), `onboarding_skipped`, `onboarding_completed`.
    *   This data is crucial for identifying drop-off points and optimizing the flow.
*   **Linking Preferences:**
    *   If preferences are set during onboarding (Section 3.7) before authentication, store them locally. Upon successful account creation/login, these preferences should be saved to the user's profile on the backend (e.g., Firestore `UserProfile` document).
*   **Modularity:**
    *   Design the onboarding flow as a modular component that can be updated or modified without impacting the core app significantly.

## 7. Future Enhancements to Onboarding

*   **Personalized Onboarding Paths:**
    *   Based on a very brief initial question (e.g., "What are you most interested in? A) Quick Sorting, B) Learning about Waste, C) Eco-Challenges"), slightly tailor the order or emphasis of feature introductions.
*   **Interactive Mini-Tutorials:**
    *   Instead of static screens, include a very simple interactive task for a key feature (e.g., a mock "drag and drop" sorting game for one item, or a single-question quiz preview).
*   **Video Integration:**
    *   Short, engaging video clips (e.g., <30 seconds) to welcome users or demonstrate key features. These need to be optimized for mobile and include captions.
*   **Localization:**
    *   Translate onboarding content into multiple languages as the app's user base grows.
*   **A/B Testing Onboarding Flows:**
    *   Implement mechanisms to test different versions of the onboarding flow (e.g., different messaging, number of steps, visuals) to see which performs better in terms of completion rates and early user engagement.
*   **Contextual Tips Post-Onboarding:**
    *   After initial onboarding, use contextual tooltips or short guides when a user first encounters a more advanced feature not covered in the initial flow.
*   **Celebrate Early Wins:**
    *   If gamification is introduced, perhaps award a small "Welcome" badge or initial points upon completing onboarding to give an immediate sense of achievement. 