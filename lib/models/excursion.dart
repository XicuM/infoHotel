import '../l10n/translations.dart';

enum ExcursionType {
  pdf,
  images,
}

class ExcursionModel {
  final String id;
  final String name;
  final Map<String, String> localizedNames;
  final String imagePath; // Logo/Thumbnail
  final ExcursionType type;
  final dynamic content; // String (pdf path) or List<String> (image paths)
  final bool isLocalImage; // whether imagePath is in app docs or assets

  ExcursionModel({
    required this.id,
    required this.name,
    this.localizedNames = const {},
    required this.imagePath,
    required this.type,
    required this.content,
    this.isLocalImage = false,
  });

  String getName(String lang) {
    if (localizedNames.containsKey(lang) && localizedNames[lang]!.isNotEmpty) {
      return localizedNames[lang]!;
    }
    return Translations.get(name, lang);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'localizedNames': localizedNames,
      'imagePath': imagePath,
      'type': type.toString().split('.').last, // 'pdf' or 'images'
      'content': content,
      'isLocalImage': isLocalImage,
    };
  }

  static ExcursionModel fromJson(Map<String, dynamic> json) {
    return ExcursionModel(
      id: json['id'],
      name: json['name'],
      localizedNames: Map<String, String>.from(json['localizedNames'] ?? {}),
      imagePath: json['imagePath'],
      type: ExcursionType.values.firstWhere(
        (e) => e.toString() == 'ExcursionType.${json['type']}',
        orElse: () => ExcursionType.images
      ),
      content: json['content'],
      isLocalImage: json['isLocalImage'] ?? false,
    );
  }
}
