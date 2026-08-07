import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TerminalService {
  /// Launches a terminal emulator on the system.
  /// 
  /// In Web mode (e.g. Raspberry Pi kiosk), sends an API request to the backend server.
  /// In native desktop mode, spawns a terminal process using system commands.
  static Future<bool> launchTerminal() async {
    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse('/api/openTerminal'),
          headers: {'Content-Type': 'application/json'},
        );
        return response.statusCode == 200;
      } catch (e) {
        debugPrint('Error launching terminal via API: $e');
        return false;
      }
    } else if (Platform.isLinux) {
      final terminals = [
        'x-terminal-emulator',
        'lxterminal',
        'foot',
        'kitty',
        'alacritty',
        'gnome-terminal',
        'xfce4-terminal',
        'xterm',
      ];

      for (final term in terminals) {
        try {
          final result = await Process.start(term, []);
          if (result.pid > 0) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
      debugPrint('No supported terminal emulator found.');
      return false;
    }
    
    return false;
  }
}
