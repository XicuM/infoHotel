import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_bar_widget.dart';
import '../widgets/zoomable_viewer.dart';
import '../widgets/app_image.dart';

/// Simple image viewer with zoom support
class ImageViewerView extends StatefulWidget {
  final List<String> imagePaths;
  final String title;
  final Color backgroundColor;
  final String? parentRoute;

  const ImageViewerView({
    super.key,
    required this.imagePaths,
    required this.title,
    this.backgroundColor = Colors.blue,
    this.parentRoute,
  });

  @override
  State<ImageViewerView> createState() => _ImageViewerViewState();
}

class _ImageViewerViewState extends State<ImageViewerView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        titleKey: widget.title,
        backgroundColor: widget.backgroundColor,
        parentRoute: widget.parentRoute,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return ZoomableViewer(
                child: AppImage(
                  path: widget.imagePaths[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading image',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          if (widget.imagePaths.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imagePaths.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 10.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? widget.backgroundColor
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

