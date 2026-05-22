import 'package:flutter/material.dart';

class PremiumLockWrapper extends StatelessWidget {
  const PremiumLockWrapper({
    required this.child,
    required this.isLocked,
    this.lockedOverlayMessage,
    super.key,
  });

  final Widget child;
  final bool isLocked;
  final String? lockedOverlayMessage;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: AbsorbPointer(
            absorbing: true,
            child: child,
          ),
        ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      size: 16,
                      color: Colors.white,
                      semanticLabel: 'Premium feature',
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        lockedOverlayMessage ?? 'Premium feature',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
