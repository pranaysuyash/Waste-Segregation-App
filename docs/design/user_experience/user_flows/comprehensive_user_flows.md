# Comprehensive User Flows Catalog
*Last Updated: December 2024*

This document serves as a comprehensive catalogue of end-to-end user flows for the WasteWise app—both what exists today and key future flows to design and implement. Use this as the basis for detailed flow diagrams, wireframes, and automated-agent tasks.

## Core User Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Onboarding & Setup** | First-Run Onboarding | 1. Launch → 2. Welcome carousel (3 cards) → 3. Permissions prompts (Camera, Notifications) → 4. Quick tour tooltips (Scan, History, Community) | Progressive tips on first use of each feature |
| | Guest ↔ Sign-in | 1. Splash/Login → 2a. Google Sign-In or 2b. Continue as Guest → 3. Set display name | Future: add Email/Password, family invite links |
| | Personalisation Quiz | 1. First‑Run → 2. "Help us customise" quiz (3–5 questions on household type, preferred language, disposal habits) → 3. Store prefs | Boosts retention by tailoring tips, notifications & achievements from day 1. Future: dynamic segmentation for A/B tests. |
| | PWA / Home‑Screen Install | 1. Banner prompt → 2. Install confirmation → 3. In‑app "You're offline‑ready!" toast | Makes the app discoverable without stores; unlocks offline scanning once on‑device model arrives. |

## Core Classification Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Core Classification** | Camera Scan | 1. Home → 2. Tap "Scan" FAB → 3. Camera preview + framing grid + pinch-zoom → 4. Capture | Future: voice-activated capture |
| | Gallery Upload | 1. Home → 2. Tap "Upload" icon → 3. Pick image from gallery → 4. Preview & confirm | |
| | AI Analysis & Result | 1. Show spinner / shimmer → 2. Result card with image, label, confidence badge, "Explain" drawer → 3. Save to History or Re-analyse | Future: "Why?" panel, low-confidence banner |
| | Batch Scan Mode | 1. Hold "Scan" FAB → 2. Multi‑capture gallery (up to 10) → 3. Bulk analyse → 4. Show grid of results | Speeds up sorting at home / events. Future: auto‑detect duplicates, CSV export. |
| | AR Sorting Guidance | 1. Scan result → 2. "View AR Guide" → 3. Live camera overlay with arrows toward recyclables/organic | Differentiator for Gen Z users; relies on ARCore / ARKit. |

## Feedback & Re-Analysis Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Feedback & Re-Analysis** | Classification Feedback | 1. Result view → 2. Tap "Feedback" → 3. Correct / Incorrect + select correction + notes → 4. Submit | Add: "Re-analyse with correction" button |
| | Re-analysis Loop | 1. After incorrect → 2. Trigger re-analysis → 3. Show loading → 4. Updated result card | |
| | Dispute Resolution | 1. Incorrect result → 2. "Escalate" → 3. Upload extra photos + description → 4. Asynchronous human review → 5. Push update | Ensures model quality in ambiguous cases; builds trusted dataset for re‑training. |

## History & Impact Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **History & Impact** | History List | 1. Home → 2. History tab → 3. Infinite-scroll list with shimmer placeholders → 4. Filter & search drawer | Future: bulk delete / export CSV |
| | History Detail | 1. Tap History item → 2. Detail modal (ModernCard) with full classification data | |
| | Impact Summary | 1. History tab header → 2. Show CO₂ saved, items recycled count, streak | Future: exportable "impact report" |
| | Seasonal Footprint Report | 1. History tab → 2. "Generate Quarterly Report" → 3. PDF preview → 4. Share / download | Useful for CSR programs and school projects. Future: auto‑email subscription, company branding for B2B. |

