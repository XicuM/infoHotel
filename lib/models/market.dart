class MarketModel {
  final String id;
  String name;
  String description;
  String openingHours; // newly added
  String imagePath; // used as card logo
  List<String> galleryImages;
  final bool isCustom;
  String? pdfPath;
  
  // New fields for multi-language support
  Map<String, String> localizedNames;
  Map<String, String> localizedDescriptions;
  Map<String, String> localizedOpeningHours; // newly added

  MarketModel({
    required this.id,
    required this.name,
    this.description = '',
    this.openingHours = '',
    required this.imagePath,
    this.galleryImages = const [],
    this.isCustom = false,
    this.pdfPath,
    this.localizedNames = const {},
    this.localizedDescriptions = const {},
    this.localizedOpeningHours = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'openingHours': openingHours,
      'imagePath': imagePath,
      'galleryImages': galleryImages,
      'isCustom': isCustom,
      if (pdfPath != null) 'pdfPath': pdfPath,
      'localizedNames': localizedNames,
      'localizedDescriptions': localizedDescriptions,
      'localizedOpeningHours': localizedOpeningHours,
    };
  }

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      openingHours: json['openingHours'] as String? ?? '',
      imagePath: json['imagePath'] as String,
      galleryImages: (json['galleryImages'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isCustom: json['isCustom'] as bool? ?? false,
      pdfPath: json['pdfPath'] as String?,
      localizedNames: (json['localizedNames'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      localizedDescriptions: (json['localizedDescriptions'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      localizedOpeningHours: (json['localizedOpeningHours'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
    );
  }

  // Helper to distinguish asset vs local file
  bool get isLocalImage => isCustom || imagePath.startsWith('http') == false && (imagePath.contains('/') || imagePath.contains('\\')) && !imagePath.startsWith('assets');

  // Helpers to get localized content
  // If we have a custom translation, use it. Otherwise fallback to the main field (which might be a key or default)
  String getName(String langCode) {
    if (localizedNames.containsKey(langCode) && localizedNames[langCode]!.isNotEmpty) {
      return localizedNames[langCode]!;
    }
    // Fallback: mostly 'name' is a key or a raw string for default markets
    return name;
  }

  String getDescription(String langCode) {
    if (localizedDescriptions.containsKey(langCode) && localizedDescriptions[langCode]!.isNotEmpty) {
      return localizedDescriptions[langCode]!;
    }
    return description;
  }
  
  String getOpeningHours(String langCode) {
    if (localizedOpeningHours.containsKey(langCode) && localizedOpeningHours[langCode]!.isNotEmpty) {
      return localizedOpeningHours[langCode]!;
    }
    return openingHours;
  }
}
