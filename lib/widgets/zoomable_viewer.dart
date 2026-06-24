import 'package:flutter/material.dart';

class ZoomableViewer extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const ZoomableViewer({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 5.0,
  });

  @override
  State<ZoomableViewer> createState() => _ZoomableViewerState();
}

class _ZoomableViewerState extends State<ZoomableViewer> {
  final TransformationController _controller = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransformationChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformationChange);
    _controller.dispose();
    super.dispose();
  }

  void _onTransformationChange() {
    final scale = _controller.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.01) {
      if (mounted) {
        setState(() {
          _currentScale = scale;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: widget.minScale,
            maxScale: widget.maxScale,
            boundaryMargin: const EdgeInsets.all(500), // Sufficiently large to allow panning
            trackpadScrollCausesScale: true,
            child: widget.child,
          ),
        ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_currentScale * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
    );
  }
}
