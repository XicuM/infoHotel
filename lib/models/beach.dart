class BeachModel {
  final String id;
  String name;
  String description;
  String municipality;
  List<String> services;
  String imagePath;
  List<String> galleryImages;
  final bool isCustom;

  Map<String, String> localizedNames;
  Map<String, String> localizedDescriptions;
  Map<String, String> localizedMunicipalities;
  Map<String, Map<String, String>> localizedServices;

  BeachModel({
    required this.id,
    required this.name,
    this.description = '',
    this.municipality = '',
    this.services = const [],
    required this.imagePath,
    this.galleryImages = const [],
    this.isCustom = false,
    this.localizedNames = const {},
    this.localizedDescriptions = const {},
    this.localizedMunicipalities = const {},
    this.localizedServices = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'municipality': municipality,
      'services': services,
      'imagePath': imagePath,
      'galleryImages': galleryImages,
      'isCustom': isCustom,
      'localizedNames': localizedNames,
      'localizedDescriptions': localizedDescriptions,
      'localizedMunicipalities': localizedMunicipalities,
      'localizedServices': localizedServices,
    };
  }

  factory BeachModel.fromJson(Map<String, dynamic> json) {
    return BeachModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      municipality: json['municipality'] as String? ?? '',
      services: (json['services'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      imagePath: json['imagePath'] as String,
      galleryImages: (json['galleryImages'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isCustom: json['isCustom'] as bool? ?? false,
      localizedNames: (json['localizedNames'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      localizedDescriptions: (json['localizedDescriptions'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      localizedMunicipalities: (json['localizedMunicipalities'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? {},
      localizedServices: (json['localizedServices'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as Map<String, dynamic>).map((sk, sv) => MapEntry(sk, sv as String)))) ?? {},
    );
  }

  bool get isLocalImage => isCustom || imagePath.startsWith('http') == false && (imagePath.contains('/') || imagePath.contains('\\')) && !imagePath.startsWith('assets');

  String getName(String langCode) {
    if (localizedNames.containsKey(langCode) && localizedNames[langCode]!.isNotEmpty) {
      return localizedNames[langCode]!;
    }
    return name;
  }

  String getDescription(String langCode) {
    if (localizedDescriptions.containsKey(langCode) && localizedDescriptions[langCode]!.isNotEmpty) {
      return localizedDescriptions[langCode]!;
    }
    return description;
  }

  String getMunicipality(String langCode) {
    if (localizedMunicipalities.containsKey(langCode) && localizedMunicipalities[langCode]!.isNotEmpty) {
      return localizedMunicipalities[langCode]!;
    }
    return municipality;
  }

  List<String> getServices(String langCode) {
    if (localizedServices.containsKey(langCode) && localizedServices[langCode]!.isNotEmpty) {
      return localizedServices[langCode]!.values.toList();
    }
    return services;
  }
}
