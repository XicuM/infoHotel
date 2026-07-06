class HotelConfig {
  final String id;
  final String name;
  final String background;
  final String logo;
  final String cardImage;
  final String showsLogo;
  final bool showShows;
  final int sortOrder;

  const HotelConfig({
    required this.id,
    required this.name,
    required this.background,
    required this.logo,
    required this.cardImage,
    this.showsLogo = '',
    this.showShows = true,
    this.sortOrder = 0,
  });

  factory HotelConfig.fromJson(String id, Map<String, dynamic> json) {
    return HotelConfig(
      id: id,
      name: (json['name'] as String?) ?? id,
      background: (json['background'] as String?) ?? '',
      logo: (json['logo'] as String?) ?? '',
      cardImage: (json['cardImage'] as String?) ?? '',
      showsLogo: (json['showsLogo'] as String?) ?? '',
      showShows: (json['showShows'] as bool?) ?? true,
      sortOrder: (json['sortOrder'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'background': background,
      'logo': logo,
      'cardImage': cardImage,
      if (showsLogo.isNotEmpty) 'showsLogo': showsLogo,
      'showShows': showShows,
      'sortOrder': sortOrder,
    };
  }
}
