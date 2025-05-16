# Glossary of Terms

This document provides definitions for key terms used in the Waste Segregation App documentation and user interface.

## Waste Classification Terms

### Waste Categories
- **Wet Waste**: Biodegradable waste that can be composted, including food waste, plant materials, and some paper products. Characterized by high moisture content.
- **Dry Waste**: Non-biodegradable waste that is potentially recyclable, including plastics, glass, metals, and paper.
- **Hazardous Waste**: Waste that poses substantial or potential threats to public health or the environment, requiring special handling and disposal.
- **Medical Waste**: Waste generated from healthcare activities that may contain infectious agents, toxic chemicals, or radioactive materials.
- **Non-Waste**: Items that should be reused, repaired, or repurposed rather than discarded.

### Material Properties
- **Recyclable**: Materials that can be processed and used to create new products, reducing the consumption of fresh raw materials.
- **Compostable**: Materials that can biodegrade into nutrient-rich soil amendment under specific conditions.
- **Biodegradable**: Materials that can be broken down naturally by microorganisms into simpler substances.

### Recycling Codes
- **Code 1 (PET/PETE)**: Polyethylene Terephthalate - common in beverage bottles and food containers.
- **Code 2 (HDPE)**: High-Density Polyethylene - used in milk jugs, detergent bottles, and toys.
- **Code 3 (PVC)**: Polyvinyl Chloride - found in pipes, shower curtains, and some food wraps.
- **Code 4 (LDPE)**: Low-Density Polyethylene - used in shopping bags and food wrap.
- **Code 5 (PP)**: Polypropylene - common in yogurt containers, bottle caps, and straws.
- **Code 6 (PS)**: Polystyrene - used in foam cups, packaging peanuts, and disposable cutlery.
- **Code 7 (Other)**: Miscellaneous plastics including polycarbonate and bioplastics.

## Technical Terms

### AI & Image Processing
- **Perceptual Hash**: A fingerprint of visual media derived from its features, allowing similar images to have similar hashes.
- **Segmentation**: The process of dividing an image into multiple segments to simplify analysis, allowing identification of multiple objects in a single image.
- **SAM (Segment Anything Model)**: An advanced AI model used to identify and separate distinct objects within an image.
- **GluonCV**: A deep learning toolkit that provides implementations for state-of-the-art computer vision algorithms.
- **Classification Confidence**: A percentage indicating how certain the AI is about a particular classification result.
- **Auto-Segmentation**: Automatic detection and separation of multiple objects in an image without user input.
- **Interactive Segmentation**: User-guided process of selecting specific objects or regions in an image for targeted analysis.
- **Component Analysis**: Breaking down a complex item into its constituent materials or parts for separate classification.

### Data Storage
- **Hive**: A lightweight, key-value database implementation in Flutter used for local storage in the app.
- **LRU (Least Recently Used)**: A caching policy that discards the least recently used items first when cache capacity is reached.
- **Perceptual Hashing**: A technique that generates similar hash values for visually similar images, used for efficient cache lookup.

### Gamification
- **Daily Streak**: The number of consecutive days a user has performed a specific action (e.g., classifying at least one item).
- **Achievement**: A specific accomplishment or milestone recognized by the app, typically rewarded with points or badges.
- **Challenge**: A time-limited task with specific goals and rewards.
- **Badge**: A visual representation of an achievement, often with multiple tiers (e.g., Bronze, Silver, Gold).
- **Points**: The basic unit of measurement for user progress and achievements in the gamification system.
- **Rank**: A title given to users based on their progress and points (e.g., "Waste Novice", "Waste Warrior").

### Educational Content
- **Article**: Text-based educational content with optional images.
- **Infographic**: Visual representation of information or data designed to make complex information quickly and easily understood.
- **Tutorial**: Step-by-step guide teaching users how to perform specific waste-related tasks.
- **Quiz**: Interactive question-and-answer format to test user knowledge.
- **Daily Tip**: Brief, informative fact or suggestion shown on the home screen, changing daily.

