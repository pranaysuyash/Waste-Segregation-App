# Current User Flows

This document outlines the current user flows in the Waste Segregation App, describing the step-by-step journey users take to accomplish key tasks within the application.

## Core User Flows

### 1. Onboarding Flow

**Purpose**: Introduce new users to the app, explain key features, and set up their account.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Welcome     │     │ Feature     │     │ Sign-in     │     │ Permissions │     │ Home Screen │
│ Screen      │────>│ Highlights  │────>│ Options     │────>│ Request     │────>│             │
│             │     │ Carousel    │     │             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              │
                                              ▼
                                        ┌─────────────┐
                                        │ Guest Mode  │
                                        │ (Optional)  │
                                        │             │
                                        └──────┬──────┘
                                               │
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │ Home Screen │
                                        │             │
                                        │             │
                                        └─────────────┘
```

#### Detailed Steps:
1. **Welcome Screen**: App introduction and branding
2. **Feature Highlights**: Carousel explaining key features
   - Waste identification
   - Educational content
   - Gamification system
   - Waste tracking dashboard
3. **Sign-in Options**:
   - Google Sign-In
   - Guest Mode (local-only storage)
4. **Permissions Request**:
   - Camera access
   - Storage access
   - Notifications (optional)
5. **Home Screen**: Main dashboard with quick access to features

### 2. Basic Classification Flow

**Purpose**: Allow users to identify and properly classify waste items using their device camera or gallery images.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Home Screen │     │ Capture     │     │ Preview &   │     │ Processing  │     │ Results     │
│ (+ Button)  │────>│ Options     │────>│ Confirm     │────>│ Screen      │────>│ Screen      │
│             │     │             │     │             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                           │                                                            │
                           │                                                            │
                           ▼                                                            │
                     ┌─────────────┐                                            ┌──────▼──────┐
                     │ Gallery     │                                            │ Points      │
                     │ Selection   │                                            │ Animation   │
                     │             │                                            │             │
                     └─────┬───────┘                                            └──────┬──────┘
                           │                                                            │
                           │                                                            │
                           ▼                                                            ▼
                     ┌─────────────┐                                            ┌─────────────┐
                     │ Preview &   │                                            │ Action      │
                     │ Confirm     │                                            │ Options     │
                     │             │                                            │             │
                     └─────────────┘                                            └─────────────┘
```

#### Detailed Steps:
1. **Home Screen**: User taps the "+" button or camera icon
2. **Capture Options**:
   - Take photo with camera
   - Select from gallery
3. **Preview & Confirm**:
   - Review captured/selected image
   - Option to retake/reselect
   - Proceed to classification
4. **Processing Screen**:
   - Visual indicator while API processes image
   - Brief educational tip while waiting
5. **Results Screen**:
   - Waste category (color-coded)
   - Item identification
   - Material composition
   - Disposal instructions
   - Environmental impact
6. **Points Animation**:
   - Visual feedback of points earned
   - Achievement notifications (if applicable)
7. **Action Options**:
   - Save to history
   - Share results
   - Learn more (educational content)
   - Classify another item

### 3. Educational Content Flow

**Purpose**: Provide users with educational resources about waste management and sustainability.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Home Screen │     │ Educational │     │ Content     │     │ Content     │
│ (Learn Tab) │────>│ Content Hub │────>│ Category    │────>│ Detail View │
│             │     │             │     │ Selection   │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └──────┬──────┘
                                                                    │
                                                                    │
                                                                    ▼
                                                            ┌─────────────┐
                                                            │ Related     │
                                                            │ Content     │
                                                            │             │
                                                            └─────────────┘
