import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../utils/web_cursor.dart';

class CursorOverlay extends StatefulWidget {
  final Widget child;
  
  const CursorOverlay({super.key, required this.child});

  @override
  State<CursorOverlay> createState() => _CursorOverlayState();
}

class _CursorOverlayState extends State<CursorOverlay> {
  bool _isVisible = false;
  Offset _mousePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    if (kIsWeb) {
      Future.delayed(const Duration(milliseconds: 100), _updateWebCursor);
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    // We use Ctrl+M as requested, but also add F3 as a fallback in case
    // the OS/Window Manager is intercepting Ctrl+M (which is common on Linux).
    if (event is KeyDownEvent) {
      final isCtrlM = HardwareKeyboard.instance.isControlPressed && event.logicalKey == LogicalKeyboardKey.keyM;
      final isF3 = event.logicalKey == LogicalKeyboardKey.f3;
      
      if (isCtrlM || isF3) {
        setState(() {
          _isVisible = !_isVisible;
        });
        if (kIsWeb) _updateWebCursor();
        return true;
      }
    }
    return false;
  }

  void _updateWebCursor() {
    updateWebCursor(_isVisible);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The main app content, wrapped in a MouseRegion to track coordinates 
        // and force the system cursor to hide (so our custom one can take over, or basic one)
        Listener(
          onPointerHover: (e) => setState(() => _mousePosition = e.position),
          onPointerMove: (e) => setState(() => _mousePosition = e.position),
          child: MouseRegion(
            cursor: kIsWeb ? MouseCursor.defer : (_isVisible ? SystemMouseCursors.basic : SystemMouseCursors.none),
            child: widget.child,
          ),
        ),
        
        // 2. The Custom Software Cursor (Circle)
        if (_isVisible && !kIsWeb)
          Positioned(
            left: _mousePosition.dx - 12,
            top: _mousePosition.dy - 12,
            child: IgnorePointer(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.6),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
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
