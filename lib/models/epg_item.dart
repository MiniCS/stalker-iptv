class EpgItem {
  final String id;
  final String title;
  final String description;
  final int startMs;
  final int stopMs;
  final String mediaId;
  final String realId;

  EpgItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startMs,
    required this.stopMs,
    this.mediaId = '',
    this.realId = '',
  });

  bool get isNow {
    final now = DateTime.now().millisecondsSinceEpoch;
    return now >= startMs && now < stopMs;
  }

  double get progress {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < startMs) return 0;
    if (now > stopMs) return 1;
    return (now - startMs) / (stopMs - startMs);
  }

  String get startTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(startMs);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String get stopTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(stopMs);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  factory EpgItem.fromJson(Map<String, dynamic> json) {
    final title = (json['name'] ?? json['title'] ?? json['programme_name'] ?? '').toString();
    final descr = (json['descr'] ?? json['description'] ?? json['info'] ?? '').toString();
    final id = (json['id'] ?? json['media_id'] ?? json['record_id'] ?? '').toString();
    final mediaId = (json['media_id'] ?? '').toString();
    final realId = (json['real_id'] ?? '').toString();

    final startMs = _parseTimestamp(json['start_timestamp'] ?? json['time'] ?? json['start'] ?? json['utc_start'] ?? 0);
    final durationMin = _parseInt(json['duration'] ?? json['duration_minutes'] ?? json['length'] ?? 0);
    final stopMs = _parseTimestamp(json['stop_timestamp'] ?? json['end'] ?? json['stop'] ?? 0).let((s) => s > 0 ? s : startMs + durationMin * 60 * 1000);

    return EpgItem(
      id: id,
      title: title,
      description: descr,
      startMs: startMs,
      stopMs: stopMs,
      mediaId: mediaId,
      realId: realId,
    );
  }

  static int _parseTimestamp(dynamic v) {
    if (v == null) return 0;
    if (v is num) {
      final n = v.toInt();
      if (n > 9999999999) return n; // already ms
      return n * 1000; // seconds → ms
    }
    final s = v.toString();
    if (s.contains('T') || s.contains('-')) {
      return DateTime.tryParse(s)?.millisecondsSinceEpoch ?? 0;
    }
    final n = int.tryParse(s) ?? 0;
    if (n > 9999999999) return n;
    return n * 1000;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
