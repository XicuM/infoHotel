import 'dart:io';
import 'package:flutter/foundation.dart';

Future<bool> hasPdfSupport() async {
  if (kIsWeb) return true;
  return Platform.isMacOS ||
      Platform.isIOS ||
      Platform.isWindows ||
      Platform.isAndroid ||
      Platform.isLinux;
}
