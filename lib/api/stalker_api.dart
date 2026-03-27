import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/epg_item.dart';
import '../models/vod_item.dart';

class StalkerApi {
  static const _vodSn = '85DFA00493C4E';
  static const _timezone = 'Europe/Prague';
  static const _userAgent =
      'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG254 stbapp ver: 5 rev: 250 Safari/533.3';
  static const _xUserAgent = 'Model: MAG254; Link: Ethernet';

  final _client = http.Client();

  Map<String, String> _buildHeaders(String portal, String mac, String token) {
    return {
      'User-Agent': _userAgent,
      'X-User-Agent': _xUserAgent,
      'Referer': '$portal/c/',
      'Origin': portal,
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      'Cookie': _buildCookie(mac, token),
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _buildCookie(String mac, String token) {
    return 'PHPSESSID=null; sn=$_vodSn; mac=$mac; stb_lang=en; timezone=$_timezone; token=$token; not_valid_token=0';
  }

  Future<Map<String, dynamic>?> _get(String url, String portal, String mac, String token) async {
    try {
      final response = await _client
          .get(Uri.parse(url), headers: _buildHeaders(portal, mac, token))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // Handshake — získá token
  Future<String?> handshake(String portal, String mac) async {
    final candidates = _portalCandidates(portal);
    for (final base in candidates) {
      final variants = [
        '$base/server/load.php?type=stb&action=handshake&token=&prehash=false&JsHttpRequest=1-xml',
        '$base/server/load.php?type=stb&action=handshake&JsHttpRequest=1-xml',
      ];
      for (final url in variants) {
        final json = await _get(url, base, mac, '');
        final token = json?['js']?['token']?.toString();
        if (token != null && token.isNotEmpty) return token;
      }
    }
    return null;
  }

  // Ověří session
  Future<bool> getProfile(String portal, String mac, String token) async {
    final url = '$portal/server/load.php?type=stb&action=get_profile&hd=1&ver=ImageDescription:0.2.18-r23-250&sn=$_vodSn&stb_type=MAG254&JsHttpRequest=1-xml';
    final json = await _get(url, portal, mac, token);
    return json != null;
  }

  // Načte kanály (stránkováno)
  Future<List<Channel>> getChannels(String portal, String mac, String token) async {
    final List<Channel> channels = [];
    int page = 1;
    while (true) {
      final url = '$portal/server/load.php?type=itv&action=get_ordered_list&genre=0&force_ch_link_check=0&p=$page&JsHttpRequest=1-xml';
      final json = await _get(url, portal, mac, token);
      final data = json?['js']?['data'] as List?;
      if (data == null || data.isEmpty) break;
      channels.addAll(data.map((e) => Channel.fromJson(e as Map<String, dynamic>)));
      final total = int.tryParse(json?['js']?['total_items']?.toString() ?? '0') ?? 0;
      if (channels.length >= total || data.length < 10) break;
      page++;
    }
    return channels;
  }

  // EPG pro kanál (7 fallbacků jako v originále)
  Future<List<EpgItem>> getShortEpg(String portal, String mac, String token, String channelId) async {
    final endpoints = [
      '$portal/server/load.php?type=itv&action=get_short_epg&ch_id=$channelId&JsHttpRequest=1-xml',
      '$portal/server/load.php?type=itv&action=get_short_epg&ch_id=$channelId&size=20&JsHttpRequest=1-xml',
      '$portal/server/load.php?type=itv&action=get_short_epg&ch_id=$channelId&size=200&JsHttpRequest=1-xml',
      '$portal/server/load.php?type=itv&action=get_simple_data_table&ch_id=$channelId&JsHttpRequest=1-xml',
      '$portal/server/load.php?type=itv&action=get_epg_info&period=6&ch_id=$channelId&JsHttpRequest=1-xml',
      '$portal/server/load.php?type=itv&action=get_epg_info&period=24&ch_id=$channelId&JsHttpRequest=1-xml',
      '$portal/server/load.php?type=itv&action=get_epg_info&period=72&ch_id=$channelId&JsHttpRequest=1-xml',
    ];
    for (final url in endpoints) {
      final json = await _get(url, portal, mac, token);
      final data = json?['js']?['data'] as List?;
      if (data != null && data.isNotEmpty) {
        return data
            .map((e) => EpgItem.fromJson(e as Map<String, dynamic>))
            .where((e) => e.title.isNotEmpty && e.startMs > 0 && e.stopMs > e.startMs)
            .toList()
          ..sort((a, b) => a.startMs.compareTo(b.startMs));
      }
    }
    return [];
  }

  // Stream link
  Future<String?> createLink(String portal, String mac, String token, String cmd) async {
    final sanitized = _sanitizeCmd(cmd);
    final encoded = Uri.encodeComponent(sanitized);
    final url = '$portal/server/load.php?type=itv&action=create_link&cmd=$encoded&JsHttpRequest=1-xml';
    final json = await _get(url, portal, mac, token);
    final result = json?['js']?['cmd']?.toString() ?? json?['js']?['url']?.toString();
    if (result != null && result.isNotEmpty) return _sanitizeCmd(result);
    if (sanitized.startsWith('http')) return sanitized;
    return null;
  }

  // Archive link
  Future<String?> createArchiveLink(String portal, String mac, String token,
      String channelId, String channelCmd, String realId, int start, int stop) async {
    final duration = ((stop - start) ~/ 1000).clamp(60, 999999);
    final sanitized = _sanitizeCmd(channelCmd);
    final encoded = Uri.encodeComponent(sanitized);
    final variants = [
      '$portal/server/load.php?type=tv_archive&action=create_link&cmd=$encoded&ch_id=$channelId&real_id=$realId&start=$start&duration=$duration&JsHttpRequest=1-xml',
      '$portal/server/load.php?type=tv_archive&action=create_link&cmd=$encoded&ch_id=$channelId&start=$start&duration=$duration&JsHttpRequest=1-xml',
      '$portal/server/load.php?type=tv_archive&action=create_link&cmd=$encoded&ch_id=$channelId&utc=$start&duration=$duration&JsHttpRequest=1-xml',
    ];
    for (final url in variants) {
      final json = await _get(url, portal, mac, token);
      final result = json?['js']?['cmd']?.toString() ?? json?['js']?['url']?.toString();
      if (result != null && result.isNotEmpty) return _sanitizeCmd(result);
    }
    return null;
  }

  // VOD kategorie
  Future<List<VodCategory>> getVodCategories(String portal, String mac, String token) async {
    final url = '$portal/server/load.php?type=vod&action=get_categories&JsHttpRequest=1-xml';
    final json = await _get(url, portal, mac, token);
    final data = json?['js'] as List?;
    if (data == null) return [];
    return data.map((e) => VodCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  // VOD seznam (stránkováno)
  Future<({List<VodItem> items, bool hasMore})> getVodItems(
      String portal, String mac, String token, String categoryId, int page) async {
    final encoded = Uri.encodeComponent(categoryId);
    final url = '$portal/server/load.php?type=vod&action=get_ordered_list&category_id=$encoded&sortby=added&sortdir=desc&p=$page&JsHttpRequest=1-xml';
    final json = await _get(url, portal, mac, token);
    final data = json?['js']?['data'] as List?;
    if (data == null) return (items: <VodItem>[], hasMore: false);
    final items = data.map((e) => VodItem.fromJson(e as Map<String, dynamic>)).toList();
    final total = int.tryParse(json?['js']?['total_items']?.toString() ?? '0') ?? 0;
    final loaded = page * items.length;
    return (items: items, hasMore: loaded < total);
  }

  String _sanitizeCmd(String cmd) {
    var s = cmd.trim();
    if (s.startsWith('ffmpeg ')) s = s.substring(7).trim();
    if (s.startsWith('auto ')) s = s.substring(5).trim();
    final hashIdx = s.indexOf('#');
    if (hashIdx > 0) s = s.substring(0, hashIdx);
    return s.trim();
  }

  List<String> _portalCandidates(String portal) {
    final candidates = <String>{portal};
    // Přidej varianty bez/s lomítkem
    if (portal.endsWith('/')) {
      candidates.add(portal.substring(0, portal.length - 1));
    } else {
      candidates.add('$portal/');
    }
    // Přidej /stalker_portal variantu
    if (!portal.contains('stalker_portal')) {
      final base = portal.endsWith('/') ? portal.substring(0, portal.length - 1) : portal;
      candidates.add('$base/stalker_portal');
    }
    return candidates.toList();
  }

  void dispose() => _client.close();
}