## Subscription & Business Terms

### Subscription Tiers
- **Free Tier**: Basic app functionality with ad support, limited to single-object classification.
- **Premium Tier** (Eco-Plus): Mid-level subscription offering automatic multi-object segmentation and limited offline capabilities.
- **Pro Tier** (Eco-Master): Top-level subscription with interactive segmentation, component analysis, and comprehensive offline functionality.

### Feature Types
- **Core Features**: Basic functionality available to all users regardless of subscription status.
- **Premium Features**: Enhanced capabilities only available to Premium and Pro subscribers.
- **Pro Features**: Advanced capabilities exclusive to Pro tier subscribers.

### Monetization Terms
- **Conversion Rate**: The percentage of users who upgrade from a free to a paid subscription.
- **ARPU (Average Revenue Per User)**: The average revenue generated per user, including both free and paid users.
- **LTV (Lifetime Value)**: The total revenue expected from a user throughout their relationship with the app.
- **Churn Rate**: The percentage of subscribers who cancel their subscription within a given time period.

## Technical Implementation Terms

### Flutter & Dart
- **Widget**: The basic building block of Flutter UI, representing an immutable description of part of the user interface.
- **State**: Information that can be read synchronously when a widget is built and might change during the lifetime of the widget.
- **Provider**: A state management solution in Flutter used to efficiently pass data down the widget tree.
- **Service**: A class responsible for a specific type of functionality, like network requests or local storage.

### System Components
- **AIService**: The component responsible for handling image classification requests, including API calls and result processing.
- **SegmentationManager**: The component that handles image segmentation, including model selection and user interactions.
- **CacheService**: The component that manages caching of classification results to improve performance and reduce API usage.
- **GamificationService**: The component that tracks and manages user points, achievements, and challenges.

### UI Components
- **ClassificationResultScreen**: The screen that displays detailed information about a classified waste item.
- **SegmentationControlsWidget**: UI component that provides tools for image segmentation based on the user's subscription tier.
- **PremiumFeatureBadge**: Visual indicator showing that a feature requires a premium subscription.
- **RewardAnimation**: Animation displayed when users earn points or achievements.

## Business Metrics

### User Engagement Metrics
- **DAU (Daily Active Users)**: Number of unique users who open the app each day.
- **MAU (Monthly Active Users)**: Number of unique users who open the app each month.
- **Session Length**: Average duration of an app session.
- **Classifications Per User**: Average number of waste items classified per user.

### Technical Performance Metrics
- **Classification Latency**: Time taken to classify an image from submission to result display.
- **Segmentation Accuracy**: Precision of object boundary detection in multi-object scenes.
- **Cache Hit Rate**: Percentage of classification requests served from cache vs. new API calls.
- **API Cost Per User**: Average cost of API calls per user, important for profitability analysis.

## Cloud Services

### Firebase Services
- **Firebase Authentication**: Service for user authentication and identity management.
- **Firebase Functions**: Serverless computing service for backend operations.
- **Firebase Remote Config**: Service for remotely changing app behavior without requiring updates.
- **Firebase Analytics**: Service for tracking user behavior and app performance.

### AI APIs
- **Gemini Vision API**: Google's multimodal AI service used for primary image classification.
- **OpenAI API**: Alternative AI service used as a fallback for classification.
- **SAM API**: Segment Anything Model API for image segmentation.

## User Experience Terms

### Interaction Modes
- **Tap Interaction**: User taps on a specific point to select an object of interest.
- **Box Interaction**: User draws a bounding box around an object to select it.
- **Scribble Interaction**: User draws on the image to refine segment boundaries.

### UI States
- **Feature Lock**: Visual indication that a feature is unavailable in the current subscription tier.
- **Upgrade Prompt**: A message encouraging users to upgrade their subscription to access more features.
- **Feedback Loop**: Process where users can provide corrections to AI classifications.
