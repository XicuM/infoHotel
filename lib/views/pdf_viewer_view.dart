import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../widgets/app_bar_widget.dart';
import '../config/theme.dart';
import '../widgets/zoomable_viewer.dart';
import '../widgets/app_image.dart';
import '../utils/path_resolver.dart';

/// PDF Viewer widget for displaying PDF brochures
/// Supports "book mode" (2 pages side-by-side) in landscape.
class PdfViewerView extends StatefulWidget {
  final String pdfPath;
  final String title;
  final Color backgroundColor;
  final bool enableBookMode;
  final bool initialPage;
  final bool isLocal;
  final String? logoPath;
  final bool isLogoLocal;

  const PdfViewerView({
    super.key,
    required this.pdfPath,
    required this.title,
    this.backgroundColor = const Color(0xFF7B1FA2), // Purple 700
    this.enableBookMode = true,
    this.initialPage = true,
    this.isLocal = false,
    this.logoPath,
    this.isLogoLocal = false,
  });

  @override
  State<PdfViewerView> createState() => _PdfViewerViewState();
}

class _PdfViewerViewState extends State<PdfViewerView> {
  PdfDocument? _document;
  bool _isLoading = true;
  String? _error;
  int _totalPages = 0;
  final PageController _pageController = PageController();
  int _currentSpreadIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final document = kIsWeb
          ? await PdfDocument.openAsset(widget.pdfPath)
          : await PdfDocument.openFile(widget.isLocal ? widget.pdfPath : PathResolver.resolve(widget.pdfPath));
      if (mounted) {
        setState(() {
          _document = document;
          _totalPages = document.pagesCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _document?.close();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent background as requested
      appBar: CustomAppBar(
        titleKey: widget.title,
        backgroundColor: widget.backgroundColor,
        parentRoute: '/excursions',
        logoPath: widget.logoPath,
        isLogoLocal: widget.isLogoLocal,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.white.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      );
    }

    if (_document == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine layout based on aspect ratio and settings
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final useBookMode = isLandscape && widget.enableBookMode && _totalPages > 1;
        final spreadCount = useBookMode ? (_totalPages / 2).ceil() : _totalPages;

        return Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: spreadCount,
              onPageChanged: (index) {
                setState(() {
                  _currentSpreadIndex = index;
                });
              },
              itemBuilder: (context, index) {
                if (useBookMode) {
                  // Book mode: 2 pages joined like a book
                  final firstPage = index * 2 + 1;
                  final secondPage = index * 2 + 2;
                  
                  return ZoomableViewer(
                    key: ValueKey('spread_$index'),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Left Page
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _PdfPageRenderer(
                                  document: _document!, 
                                  pageNumber: firstPage,
                                  isLeft: true,
                                ),
                              ),
                            ),
                            // Right Page
                            if (secondPage <= _totalPages)
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _PdfPageRenderer(
                                    document: _document!, 
                                    pageNumber: secondPage,
                                    isRight: true,
                                  ),
                                ),
                              )
                            else
                              // Placeholder to keep left page centered/properly sized
                              Flexible(child: Container(color: Colors.white10)),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Single page mode
                  return ZoomableViewer(
                    key: ValueKey('single_${index + 1}'),
                    child: _PdfPageRenderer(
                      document: _document!, 
                      pageNumber: index + 1,
                    ),
                  );
                }
              },
            ),

            // Navigation Controls
            if (spreadCount > 1) ...[
              // Previous Button
              if (_currentSpreadIndex > 0)
                Positioned(
                  left: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavButton(
                      icon: Icons.arrow_back_ios_new,
                      color: widget.backgroundColor,
                      onTap: () {
                        _pageController.jumpToPage(_currentSpreadIndex - 1);
                      },
                    ),
                  ),
                ),

              // Next Button
              if (_currentSpreadIndex < spreadCount - 1)
                Positioned(
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavButton(
                      icon: Icons.arrow_forward_ios,
                      color: widget.backgroundColor,
                      onTap: () {
                        _pageController.jumpToPage(_currentSpreadIndex + 1);
                      },
                    ),
                  ),
                ),

              // Page Indicator
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentSpreadIndex + 1} / $spreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PdfPageRenderer extends StatefulWidget {
  final PdfDocument document;
  final int pageNumber;
  final bool isLeft;
  final bool isRight;

  const _PdfPageRenderer({
    required this.document, 
    required this.pageNumber,
    this.isLeft = false,
    this.isRight = false,
  });

  @override
  State<_PdfPageRenderer> createState() => _PdfPageRendererState();
}

class _PdfPageRendererState extends State<_PdfPageRenderer> {
  PdfPageImage? _image;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Delay rendering slightly to allow page transition to complete smoothly
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _renderPage();
    });
  }

  @override
  void didUpdateWidget(covariant _PdfPageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _renderPage();
    }
  }

  Future<void> _renderPage() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    try {
      final page = await widget.document.getPage(widget.pageNumber);
      // Render at 1.5x instead of 2x to significantly improve rendering speed
      // while still keeping reasonable quality for zooming
      final pageImage = await page.render(
        width: page.width * 1.5,
        height: page.height * 1.5,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();
      
      if (mounted) {
        setState(() {
          _image = pageImage;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error rendering page ${widget.pageNumber}: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    if (_image == null) {
      return const Center(child: Icon(Icons.broken_image, color: Colors.white));
    }

    return Stack(
      children: [
        AppImage(
          bytes: _image!.bytes,
          fit: BoxFit.contain,
        ),
        // Spine shadow for book effect (only on left page for realism)
        if (widget.isLeft)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _NavButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