## Gamification & Community Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Gamification & Community** | Achievements & Rewards | 1. Home / Rewards tab → 2. Badge list with progress bars → 3. Tap badge for detail / claim | Future: daily challenges, community goals |
| | Leaderboard | 1. Rewards → 2. Leaderboard (tiered view) → 3. Confetti + haptic on level-up | Future: friend invites, team challenges |
| | Community Feed | 1. Home → 2. Community tab → 3. Infinite feed with skeletons → 4. Tap item for context | |
| | Daily Eco‑Quests | 1. Rewards tab → 2. "Take Quest" → 3. Contextual task (e.g., recycle 3 plastics) → 4. Success modal + streak | Drives habit formation; easily A/B tested. |
| | User‑Generated Challenges | 1. Community → 2. "Create Challenge" FAB → 3. Define goal + duration → 4. Invite friends → 5. Live leaderboard | Leverages network effects; moderation queue required. |

## Disposal Facilities Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Disposal Facilities** | Facilities Browser | 1. Home → 2. Quick Actions → 3. Disposal Facilities → 4. Search & filter list → 5. Tap to view map/list toggle | Future: offline map, notifications (nearby drop-off) |
| | Facility Detail & Contribution | 1. Facility tile → 2. Detail screen with info, hours, materials → 3. "Suggest Edit" or "Report Closure" CTA → 4. Dynamic form modal | |
| | Contribution History | 1. Profile → 2. My Contributions tab → 3. Status list with color codes | |
| | Route Optimiser | 1. Facilities list → 2. "Plan Route" → 3. Map with draggable waypoints → 4. Save route → 5. Send to Google / Apple Maps | Reduces friction for multiple drop‑offs; upsell to pro tier with unlimited stops. |

## Educational Content Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Educational Content** | Learn & Help | 1. Home → 2. Educational tab → 3. Category grid (Articles, Videos, Quizzes…) → 4. Content list & detail | Future: personalized daily tip push |
| | Quizzes & Knowledge Checks | 1. Tap Quiz → 2. Questions flow → 3. Feedback & scoring → 4. Badge / points award | |
| | Interactive AR Quiz | 1. Tap Quiz → 2. "Start AR Mode" → 3. Point at item → 4. Answer question overlay → 5. Score | Blends learning with real‑world items; increases dwell time. |

## Notifications & Settings Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Notifications & Settings** | Notification Preferences | 1. Settings → 2. Notifications → 3. Toggle types (Tips, Reminders, Community) → 4. Preview sample push | |
| | Reminders & Alerts | 1. Receive daily tip / streak reminder → 2. Tap notification → deep-link to relevant screen | |
| | Smart Notification Bundles | 1. Settings → 2. "Digest vs. Real‑time" toggle → 3. Preview schedule | Reduces notification fatigue; uses preference quiz data. |

## Credits & Payments Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Credits & Payments** | Credits Wallet | 1. Profile → 2. Credits tab → 3. Display balance + history → 4. Tap "Buy Credits" → Payment flow | Future: UPI integration, Razorpay, QR |
| | Paywall / Upsell | 1. Attempt pro feature → 2. Show modal with benefits + "Upgrade" CTA → 3. Payment flow | |
| | Referral Rewards | 1. Profile → 2. "Invite & Earn" → 3. Share link/QR → 4. New user signs up → 5. Both credited | Proven growth loop (drop‑in with Branch.io / Firebase DL). |
| | Carbon Offset Marketplace | 1. Credits tab → 2. "Buy Offsets" → 3. Choose project → 4. Payment → 5. Certificate screen | Extends mission beyond recycling; potential revenue share with NGOs. |

## Voice & Multilingual Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Voice & Multilingual** | Voice Classification | 1. Home → 2. Tap "Voice" icon → 3. Overlay with waveform + language picker → 4. Speak item name → 5. Show classification result | Support Hindi / Kannada / English toggles |
| | Real‑time Voice Coaching | 1. Voice overlay → 2. Continuous listen → 3. Immediate verbal guidance ("Plastic code #5 – recycle") | Hands‑free UX for visually impaired or gloved users. |

