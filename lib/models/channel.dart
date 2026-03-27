class Channel {
  final String id;
  final String name;
  final String cmd;
  final String logo;
  final String archiveCmd;
  final bool hasArchive;
  final int archiveDuration;
  final String genreId;
  final String genreTitle;

  Channel({
    required this.id,
    required this.name,
    required this.cmd,
    required this.logo,
    this.archiveCmd = '',
    this.hasArchive = false,
    this.archiveDuration = 0,
    this.genreId = '',
    this.genreTitle = '',
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    final archiveCmd = json['archive_cmd']?.toString() ?? '';
    final flussonicDvr = _parseBool(json['flussonic_dvr']);
    final archiveDuration = _parseInt(json['tv_archive_duration'] ?? json['archive_duration'] ?? 0);
    final hasArchive = flussonicDvr || archiveCmd.isNotEmpty || archiveDuration > 0;

    return Channel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      cmd: json['cmd']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      archiveCmd: archiveCmd,
      hasArchive: hasArchive,
      archiveDuration: archiveDuration,
      genreId: (json['tv_genre_id'] ?? json['genre_id'] ?? '').toString(),
      genreTitle: (json['genre_title'] ?? json['group_title'] ?? '').toString(),
    );
  }

  static bool _parseBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
