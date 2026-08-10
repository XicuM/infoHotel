import 'dart:js_interop';

@JS('setCursorVisible')
external void _setCursorVisible(bool visible);

void setWebCursorVisible(bool visible) {
  try {
    _setCursorVisible(visible);
  } catch (_) {}
}
