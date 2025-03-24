// Platform-agnostic web utilities
// This file imports the appropriate implementation based on the platform

import 'package:flutter/foundation.dart';

// Use conditional exports based on the platform
export 'web_impl.dart' if (dart.library.io) 'web_stubs.dart';