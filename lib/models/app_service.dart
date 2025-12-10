class AppVersion {
  final bool updateAvailable;
  final bool isMandatory;
  final bool forceUpdateRequired;
  final String priority;
  final String latestVersion;
  final int latestBuild;
  final String? whatsNew;
  final String? releaseNotes;
  final String storeUrl;
  final DateTime? forceUpdateDate;
  final String? minVersion;
  final DateTime releaseDate;

  AppVersion({
    required this.updateAvailable,
    required this.isMandatory,
    required this.forceUpdateRequired,
    required this.priority,
    required this.latestVersion,
    required this.latestBuild,
    this.whatsNew,
    this.releaseNotes,
    required this.storeUrl,
    this.forceUpdateDate,
    this.minVersion,
    required this.releaseDate,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      updateAvailable: json['updateAvailable'] ?? false,
      isMandatory: json['isMandatory'] ?? false,
      forceUpdateRequired: json['forceUpdateRequired'] ?? false,
      priority: json['priority'] ?? 'NORMAL',
      latestVersion: json['latestVersion'] ?? '',
      latestBuild: json['latestBuild'] ?? 0,
      whatsNew: json['whatsNew'],
      releaseNotes: json['releaseNotes'],
      storeUrl: json['storeUrl'] ?? '',
      forceUpdateDate: json['forceUpdateDate'] != null
          ? DateTime.parse(json['forceUpdateDate'])
          : null,
      minVersion: json['minVersion'],
      releaseDate: DateTime.parse(json['releaseDate']),
    );
  }
}
