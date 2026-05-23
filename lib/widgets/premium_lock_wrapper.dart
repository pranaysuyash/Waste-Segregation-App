import 'package:flutter/material.dart';

class PremiumLockWrapper extends StatelessWidget {
  const PremiumLockWrapper({
    required this.child,
    required this.isLocked,
    this.lockedOverlayMessage,
    this.absorbInteractions = true,
    super.key,
  });

  final Widget child;
  final bool isLocked;
  final String? lockedOverlayMessage;
  final bool absorbInteractions;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: AbsorbPointer(
            absorbing: absorbInteractions,
            child: child,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !absorbInteractions,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        size: 16,
                        color: Colors.white,
                        semanticLabel: 'Premium feature',
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          lockedOverlayMessage ?? 'Premium feature',
                          style: const TextStyle(
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
        ),
      ],
    );
  }
}
