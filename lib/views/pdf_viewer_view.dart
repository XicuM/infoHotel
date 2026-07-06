import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../widgets/app_bar_widget.dart';
import '../config/app_config.dart';
import '../widgets/zoomable_viewer.dart';
import '../widgets/app_image.dart';
import '../utils/path_resolver.dart';
import '../utils/pdf_disk_cache.dart';

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
      PdfDocument document;
      if (kIsWeb) {
        document = await PdfDocument.openAsset(widget.pdfPath);
      } else if (!widget.isLocal && widget.pdfPath.startsWith('hotel_assets/')) {
        document = await PdfDocument.openAsset(widget.pdfPath);
      } else {
        document = await PdfDocument.openFile(
          widget.isLocal ? widget.pdfPath : PathResolver.resolve(widget.pdfPath)
        );
      }

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
      return Center(child: AppConfig.lowPowerMode 
          ? const Icon(Icons.hourglass_empty, color: Colors.white, size: 36) 
          : const CircularProgressIndicator(color: Colors.white));
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
                                  pdfPath: widget.pdfPath,
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
                                    pdfPath: widget.pdfPath,
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
                      pdfPath: widget.pdfPath,
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
  final String pdfPath;
  final int pageNumber;
  final bool isLeft;
  final bool isRight;

  const _PdfPageRenderer({
    required this.document, 
    required this.pdfPath,
    required this.pageNumber,
    this.isLeft = false,
    this.isRight = false,
  });

  @override
  State<_PdfPageRenderer> createState() => _PdfPageRendererState();
}

class _PdfPageRendererState extends State<_PdfPageRenderer> {
  Uint8List? _imageBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _renderPage();
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
    setState(() {
      _imageBytes = null; // Release previous page image bytes to save memory immediately
      _loading = true;
    });
    
    try {
      final cachedBytes = await PdfDiskCache.get(widget.pdfPath, widget.pageNumber);
      if (cachedBytes != null) {
        if (mounted) {
          setState(() {
            _imageBytes = cachedBytes;
            _loading = false;
          });
        }
        return;
      }

      final page = await widget.document.getPage(widget.pageNumber);
      final scaleMultiplier = AppConfig.lowPowerMode ? 1.0 : 1.5;
      final pageImage = await page.render(
        width: page.width * scaleMultiplier,
        height: page.height * scaleMultiplier,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();
      
      if (pageImage != null) {
        final bytesToCache = pageImage.bytes;
        // Run cache put asynchronously without awaiting so UI renders immediately
        PdfDiskCache.put(widget.pdfPath, widget.pageNumber, bytesToCache);
        
        if (mounted) {
          setState(() {
            _imageBytes = bytesToCache;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error rendering page ${widget.pageNumber}: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: AppConfig.lowPowerMode 
          ? const Icon(Icons.hourglass_empty, color: Colors.white, size: 36) 
          : const CircularProgressIndicator(color: Colors.white));
    }
    
    if (_imageBytes == null) {
      return const Center(child: Icon(Icons.broken_image, color: Colors.white));
    }

    return Stack(
      children: [
        AppImage(
          bytes: _imageBytes!,
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
