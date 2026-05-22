import 'dart:math';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/detected_waste_region.dart';

class _BoxData {
  _BoxData({required this.id, required this.box});
  final int id;
  final NormalizedBoundingBox box;
}

class ManualRegionSelector extends StatefulWidget {
  const ManualRegionSelector({
    super.key,
    this.imageFile,
    this.webImageBytes,
    this.initialRegions = const [],
    required this.maxRegions,
    required this.onRegionsChanged,
    this.onConfirm,
  });

  final File? imageFile;
  final Uint8List? webImageBytes;
  final List<NormalizedBoundingBox> initialRegions;
  final int maxRegions;
  final ValueChanged<List<NormalizedBoundingBox>> onRegionsChanged;
  final VoidCallback? onConfirm;

  @override
  State<ManualRegionSelector> createState() => _ManualRegionSelectorState();
}

class _ManualRegionSelectorState extends State<ManualRegionSelector> {
  final List<_BoxData> _regions = [];
  int _nextId = 1;

  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _isDragging = false;

  double _imageAspectRatio = 16 / 9;
  bool _dimensionsLoaded = false;
  bool _initialRegionsApplied = false;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  @override
  void didUpdateWidget(ManualRegionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageFile != oldWidget.imageFile ||
        widget.webImageBytes != oldWidget.webImageBytes) {
      setState(() {
        _dimensionsLoaded = false;
      });
      _loadImageDimensions();
    }
  }

  Future<void> _loadImageDimensions() async {
    try {
      if (kIsWeb) {
        if (widget.webImageBytes != null) {
          final decoded = await decodeImageFromList(widget.webImageBytes!);
          if (mounted) {
            setState(() {
              _imageAspectRatio = decoded.width / decoded.height;
              _dimensionsLoaded = true;
            });
            _applyInitialRegions();
          }
        } else {
          if (mounted) {
            setState(() {
              _imageAspectRatio = 1.0;
              _dimensionsLoaded = true;
            });
            _applyInitialRegions();
          }
        }
      } else if (widget.imageFile != null) {
        final bytes = await widget.imageFile!.readAsBytes();
        final decoded = await decodeImageFromList(bytes);
        if (mounted) {
          setState(() {
            _imageAspectRatio = decoded.width / decoded.height;
            _dimensionsLoaded = true;
          });
          _applyInitialRegions();
        }
      } else {
        if (mounted) {
          setState(() {
            _imageAspectRatio = 1.0;
            _dimensionsLoaded = true;
          });
          _applyInitialRegions();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageAspectRatio = 16 / 9;
          _dimensionsLoaded = true;
        });
        _applyInitialRegions();
      }
    }
  }

  void _applyInitialRegions() {
    if (_initialRegionsApplied || widget.initialRegions.isEmpty) return;
    _initialRegionsApplied = true;
    final regions = widget.initialRegions
        .map((box) => _BoxData(id: _nextId++, box: box))
        .toList();
    _regions
      ..clear()
      ..addAll(regions);
    widget.onRegionsChanged(List.unmodifiable(regionBoxes));
  }

  List<NormalizedBoundingBox> get regionBoxes =>
      _regions.map((d) => d.box).toList();

  void _removeRegion(int id) {
    setState(() {
      _regions.removeWhere((r) => r.id == id);
    });
    widget.onRegionsChanged(List.unmodifiable(regionBoxes));
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

    if (clampedWidth * clampedHeight < 0.005) {
      setState(() {
        _isDragging = false;
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }

    final newBox = NormalizedBoundingBox(
      left: clampedLeft,
      top: clampedTop,
      width: clampedWidth,
      height: clampedHeight,
    );

    setState(() {
      _isDragging = false;
      _dragStart = null;
      _dragCurrent = null;
      _regions.add(_BoxData(id: _nextId++, box: newBox));
    });
    widget.onRegionsChanged(List.unmodifiable(regionBoxes));
  }

  @override
  Widget build(BuildContext context) {
    if (!_dimensionsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _imageAspectRatio,
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    final imageSize = innerConstraints.biggest;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(),
                        _buildInteractiveOverlay(imageSize),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_regions.isEmpty && !_isDragging) _buildInstructionOverlay(),
            if (_regions.isNotEmpty) _buildRegionCountChip(),
          ],
        );
      },
    );
  }

  Widget _buildImage() {
    late final Widget imageWidget;
    if (kIsWeb) {
      if (widget.webImageBytes != null) {
        imageWidget = Image.memory(widget.webImageBytes!, fit: BoxFit.fill);
      } else {
        imageWidget = const Center(child: CircularProgressIndicator());
      }
    } else {
      if (widget.imageFile != null) {
        imageWidget = Image.file(widget.imageFile!, fit: BoxFit.fill);
      } else {
        imageWidget = const Center(child: CircularProgressIndicator());
      }
    }
    return imageWidget;
  }

  Widget _buildInteractiveOverlay(Size imageSize) {
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
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ..._regions.map((r) => _buildRegionBox(r, imageSize)),
            if (_isDragging && _dragStart != null && _dragCurrent != null)
              _buildDragPreview(imageSize),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionBox(_BoxData data, Size imageSize) {
    final box = data.box;
    final left = box.left * imageSize.width;
    final top = box.top * imageSize.height;
    final width = box.width * imageSize.width;
    final height = box.height * imageSize.height;

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
              border: Border.all(color: Colors.teal, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeRegion(data.id),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'Item ${_regions.indexOf(data) + 1}',
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
          border:
              Border.all(color: Colors.teal.withValues(alpha: 0.8), width: 2),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Drag to refine the area. Up to ${widget.maxRegions} regions.',
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
