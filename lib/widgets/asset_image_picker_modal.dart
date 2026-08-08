import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import '../services/content_service.dart';
import '../widgets/app_image.dart';

class AssetImagePickerModal extends StatefulWidget {
  final String subFolder;
  final bool allowPdf;
  final bool allowMultiple;

  const AssetImagePickerModal({
    super.key,
    this.subFolder = 'markets',
    this.allowPdf = false,
    this.allowMultiple = false,
  });

  /// Helper to show modal and return selected path(s)
  static Future<dynamic> show(
    BuildContext context, {
    String subFolder = 'markets',
    bool allowPdf = false,
    bool allowMultiple = false,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => AssetImagePickerModal(
        subFolder: subFolder,
        allowPdf: allowPdf,
        allowMultiple: allowMultiple,
      ),
    );
  }

  @override
  State<AssetImagePickerModal> createState() => _AssetImagePickerModalState();
}

class _AssetImagePickerModalState extends State<AssetImagePickerModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoadingAssets = true;
  List<String> _allAssets = [];
  List<String> _filteredAssets = [];
  String _selectedFolderFilter = 'All';
  List<String> _selectedSubFolders = [];

  bool _isLoadingUsb = false;
  List<Map<String, dynamic>> _usbFiles = [];

  final List<String> _selectedPaths = [];
  final TextEditingController _customPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAssets();
    _loadUsbFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customPathController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoadingAssets = true);
    final contentService = Provider.of<ContentService>(context, listen: false);
    final files = await contentService.listAvailableImages();
    
    // Extract unique subfolders
    final folders = <String>{'All'};
    for (final file in files) {
      final parts = file.split('/');
      if (parts.length > 2) {
        folders.add(parts[2]);
      }
    }

    setState(() {
      _allAssets = files;
      _selectedSubFolders = folders.toList()..sort();
      _isLoadingAssets = false;
      _applyFolderFilter();
    });
  }

  void _applyFolderFilter() {
    setState(() {
      if (_selectedFolderFilter == 'All') {
        _filteredAssets = _allAssets.where((f) {
          if (widget.allowPdf) return true;
          return !f.toLowerCase().endsWith('.pdf');
        }).toList();
      } else {
        _filteredAssets = _allAssets.where((f) {
          final isSub = f.contains('/$_selectedFolderFilter/');
          if (widget.allowPdf) return isSub;
          return isSub && !f.toLowerCase().endsWith('.pdf');
        }).toList();
      }
    });
  }

  Future<void> _loadUsbFiles() async {
    setState(() => _isLoadingUsb = true);
    final contentService = Provider.of<ContentService>(context, listen: false);
    final files = await contentService.listUsbFiles();
    setState(() {
      _usbFiles = files.where((f) {
        final path = f['path'] as String? ?? '';
        if (widget.allowPdf) return true;
        return !path.toLowerCase().endsWith('.pdf');
      }).toList();
      _isLoadingUsb = false;
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (widget.allowMultiple) {
        if (_selectedPaths.contains(path)) {
          _selectedPaths.remove(path);
        } else {
          _selectedPaths.add(path);
        }
      } else {
        _selectedPaths.clear();
        _selectedPaths.add(path);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedPaths.isEmpty) {
      Navigator.of(context).pop(null);
    } else if (widget.allowMultiple) {
      Navigator.of(context).pop(_selectedPaths);
    } else {
      Navigator.of(context).pop(_selectedPaths.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header & Tabs
            Row(
              children: [
                const Icon(Icons.photo_library, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 12),
                Text(
                  widget.allowPdf ? 'Select Media / PDF' : 'Select Image',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TabBar(
              controller: _tabController,
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(icon: Icon(Icons.collections), text: 'Asset Gallery'),
                Tab(icon: Icon(Icons.usb), text: 'USB Flash Drive'),
                Tab(icon: Icon(Icons.upload_file), text: 'Upload / Path'),
              ],
            ),

            const SizedBox(height: 12),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAssetGalleryTab(),
                  _buildUsbTab(),
                  _buildUploadTab(),
                ],
              ),
            ),

            const Divider(color: Colors.white24, height: 24),

            // Footer / Actions
            Row(
              children: [
                if (_selectedPaths.isNotEmpty)
                  Text(
                    'Selected: ${_selectedPaths.length} item(s)',
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _selectedPaths.isEmpty ? null : _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Selection'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetGalleryTab() {
    if (_isLoadingAssets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allAssets.isEmpty) {
      return const Center(
        child: Text('No assets found in hotel_assets/', style: TextStyle(color: Colors.white54)),
      );
    }

    return Column(
      children: [
        // Folder Filter Dropdown
        Row(
          children: [
            const Text('Folder: ', style: TextStyle(color: Colors.white70)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _selectedFolderFilter,
              dropdownColor: const Color(0xFF2A2A3D),
              style: const TextStyle(color: Colors.white),
              items: _selectedSubFolders.map((folder) {
                return DropdownMenuItem(
                  value: folder,
                  child: Text(folder.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedFolderFilter = val;
                    _applyFolderFilter();
                  });
                }
              },
            ),
            const Spacer(),
            Text('${_filteredAssets.length} items', style: const TextStyle(color: Colors.white54)),
          ],
        ),
        const SizedBox(height: 8),

        // Grid View of Images
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _filteredAssets.length,
            itemBuilder: (context, index) {
              final path = _filteredAssets[index];
              final isSelected = _selectedPaths.contains(path);
              final isPdf = path.toLowerCase().endsWith('.pdf');

              return InkWell(
                onTap: () => _toggleSelection(path),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.white24,
                      width: isSelected ? 3 : 1,
                    ),
                    color: Colors.black26,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: isPdf
                            ? const Center(
                                child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.redAccent),
                              )
                            : AppImage(
                                path: path,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white38),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: const Color(0xB3000000),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            p.basename(path),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.check, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsbTab() {
    if (_isLoadingUsb) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usbFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.usb_off, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            const Text(
              'No USB flash drives or compatible image/PDF files found.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadUsbFiles,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh USB Scan'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Text('Found ${_usbFiles.length} file(s) on USB drive:', style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blueAccent),
              onPressed: _loadUsbFiles,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _usbFiles.length,
            itemBuilder: (context, index) {
              final file = _usbFiles[index];
              final usbPath = file['path'] as String;
              final fileName = file['name'] as String;
              final size = file['size'] as int? ?? 0;
              final sizeMb = (size / (1024 * 1024)).toStringAsFixed(2);

              return ListTile(
                leading: Icon(
                  fileName.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                  color: Colors.blueAccent,
                ),
                title: Text(fileName, style: const TextStyle(color: Colors.white)),
                subtitle: Text('$usbPath ($sizeMb MB)', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                trailing: ElevatedButton(
                  child: const Text('Import'),
                  onPressed: () async {
                    final contentService = Provider.of<ContentService>(context, listen: false);
                    final newPath = await contentService.copyUsbFile(usbPath, subFolder: widget.subFolder);
                    _toggleSelection(newPath);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Option 1: Browser/PC File Upload',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use standard browser file selection if accessing from a PC or desktop browser:',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.file_upload),
            label: const Text('Open System File Browser'),
            onPressed: () async {
              final result = await FilePicker.pickFiles(
                type: widget.allowPdf ? FileType.custom : FileType.image,
                allowedExtensions: widget.allowPdf ? ['pdf'] : null,
                allowMultiple: widget.allowMultiple,
                withData: true,
              );

              if (result != null && result.files.isNotEmpty) {
                final contentService = Provider.of<ContentService>(context, listen: false);
                for (var file in result.files) {
                  final newPath = await contentService.saveImage(
                    file.path ?? '',
                    subFolder: widget.subFolder,
                    bytes: file.bytes,
                    originalName: file.name,
                  );
                  _toggleSelection(newPath);
                }
              }
            },
          ),

          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          const Text(
            'Option 2: Direct Asset Path / URL',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Type or paste an asset path (e.g. hotel_assets/images/markets/sample.jpg) or HTTP URL:',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customPathController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'hotel_assets/images/...',
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Color(0xFF2A2A3D),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  final text = _customPathController.text.trim();
                  if (text.isNotEmpty) {
                    _toggleSelection(text);
                  }
                },
                child: const Text('Add Path'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