```

#### Detailed Steps:
1. **Home Screen**: User taps the "Learn" tab
2. **Educational Content Hub**:
   - Featured content
   - Recently added
   - Trending topics
   - Content categories
3. **Category Selection**:
   - By waste type (recycling, composting, etc.)
   - By format (articles, videos, infographics)
   - By difficulty (beginner, intermediate, advanced)
4. **Content Detail View**:
   - Full content display
   - Interactive elements
   - Bookmark option
   - Share functionality
5. **Related Content**:
   - Suggestions for further learning
   - "Next steps" recommendations

### 4. Achievements & Gamification Flow

**Purpose**: Engage users through gamification elements that track progress and reward consistent usage.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Home Screen │     │ Achievements│     │ Achievement │     │ Achievement │
│ (Profile)   │────>│ Dashboard   │────>│ Category    │────>│ Detail View │
│             │     │             │     │ View        │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                           │
                           │
                           ▼
                     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
                     │ Active      │     │ Challenge   │     │ Challenge   │
                     │ Challenges  │────>│ Detail View │────>│ Progress    │
                     │             │     │             │     │ Update      │
                     └─────────────┘     └─────────────┘     └─────────────┘
                           │
                           │
                           ▼
                     ┌─────────────┐
                     │ Stats &     │
                     │ Progress    │
                     │             │
                     └─────────────┘
```

#### Detailed Steps:
1. **Home Screen**: User taps the "Profile" or "Achievements" icon
2. **Achievements Dashboard**:
   - Overview of unlocked achievements
   - Progress toward next level
   - Daily streak status
   - Recent awards
3. **Achievement Category View**:
   - Classification achievements
   - Educational achievements
   - Community achievements
   - Special events
4. **Achievement Detail View**:
   - Description and requirements
   - Progress tracking
   - Rewards earned
   - Related achievements
5. **Active Challenges**:
   - Current time-limited challenges
   - Progress toward each challenge
   - Rewards for completion
   - Expiration dates
6. **Challenge Detail View**:
   - Specific requirements
   - Tips for completion
   - Related educational content
7. **Stats & Progress**:
   - Historical activity graph
   - Total items classified
   - Environmental impact metrics
   - Skill development tracking

### 5. Waste Dashboard Flow

**Purpose**: Provide users with insights into their waste patterns and environmental impact over time.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Home Screen │     │ Waste       │     │ Dashboard   │     │ Detailed    │
│ (Dashboard) │────>│ Dashboard   │────>│ Tab         │────>│ Analytics   │
│             │     │ Overview    │     │ Selection   │     │ View        │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              │
                                              ▼
                                        ┌─────────────┐     ┌─────────────┐
                                        │ Time Period │     │ Filtered    │
                                        │ Filter      │────>│ Results     │
                                        │             │     │             │
                                        └─────────────┘     └─────────────┘
                                              │
                                              │
                                              ▼
                                        ┌─────────────┐     ┌─────────────┐
                                        │ Export or   │     │ Sharing     │
                                        │ Share       │────>│ Options     │
                                        │             │     │             │
                                        └─────────────┘     └─────────────┘
```

#### Detailed Steps:
1. **Home Screen**: User taps the "Dashboard" or "Analytics" icon
2. **Waste Dashboard Overview**:
   - Summary metrics
   - Recent trends
   - Key insights
   - Quick access to detailed views
3. **Dashboard Tab Selection**:
   - Overview tab
   - Trends tab
   - Insights tab
   - Impact tab
4. **Detailed Analytics View**:
   - Expanded charts
   - Detailed breakdowns
   - Comparative analysis
   - Historical data
5. **Time Period Filter**:
   - This week
   - This month
   - Custom date range
   - All time
6. **Export or Share**:
   - Generate report
   - Share insights
   - Set goals based on data

### 6. Settings & Preferences Flow

**Purpose**: Allow users to customize their app experience and manage their account settings.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Home Screen │     │ Settings    │     │ Setting     │
│ (Settings)  │────>│ Categories  │────>│ Detail      │
│             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
                           │
                           ├──────────────────┐
                           │                  │
                           ▼                  ▼
                     ┌─────────────┐    ┌─────────────┐
                     │ Account     │    │ App         │
                     │ Settings    │    │ Preferences │
                     │             │    │             │
                     └─────────────┘    └─────────────┘
                           │                  │
                           ▼                  ▼
                     ┌─────────────┐    ┌─────────────┐
                     │ Profile     │    │ Notification│
                     │ Management  │    │ Settings    │
                     │             │    │             │
                     └─────────────┘    └─────────────┘
                           │                  │
                           ▼                  ▼
                     ┌─────────────┐    ┌─────────────┐
                     │ Privacy     │    │ Theme &     │
                     │ Settings    │    │ Display     │
                     │             │    │             │
                     └─────────────┘    └─────────────┘
```

