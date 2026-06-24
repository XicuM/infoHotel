import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../l10n/translations.dart';

class LocalizedTextField extends StatefulWidget {
  final Map<String, String> localizedValues;
  final String defaultValue;
  final ValueChanged<Map<String, String>> onValuesChanged;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? maxLines;
  final FocusNode? focusNode;
  final bool enabled;

  const LocalizedTextField({
    super.key,
    required this.localizedValues,
    required this.defaultValue,
    required this.onValuesChanged,
    this.style,
    this.decoration,
    this.maxLines = 1,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<LocalizedTextField> createState() => _LocalizedTextFieldState();
}

class _LocalizedTextFieldState extends State<LocalizedTextField> {
  late TextEditingController _controller;
  late Map<String, String> _currentValues;
  String? _lastLanguage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _currentValues = Map.from(widget.localizedValues);
  }

  @override
  void didUpdateWidget(LocalizedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.defaultValue != oldWidget.defaultValue) {
      // Re-initialize if the underlying data reference changes (e.g. different market selected)
      // Note: checking localizedValues equality is hard, but usually if defaultValue (id-based) changes, the item changed.
       _currentValues = Map.from(widget.localizedValues);
       _lastLanguage = null; // Force reload
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getTextForLang(String lang) {
    if (_currentValues.containsKey(lang) && _currentValues[lang]!.isNotEmpty) {
      return _currentValues[lang]!;
    }
    // Fallback behavior: translate the default value if it's a key
    return Translations.get(widget.defaultValue, lang);
  }

  void _onTextChanged(String value, String lang) {
    _currentValues[lang] = value;
    widget.onValuesChanged(_currentValues);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        final currentLang = langService.currentLanguage;

        // Handle Language Switch
        if (_lastLanguage != currentLang) {
          // Save buffer of previous language if we were tracking one
          if (_lastLanguage != null) {
            _currentValues[_lastLanguage!] = _controller.text;
          }
          
          // Load new language
          _controller.text = _getTextForLang(currentLang);
          _lastLanguage = currentLang;
        } else {
             // Ensure text is populated on first load
             if (_controller.text.isEmpty && _getTextForLang(currentLang).isNotEmpty) {
                 _controller.text = _getTextForLang(currentLang);
             }
        }

        if (!widget.enabled) {
          // View Mode (Text)
           return Text(
              _controller.text.isNotEmpty ? _controller.text : _getTextForLang(currentLang),
              style: widget.style,
           );
        }

        // Edit Mode (TextField)
        return TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          style: widget.style,
          decoration: widget.decoration,
          maxLines: widget.maxLines,
          onChanged: (val) => _onTextChanged(val, currentLang),
        );
      },
    );
  }
}
