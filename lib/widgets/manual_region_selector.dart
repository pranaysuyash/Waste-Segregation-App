import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Data class representing a manually selected rectangular region.
/// Coordinates are normalized to [0.0, 1.0] relative to the image dimensions.
class SelectedRegion {
  SelectedRegion({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final int id;
  final double left; // 0.0 - 1.0
  final double top; // 0.0 - 1.0
  final double width; // 0.0 - 1.0
  final double height; // 0.0 - 1.0

  double get right => (left + width).clamp(0.0, 1.0);
  double get bottom => (top + height).clamp(0.0, 1.0);

  Map<String, dynamic> toBoundsMap() => <String, dynamic>{
        'x': left * 100,
        'y': top * 100,
        'width': width * 100,
        'height': height * 100,
      };
}

/// Widget that lets a user draw rectangular regions on an image.
///
/// MVP constraints:
/// - Rectangular crop only.
/// - Max 3 regions.
/// - No automatic segmentation.
/// - No fake confidence/object labels.
class ManualRegionSelector extends StatefulWidget {
  const ManualRegionSelector({
    super.key,
    this.imageFile,
    this.webImageBytes,
    required this.maxRegions,
    required this.onRegionsChanged,
    this.onConfirm,
  });

  final File? imageFile;
  final Uint8List? webImageBytes;
  final int maxRegions;
  final ValueChanged<List<SelectedRegion>> onRegionsChanged;
  final VoidCallback? onConfirm;

  @override
  State<ManualRegionSelector> createState() => _ManualRegionSelectorState();
}

class _ManualRegionSelectorState extends State<ManualRegionSelector> {
  final List<SelectedRegion> _regions = [];
  int _nextId = 1;

  // Drag state
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _isDragging = false;

  // Image render size tracking
  Size? _imageRenderSize;

  void _removeRegion(int id) {
    setState(() {
      _regions.removeWhere((r) => r.id == id);
    });
    widget.onRegionsChanged(List.unmodifiable(_regions));
  }

  void _clearRegions() {
    setState(() {
      _regions.clear();
    });
    widget.onRegionsChanged(List.unmodifiable(_regions));
  }

  void _onPanStart(DragStartDetails details, Size imageSize) {
    if (_regions.length >= widget.maxRegions) return;
    setState(() {
      _isDragging = true;
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size imageSize) {
    if (!_isDragging) return;
    setState(() {
      _dragCurrent = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details, Size imageSize) {
    if (!_isDragging || _dragStart == null || _dragCurrent == null) {
      setState(() {
        _isDragging = false;
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }

    final dx = _dragCurrent!.dx - _dragStart!.dx;
    final dy = _dragCurrent!.dy - _dragStart!.dy;

    // Ignore tiny accidental taps
    if (dx.abs() < 12 && dy.abs() < 12) {
      setState(() {
        _isDragging = false;
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }

    final left = min(_dragStart!.dx, _dragCurrent!.dx) / imageSize.width;
    final top = min(_dragStart!.dy, _dragCurrent!.dy) / imageSize.height;
    final width = dx.abs() / imageSize.width;
    final height = dy.abs() / imageSize.height;

    final clampedLeft = left.clamp(0.0, 1.0);
    final clampedTop = top.clamp(0.0, 1.0);
    final clampedWidth = width.clamp(0.0, 1.0 - clampedLeft);
    final clampedHeight = height.clamp(0.0, 1.0 - clampedTop);

    // Ignore tiny regions
    if (clampedWidth * clampedHeight < 0.005) {
      setState(() {
        _isDragging = false;
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }

    final newRegion = SelectedRegion(
      id: _nextId++,
      left: clampedLeft,
      top: clampedTop,
      width: clampedWidth,
      height: clampedHeight,
    );

    setState(() {
      _isDragging = false;
      _dragStart = null;
      _dragCurrent = null;
      _regions.add(newRegion);
    });
    widget.onRegionsChanged(List.unmodifiable(_regions));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Image layer
            Positioned.fill(
              child: _buildImage(),
            ),
            // Gesture + overlay layer sized to image
            Positioned.fill(
              child: _buildInteractiveOverlay(constraints.biggest),
            ),
            // Instruction / controls overlay
            if (_regions.isEmpty && !_isDragging)
              _buildInstructionOverlay(),
            // Region count chip
            if (_regions.isNotEmpty)
              _buildRegionCountChip(),
          ],
        );
      },
    );
  }

  Widget _buildImage() {
    late final Widget imageWidget;
    if (kIsWeb) {
      if (widget.webImageBytes != null) {
        imageWidget = Image.memory(
          widget.webImageBytes!,
          fit: BoxFit.contain,
        );
      } else {
        imageWidget = const Center(child: CircularProgressIndicator());
      }
    } else {
      if (widget.imageFile != null) {
        imageWidget = Image.file(
          widget.imageFile!,
          fit: BoxFit.contain,
        );
      } else {
        imageWidget = const Center(child: CircularProgressIndicator());
      }
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _imageRenderSize = constraints.biggest;
              return Stack(
                fit: StackFit.expand,
                children: [Center(child: imageWidget)],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveOverlay(Size stackSize) {
    // We need the actual image render size from the inner LayoutBuilder.
    // If not available yet, use a fallback that fills the space.
    final imageSize = _imageRenderSize ?? stackSize;

    return GestureDetector(
      onPanStart: (details) => _onPanStart(details, imageSize),
      onPanUpdate: (details) => _onPanUpdate(details, imageSize),
      onPanEnd: (details) => _onPanEnd(details, imageSize),
      onPanCancel: () {
        setState(() {
          _isDragging = false;
          _dragStart = null;
          _dragCurrent = null;
        });
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Existing regions
            ..._regions.map((region) => _buildRegionBox(region, imageSize)),
            // Active drag preview
            if (_isDragging && _dragStart != null && _dragCurrent != null)
              _buildDragPreview(imageSize),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionBox(SelectedRegion region, Size imageSize) {
    final left = region.left * imageSize.width;
    final top = region.top * imageSize.height;
    final width = region.width * imageSize.width;
    final height = region.height * imageSize.height;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.teal,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeRegion(region.id),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Region number badge
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Item ${_regions.indexOf(region) + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragPreview(Size imageSize) {
    final left = min(_dragStart!.dx, _dragCurrent!.dx);
    final top = min(_dragStart!.dy, _dragCurrent!.dy);
    final width = (_dragCurrent!.dx - _dragStart!.dx).abs();
    final height = (_dragCurrent!.dy - _dragStart!.dy).abs();

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.12),
          border: Border.all(
            color: Colors.teal.withValues(alpha: 0.8),
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildInstructionOverlay() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.touch_app,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Draw a rectangle around each item you want to classify. Max ${widget.maxRegions}.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionCountChip() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_regions.length} / ${widget.maxRegions}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_regions.length == widget.maxRegions) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
