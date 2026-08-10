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
  
  // Asset Gallery State
  bool _isLoadingAssets = true;
  List<String> _allAssets = [];
  List<String> _filteredAssets = [];
  String _selectedFolderFilter = 'All';
  List<String> _selectedSubFolders = [];
  String _gallerySearchQuery = '';

  // USB State
  bool _isLoadingUsb = false;
  List<Map<String, dynamic>> _usbFiles = [];
  List<Map<String, dynamic>> _filteredUsbFiles = [];
  List<String> _usbFolderList = [];
  String _selectedUsbFolder = 'All Folders';
  String _usbSearchQuery = '';

  final List<String> _selectedPaths = [];
  final TextEditingController _customPathController = TextEditingController();
  final TextEditingController _gallerySearchController = TextEditingController();
  final TextEditingController _usbSearchController = TextEditingController();

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
    _gallerySearchController.dispose();
    _usbSearchController.dispose();
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
      final query = _gallerySearchQuery.toLowerCase().trim();
      _filteredAssets = _allAssets.where((f) {
        final lowerPath = f.toLowerCase();
        final filename = p.basename(f).toLowerCase();

        // PDF filter
        if (!widget.allowPdf && lowerPath.endsWith('.pdf')) {
          return false;
        }
        // Subfolder filter
        if (_selectedFolderFilter != 'All' && !lowerPath.contains('/${_selectedFolderFilter.toLowerCase()}/')) {
          return false;
        }
        // Search query filter
        if (query.isNotEmpty && !lowerPath.contains(query) && !filename.contains(query)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _loadUsbFiles() async {
    setState(() => _isLoadingUsb = true);
    final contentService = Provider.of<ContentService>(context, listen: false);
    final files = await contentService.listUsbFiles();

    final validFiles = files.where((f) {
      final path = f['path'] as String? ?? '';
      if (widget.allowPdf) return true;
      return !path.toLowerCase().endsWith('.pdf');
    }).toList();

    // Extract USB folders
    final folders = <String>{'All Folders'};
    for (final file in validFiles) {
      final path = file['path'] as String? ?? '';
      final dirName = p.basename(p.dirname(path));
      if (dirName.isNotEmpty) {
        folders.add(dirName);
      }
    }

    setState(() {
      _usbFiles = validFiles;
      _usbFolderList = folders.toList()..sort();
      _selectedUsbFolder = 'All Folders';
      _isLoadingUsb = false;
      _applyUsbFilter();
    });
  }

  void _applyUsbFilter() {
    setState(() {
      final query = _usbSearchQuery.toLowerCase().trim();
      _filteredUsbFiles = _usbFiles.where((file) {
        final path = file['path'] as String? ?? '';
        final name = file['name'] as String? ?? '';
        final dirName = p.basename(p.dirname(path));

        // Folder filter
        if (_selectedUsbFolder != 'All Folders' && dirName != _selectedUsbFolder) {
          return false;
        }
        // Search query filter
        if (query.isNotEmpty && !name.toLowerCase().contains(query) && !path.toLowerCase().contains(query)) {
          return false;
        }
        return true;
      }).toList();
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

  Future<void> _confirmDeleteAsset(String path) async {
    final fileName = p.basename(path);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252538),
        title: const Text('Delete Asset?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to permanently delete "$fileName"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final contentService = Provider.of<ContentService>(context, listen: false);
      await contentService.deleteImage(path);
      setState(() {
        _selectedPaths.remove(path);
      });
      await _loadAssets();
    }
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedPaths.isEmpty) return;
    final count = _selectedPaths.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF252538),
        title: Text('Delete $count Selected Asset(s)?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete the selected asset(s)? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final contentService = Provider.of<ContentService>(context, listen: false);
      final pathsToDelete = List<String>.from(_selectedPaths);
      for (final p in pathsToDelete) {
        await contentService.deleteImage(p);
      }
      setState(() {
        _selectedPaths.clear();
      });
      await _loadAssets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        height: 650,
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
                if (_selectedPaths.isNotEmpty) ...[
                  Text(
                    'Selected: ${_selectedPaths.length} item(s)',
                    style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _confirmDeleteSelected,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text('Delete (${_selectedPaths.length})'),
                  ),
                ],
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
        // Controls Row: Search Bar & Folder Filter Dropdown
        Row(
          children: [
            // Search Input
            Expanded(
              child: TextField(
                controller: _gallerySearchController,
                onChanged: (val) {
                  _gallerySearchQuery = val;
                  _applyFolderFilter();
                },
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search gallery images...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                  suffixIcon: _gallerySearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () {
                            _gallerySearchController.clear();
                            _gallerySearchQuery = '';
                            _applyFolderFilter();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFF2A2A3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Folder Filter Dropdown
            const Text('Folder: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFolderFilter,
                  dropdownColor: const Color(0xFF2A2A3D),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grid View of Images
        Expanded(
          child: _filteredAssets.isEmpty
              ? const Center(
                  child: Text('No matching assets found.', style: TextStyle(color: Colors.white38)),
                )
              : GridView.builder(
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
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _confirmDeleteAsset(path),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                  ),
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
        // USB Header Controls: Search Bar + Folder Filter Dropdown + Refresh Button
        Row(
          children: [
            // Search Input
            Expanded(
              child: TextField(
                controller: _usbSearchController,
                onChanged: (val) {
                  _usbSearchQuery = val;
                  _applyUsbFilter();
                },
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search USB files...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
                  suffixIcon: _usbSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                          onPressed: () {
                            _usbSearchController.clear();
                            _usbSearchQuery = '';
                            _applyUsbFilter();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFF2A2A3D),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Folder Filter Dropdown
            const Text('Folder: ', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUsbFolder,
                  dropdownColor: const Color(0xFF2A2A3D),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: _usbFolderList.map((folder) {
                    return DropdownMenuItem(
                      value: folder,
                      child: Text(folder),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedUsbFolder = val;
                        _applyUsbFilter();
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blueAccent),
              tooltip: 'Refresh USB scan',
              onPressed: _loadUsbFiles,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // USB Files List
        Expanded(
          child: _filteredUsbFiles.isEmpty
              ? const Center(
                  child: Text('No files match the search or folder filter.', style: TextStyle(color: Colors.white38)),
                )
              : ListView.builder(
                  itemCount: _filteredUsbFiles.length,
                  itemBuilder: (context, index) {
                    final file = _filteredUsbFiles[index];
                    final usbPath = file['path'] as String;
                    final fileName = file['name'] as String;
                    final size = file['size'] as int? ?? 0;
                    final sizeMb = (size / (1024 * 1024)).toStringAsFixed(2);
                    final dirName = p.basename(p.dirname(usbPath));
                    final isSelected = _selectedPaths.contains(usbPath);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : const Color(0xFF252538),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blueAccent : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          fileName.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                          color: isSelected ? Colors.blueAccent : Colors.white70,
                        ),
                        title: Text(fileName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('📁 $dirName • $sizeMb MB\n$usbPath', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? Colors.green : Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(isSelected ? Icons.check : Icons.file_download, size: 16),
                          label: Text(isSelected ? 'Imported' : 'Import'),
                          onPressed: () async {
                            final contentService = Provider.of<ContentService>(context, listen: false);
                            final newPath = await contentService.copyUsbFile(usbPath, subFolder: widget.subFolder);
                            _toggleSelection(newPath);
                          },
                        ),
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