## User & Family Management Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **User & Family Management** | Profile & Settings | 1. Profile icon → 2. Profile screen (name, email, photo) → 3. Edit fields | |
| | Family/Team Onboarding | 1. Profile → 2. "Manage Family" → 3. Invite member (email/link/QR) → 4. Accept invitation | Shared stats, collaborative challenges |
| | Child Account / Parental Controls | 1. Manage Family → 2. "Add Child Profile" → 3. Simplified UI + restricted community access | Opens K‑12 education segment; COPPA/GDPR‑K compliant. |

## Admin & Developer Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Admin & Developer** | Admin Dashboard (Web) | 1. Login (2FA) → 2. Overview → 3. Drill-down modules (Users, Content, Analytics) | |
| | Storybook/Widgetbook Previews | 1. PR triggers → 2. Visual diff snapshots for each component → 3. Approve/Reject | |
| | Feature‑Flag Console | 1. Admin Web → 2. Experiments → 3. Toggle flags per cohort → 4. Roll‑out % slider | Enables gradual releases; integrates with LaunchDarkly / Firebase RC. |

## Support & Feedback Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Support & Feedback** | In‑App Chatbot & FAQ | 1. Settings → 2. "Help & Chat" → 3. GPT‑powered chat → 4. Escalate to human → 5. Ticket status list | Off‑loads 80% of Tier‑1 queries; logs issues for product team. |

## Data & Privacy Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Data & Privacy** | Data Download / Delete (GDPR) | 1. Settings → 2. Privacy → 3. "Export My Data" or "Delete My Account" → 4. Email link + confirmation | Mandatory for EU expansion; builds trust globally. |

## Accessibility Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Accessibility** | VoiceOver & TalkBack Audit Flow | 1. Toggle Accessibility inspector → 2. Step through each screen → 3. Annotated report | Ensures WCAG 2.2 AA compliance; forms baseline for automated audits. |

## Reliability / Offline Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Reliability / Offline** | Offline Scan Queue | 1. Airplane mode → 2. Capture scan → 3. "Queued" badge in History → 4. Auto‑upload on reconnect | Critical for field workers and rural areas. |

## Cross‑Device / Web Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Cross‑Device / Web** | Desktop Dashboard Sync | 1. Login web → 2. View synced History, Reports, Achievements → 3. Drag‑drop file for analysis → 4. Result synced back to mobile | Appeals to corporate sustainability officers & power users. |

---

## Additional Advanced User Flows

