# AI and Machine Learning Documentation

## Recent Improvements

- **Web Camera Access**: Camera capture is now supported in the browser using `image_picker_for_web` (see `web_camera_access.dart`).
- **UI and Media Rendering**: Improved text overflow handling and media (video/image) rendering in educational content screens (see `result_screen.dart`, `content_detail_screen.dart`).
- **Centralized Error Handling**: Error handling is now standardized using `AppException` and `ErrorHandler` (see `constants.dart`).

This directory contains documentation related to the AI and machine learning components of the Waste Segregation App.

## Main Files

- [Multi-Model AI Strategy](./multi_model_ai_strategy.md): The primary source of truth for the app's multi-model AI approach, including architecture, fallback logic, and cost optimization.
- [Advanced AI Image Features](./advanced_ai_image_features.md): Details on advanced image recognition and segmentation features.
- [AI-Powered Image Segmentation](./ai_powered_image_segmentation.md): Technical details on segmentation models and their integration.
- [AI Model Management and Retraining Strategy](./ai_model_management_and_retraining_strategy.md): Strategy for maintaining, evaluating, and retraining AI models.

## Deprecated

- [AI Strategy & Multi-Model Integration](./ai_strategy_multimodel.md): Deprecated in favor of the unified multi_model_ai_strategy.md.

## Contribution

When updating or adding AI/ML features, please update the relevant documentation here and cross-link from the main architecture docs as needed. 