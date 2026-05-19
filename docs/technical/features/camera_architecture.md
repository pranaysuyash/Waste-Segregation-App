# Camera Architecture

* Status: current implementation + aspirational notes from stash 7
* Source: Current `lib/widgets/platform_camera.dart` + stash 7 `CLAUDE.md` notes
* Last updated: 2025-06-20

---

## Current Implementation

The app uses a **multi-approach camera architecture** with graceful fallbacks across platforms.

### Core File: `lib/widgets/platform_camera.dart`

The `PlatformCamera` class provides static utility methods:

| Method | Description |
|--------|-------------|
| `setup()` | Check/request camera permissions |
| `takePicture()` | Capture image via `image_picker` (max 1200×1200, quality 85) |
| `cleanup()` | Dispose camera resources (currently no-op) |
| `isCameraAvailable()` | Check if camera permission is available |

### Current Approach

- **All platforms**: Uses `image_picker` package for camera capture
- **Web**: `image_picker` only (no direct camera preview)
- **Android/iOS**: `image_picker` + `permission_handler` for permissions
- **Desktop**: Limited support, falls back to `image_picker` dialog

### Dependencies

```yaml
camera: ^0.10.5+9          # Installed but not directly used yet
permission_handler: ^11.2.0  # Used for camera permissions
image_picker: ^1.0.7         # Primary capture mechanism
image_picker_for_web: ^3.0.1 # Web support
```

---

## Aspirational: Direct Camera API (from stash 7)

Stash 7 contained a more advanced `PlatformCamera` with direct camera integration using the `camera` package. These changes were **not merged** but are preserved here for future reference.

### What stash 7 Added

- **`CameraController` field** — Direct control over camera hardware
- **`availableCameras()`** — List available cameras (front/back)
- **`getCameraPreview()`** — Widget-based camera preview
- **`takePicture()`** — Direct camera API with `image_picker` fallback
- **`isCameraAvailable()`** — Emulator detection + permission check
- **`start()`/`stop()`** — Lifecycle management for camera preview

### Files That Would Change

| File | Change |
|------|--------|
| `lib/widgets/platform_camera.dart` | Add `CameraController`, preview methods |
| `lib/widgets/enhanced_camera.dart` | New widget with preview + capture UI |
| `lib/screens/camera_screen.dart` | Full-screen camera experience |
| `lib/main.dart` | Camera background initialization |

### Why Not Merged

1. The `camera` package (^0.10.x) has platform-specific issues that need testing
2. Adding direct camera API increases complexity without clear UX benefit over `image_picker`
3. The stash 7 version was incompatible with current code structure
4. Web support for direct camera requires different approach

---

## Future Direction

When ready to implement direct camera API:

1. **Upgrade `camera` package** to latest stable
2. **Test on real devices** — emulators don't support CameraController well
3. **Fallback strategy**: Direct camera → `image_picker` → file picker
4. **Permissions**: Already handled via `permission_handler`
5. **PlatformCamera** should remain the single entry point — all camera access goes through it

### Decision Points

- [ ] Do we need camera preview before capture, or is basic image_picker sufficient?
- [ ] Share vs. privacy: should images be processed locally first?
- [ ] Web strategy: browser APIs vs. existing image_picker_for_web?
- [ ] Desktop: skip camera entirely or add platform-specific support?

---

## Links

* Source stash: `stash@{7}` (direct camera API — never merged)
* Current file: `lib/widgets/platform_camera.dart`
* Related: `docs/planning/roadmap/SOCIAL_GAMIFICATION.md` (same stash)
* Dependencies: `camera`, `permission_handler`, `image_picker` in `pubspec.yaml`
