# Data Storage Documentation

## Recent Improvements

- **Centralized Error Handling**: All major screens now use a centralized `ErrorHandler` and `AppException` pattern for consistent error logging and user feedback. See `constants.dart`.
- **Web Camera Access**: Camera capture is now supported in the browser using `image_picker_for_web` (see `web_camera_access.dart`).
- **UI and Media Rendering**: Improved text overflow handling and media (video/image) rendering in educational content screens (see `result_screen.dart`, `content_detail_screen.dart`).

## Main Files

- [Data Storage and Management](./data_storage_and_management.md): Core data storage architecture and best practices.
- [Enhanced Storage and Asset Management](./enhanced_storage_and_asset_management.md): Advanced strategies for optimizing storage and asset handling.
- [Data Migration Playbook](./data_migration_playbook.md): Guidelines and procedures for data migration. 