import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../../models/excursion.dart';
import '../../services/content_service.dart';
import '../../services/excursion_service.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/localized_text_field.dart';
import '../../widgets/app_image.dart';

class ExcursionEditView extends StatefulWidget {
  final ExcursionModel excursion;
  final bool isNew;

  const ExcursionEditView({
    super.key,
    required this.excursion,
    this.isNew = false,
  });

  @override
  State<ExcursionEditView> createState() => _ExcursionEditViewState();
}

class _ExcursionEditViewState extends State<ExcursionEditView> {
  late Map<String, String> _localizedNames;
  late ExcursionType _type;
  late String _imagePath;
  late dynamic _content; // String or List<String>
  late bool _isLocalImage;

  @override
  void initState() {
    super.initState();
    _localizedNames = Map.from(widget.excursion.localizedNames);
    _type = widget.excursion.type;
    _imagePath = widget.excursion.imagePath;
    _content = widget.excursion.content;
    _isLocalImage = widget.excursion.isLocalImage;

    // Ensure default lang key exists for new items
    if (widget.isNew && !_localizedNames.containsKey('en')) {
      _localizedNames['en'] = widget.excursion.name;
    }
  }

  void _save(ContentService contentService) async {
    final updatedExcursion = ExcursionModel(
      id: widget.excursion.id,
      name: _localizedNames['en'] ?? widget.excursion.name, // Fallback
      localizedNames: _localizedNames,
      imagePath: _imagePath,
      type: _type,
      content: _content,
      isLocalImage: _isLocalImage,
    );

    if (widget.isNew) {
      await context.read<ExcursionService>().addExcursion(updatedExcursion);
    } else {
      await context.read<ExcursionService>().updateExcursion(updatedExcursion);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _delete(ContentService contentService) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Excursion?'),
        content: const Text('Are you sure you want to delete this excursion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close view
              await context.read<ExcursionService>().deleteExcursion(widget.excursion.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentService>(
      builder: (context, contentService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212), // Dark mode background
          appBar: CustomAppBar(
            titleKey: widget.isNew ? 'New Excursion' : 'Edit Excursion',
            backgroundColor: const Color(0xFF00ACC1), // Excursions color
            onBack: () => Navigator.of(context).pop(),
            actions: [
              if (!widget.isNew)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _delete(contentService),
                ),
              IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
                onPressed: () => _save(contentService),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name Input
                LocalizedTextField(
                  localizedValues: _localizedNames,
                  defaultValue: widget.excursion.name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  onValuesChanged: (values) {
                     setState(() {
                       _localizedNames = values;
                     });
                  },
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),

                // Logo Picker
                const Text('Logo/Thumbnail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                        child: _isLocalImage 
                          ? AppImage(path: _imagePath, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                          : AppImage(path: _imagePath, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image, withData: true);
                        if (result != null && (result.files.single.path != null || kIsWeb)) {
                           final newPath = await contentService.saveImage(
                             result.files.single.path ?? '', 
                             subFolder: 'excursions/logos',
                             bytes: result.files.single.bytes,
                             originalName: result.files.single.name,
                           );
                           setState(() {
                             _imagePath = newPath;
                             _isLocalImage = true;
                           });
                        }
                      },
                      child: const Text('Pick Image'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Type Dropdown
                DropdownButtonFormField<ExcursionType>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ExcursionType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null && val != _type) {
                      setState(() {
                        _type = val;
                        // Reset content on type change
                        _content = val == ExcursionType.pdf ? '' : <String>[];
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Content Picker
                const Text('Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                 if (_type == ExcursionType.pdf)
                  _buildPdfPicker(contentService)
                else
                  _buildImagesPicker(contentService),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPdfPicker(ContentService contentService) {
    return Row(
      children: [
        Expanded(
          child: Text(
            (_content as String).isEmpty ? 'No PDF selected' : p.basename(_content as String),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              withData: true,
            );
            if (result != null && (result.files.single.path != null || kIsWeb)) {
              final newPath = await contentService.saveImage(
                result.files.single.path ?? '', 
                subFolder: 'excursions/pdf',
                bytes: result.files.single.bytes,
                originalName: result.files.single.name,
              );
              setState(() {
                _content = newPath;
              });
            }
          },
          child: const Text('Select PDF'),
        ),
      ],
    );
  }

  Widget _buildImagesPicker(ContentService contentService) {
    final images = _content as List<dynamic>; // JSON decode might produce list of dynamic
    
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: images.map((path) {
            final strPath = path.toString();
            final isLocal = !strPath.startsWith('hotel_assets/');
            return SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  isLocal 
                     ? AppImage(path: strPath, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                     : AppImage(path: strPath, fit: BoxFit.cover),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                       icon: const Icon(Icons.close, color: Colors.red),
                       onPressed: () {
                          setState(() {
                            images.remove(path);
                            _content = images;
                          });
                       },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
             final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: true, withData: true);
             if (result != null) {
                for (var file in result.files) {
                  if (file.path != null || kIsWeb) {
                     final newPath = await contentService.saveImage(
                       file.path ?? '', 
                       subFolder: 'excursions/images',
                       bytes: file.bytes,
                       originalName: file.name,
                     );
                     setState(() {
                       images.add(newPath);
                       _content = images;
                     });
                  }
                }
             }
          },
          child: const Text('Add Images'),
        ),
      ],
    );
  }
}
