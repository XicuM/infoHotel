import 'dart:html' as html;

void updateWebCursor(bool isVisible) {
  final cursor = isVisible ? 'auto' : 'none';
  html.document.body?.style.cursor = cursor;
  final canvases = html.document.querySelectorAll('flt-canvas');
  for (final canvas in canvases) {
    (canvas as html.Element).style.cursor = cursor;
  }
}