#### Detailed Steps:
1. **Home Screen**: User taps the "Settings" icon
2. **Settings Categories**:
   - Account
   - Preferences
   - Notifications
   - Privacy
   - About
   - Help & Support
3. **Account Settings**:
   - Profile information
   - Sign-in method
   - Linked accounts
   - Account deletion
4. **App Preferences**:
   - Theme selection (light/dark/system)
   - Language selection
   - Storage management
   - Camera preferences
5. **Notification Settings**:
   - Push notification toggles
   - Daily reminders
   - Challenge alerts
   - Achievement notifications
6. **Privacy Settings**:
   - Data sharing preferences
   - Analytics opt-out
   - Export user data
   - Clear history

## User Flow Integrations

### Multi-feature Flows

#### Classification to Education Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Results     │     │ "Learn More"│     │ Educational │     │ Return to   │
│ Screen      │────>│ Button      │────>│ Content     │────>│ Results     │
│             │     │             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

#### Classification to Challenge Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Results     │     │ "Challenge  │     │ Challenge   │     │ Return to   │
│ Screen      │────>│ Progress"   │────>│ Detail      │────>│ Results     │
│             │     │ Notification│     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

#### Dashboard to Action Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Waste       │     │ Insight     │     │ Suggested   │
│ Dashboard   │────>│ Card        │────>│ Action      │
│             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                   ┌─────────────────────────┬┴───────────────────────┐
                   │                         │                        │
                   ▼                         ▼                        ▼
            ┌─────────────┐          ┌─────────────┐          ┌─────────────┐
            │ Educational │          │ New         │          │ Challenge   │
            │ Content     │          │ Classification│         │ Acceptance  │
            │             │          │             │          │             │
            └─────────────┘          └─────────────┘          └─────────────┘
```

## Error Handling Flows

### Connectivity Loss Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Any Screen  │     │ Connection  │     │ Offline     │     │ Retry       │
│ with Network│────>│ Error       │────>│ Mode        │────>│ Connection  │
│ Action      │     │ Dialog      │     │ Activation  │     │ Button      │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                              │                    │
                                              │                    │
                                              ▼                    ▼
                                        ┌─────────────┐     ┌─────────────┐
                                        │ Limited     │     │ Online Mode │
                                        │ Functionality│     │ Restored   │
                                        │             │     │             │
                                        └─────────────┘     └─────────────┘
```

### Classification Failure Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Processing  │     │ Error       │     │ Retry       │     │ Alternative │
│ Screen      │────>│ Dialog      │────>│ Option      │────>│ Options     │
│             │     │             │     │             │     │             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
                                              │                    │
                                              │                    │
                                              ▼                    ▼
                                        ┌─────────────┐     ┌─────────────┐
                                        │ Image       │     │ Manual      │
                                        │ Adjustment  │     │ Selection   │
                                        │ Tips        │     │ Option      │
                                        └─────────────┘     └─────────────┘
```

## Accessibility Considerations

All user flows include accessibility considerations:

1. **Screen Reader Support**:
   - All screens have proper labeling
   - Meaningful descriptions for actions
   - Logical navigation sequence

2. **Alternative Navigation**:
   - Keyboard navigation support for web version
   - Voice command capabilities (where supported)
   - Gesture alternatives

3. **Visual Accessibility**:
   - High contrast mode flows
   - Text size adjustment options
   - Color-blind friendly alternatives

4. **Cognitive Accessibility**:
   - Simple, consistent UI patterns
   - Clear error recovery
   - Persistent navigation aids