| **Category** | **Flow Name** | **Steps / Screens** | **Notes / Future Extensions** |
|--------------|---------------|-------------------|------------------------------|
| **Smart Home Integration** | IoT Bin Monitoring | 1. Settings → 2. "Connect Smart Bin" → 3. QR scan / Bluetooth pairing → 4. Real-time fill level dashboard → 5. Auto-schedule pickup notifications | Integrates with smart waste bins, weight sensors, and municipal pickup systems. |
| | Alexa/Google Assistant Integration | 1. Voice command "Hey Google, classify this item" → 2. App opens with voice mode → 3. Speak item name → 4. Audio response with disposal instructions | Hands-free operation for kitchen/garage use. |
| **Circular Economy** | Item Lifecycle Tracking | 1. Scan item → 2. "Track Lifecycle" → 3. Register item with blockchain ID → 4. Track through recycling/upcycling → 5. Impact visualization | Enables true circular economy tracking with blockchain verification. |
| | Upcycling Marketplace | 1. Scan item → 2. "Find Upcycling Ideas" → 3. Browse DIY projects → 4. Purchase materials → 5. Share completed project | Connects users with creative reuse opportunities and local makers. |
| **Corporate & B2B** | Enterprise Waste Audit | 1. Admin login → 2. "Start Audit" → 3. Bulk scan mode → 4. Generate compliance report → 5. Export to ERP systems | For corporate sustainability reporting and compliance. |
| | Supplier Sustainability Scoring | 1. Scan product → 2. "View Supplier Score" → 3. Sustainability metrics dashboard → 4. Alternative product suggestions | Helps businesses make sustainable procurement decisions. |
| **Social Impact** | Community Cleanup Events | 1. Community tab → 2. "Organize Cleanup" → 3. Set location/date → 4. Invite participants → 5. Live tracking dashboard → 6. Impact celebration | Facilitates local environmental action and community building. |
| | School Program Integration | 1. Teacher dashboard → 2. "Create Class Challenge" → 3. Student progress tracking → 4. Curriculum integration → 5. Parent reports | Educational tool for environmental awareness in schools. |
| **Advanced AI Features** | Predictive Waste Analytics | 1. History analysis → 2. "View Predictions" → 3. Seasonal waste patterns → 4. Optimization suggestions → 5. Calendar integration | Uses ML to predict waste patterns and optimize disposal schedules. |
| | Computer Vision Training | 1. Scan unclear item → 2. "Help Train AI" → 3. Multiple angle capture → 4. Expert verification → 5. Model improvement feedback | Crowdsourced AI training for better classification accuracy. |
| **Health & Safety** | Hazardous Material Detection | 1. Scan item → 2. Hazard warning overlay → 3. Safety instructions → 4. Professional disposal booking → 5. Compliance documentation | Identifies dangerous materials and guides safe disposal. |
| | Contamination Prevention | 1. Batch scan → 2. Cross-contamination analysis → 3. Sorting recommendations → 4. Quality score → 5. Improvement tips | Prevents recycling contamination through intelligent sorting guidance. |
| **Location-Based Services** | Geo-fenced Disposal Reminders | 1. Pass by recycling center → 2. Auto-notification with queued items → 3. Navigation to facility → 4. Check-in confirmation → 5. Impact update | Location-aware reminders for optimal disposal timing. |
| | Regional Compliance Checker | 1. Travel to new location → 2. Auto-detect local regulations → 3. Updated disposal guidelines → 4. Local facility recommendations | Adapts to local waste management rules and facilities. |
| **Wearable Integration** | Smartwatch Quick Scan | 1. Raise wrist → 2. "Scan" voice command → 3. Phone camera activation → 4. Result on watch display → 5. Quick action buttons | Seamless integration with Apple Watch/Wear OS for quick access. |
| **Blockchain & Web3** | NFT Impact Certificates | 1. Reach milestone → 2. "Mint Certificate" → 3. Blockchain verification → 4. NFT gallery → 5. Social sharing | Gamifies environmental impact with verifiable digital certificates. |
| | Carbon Credit Trading | 1. Impact dashboard → 2. "Convert to Credits" → 3. Marketplace listing → 4. Trade execution → 5. Wallet integration | Enables users to monetize their environmental impact. |
| **Mental Health & Wellness** | Eco-Anxiety Support | 1. Mood tracking → 2. Environmental impact correlation → 3. Positive action suggestions → 4. Community support groups → 5. Professional resources | Addresses climate anxiety through positive environmental action. |
| **Advanced Personalization** | AI Lifestyle Coach | 1. Behavior analysis → 2. Personalized recommendations → 3. Habit formation tracking → 4. Adaptive challenges → 5. Long-term goal setting | Uses AI to provide personalized sustainability coaching. |
| | Dynamic UI Adaptation | 1. Usage pattern analysis → 2. Interface optimization → 3. Feature prioritization → 4. Accessibility adjustments → 5. Performance optimization | Adapts UI based on individual usage patterns and needs. |

---

## How to Use This Document

1. **Flow diagrams** – Extend your current Mermaid or Whimsical files; one swim‑lane per flow for mobile, server, and external services.
2. **Wireframes** – Prioritise by impact: start with *Batch Scan* and *Daily Eco‑Quests* (highest engagement lift).
3. **Agent tasks** – Example tickets for your AI‑assistant pipeline:
   * "Draft PWA install prompt copy & graphic (stable‑diffusion seed #1234)."
   * "Generate voice‑over script variations for Personalisation Quiz (EN/HIN/KAN)."
   * "Write Cypress spec: Offline Scan Queue → reconnect → assert POST /classify fired."

Add these rows to your backlog sheet, tag them `future+`, and score with RICE to decide which sprints they land in. 