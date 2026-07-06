import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../services/hotel_service.dart';
import '../services/content_service.dart';
import 'help_popup.dart';

class KioskManager extends StatefulWidget {
  final Widget child;

  const KioskManager({super.key, required this.child});

  @override
  State<KioskManager> createState() => _KioskManagerState();
}

class _KioskManagerState extends State<KioskManager> {
  final FocusNode _focusNode = FocusNode();
  bool _showHelp = false;
  bool _cursorVisible = kDebugMode;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotelService = Provider.of<HotelService>(context, listen: false);
    final contentService = Provider.of<ContentService>(context, listen: false);

    if (!_focusNode.hasFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
    }

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final isAltPressed = HardwareKeyboard.instance.isAltPressed;
          
          if (isAltPressed && event.logicalKey == LogicalKeyboardKey.keyT) {
            hotelService.cycleNextHotel();
          } else if (isAltPressed && event.logicalKey == LogicalKeyboardKey.keyS) {
            hotelService.setHotel('Savines');
          } else if (isAltPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
            hotelService.setHotel('Arenal');
          } else if (event.logicalKey == LogicalKeyboardKey.f11) {
            windowManager.isFullScreen().then((isFullScreen) async {
              bool willBeFullScreen = !isFullScreen;
              await windowManager.setFullScreen(willBeFullScreen);
              await windowManager.setTitleBarStyle(
                willBeFullScreen ? TitleBarStyle.hidden : TitleBarStyle.normal,
              );
            });
          } else if (event.logicalKey == LogicalKeyboardKey.f2) {
            contentService.toggleEditMode();
          } else if (isAltPressed && event.logicalKey == LogicalKeyboardKey.keyM) {
            setState(() {
              _cursorVisible = !_cursorVisible;
            });
          } else if (isAltPressed && event.logicalKey == LogicalKeyboardKey.keyH) {
             setState(() {
               _showHelp = !_showHelp;
             });
           }
        }
      },
      child: MouseRegion(
        cursor: _cursorVisible ? SystemMouseCursors.basic : SystemMouseCursors.none,
        child: Stack(
          children: [
            widget.child,
            if (_showHelp)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showHelp = false),
                  child: Container(
                    color: Colors.black38,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // prevent closing when tapping the popup
                        child: const HelpPopup(),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
