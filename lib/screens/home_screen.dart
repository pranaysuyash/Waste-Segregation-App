import 'package:flutter/material.dart';
import 'package:waste_segregation_app/screens/ultra_modern_home_screen.dart';

/// Canonical app home screen entrypoint.
///
/// We keep the legacy implementation in `ultra_modern_home_screen.dart`
/// for compatibility, but route/runtime code should depend on `HomeScreen`.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.isGuestMode = false,
  });

  final bool isGuestMode;

  @override
  Widget build(BuildContext context) {
    return UltraModernHomeScreen(isGuestMode: isGuestMode);
  }
}
