import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/stalker_api.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';

class AppState extends ChangeNotifier {
  final _api = StalkerApi();

  String portal = '';
  String mac = '';
  String token = '';
  bool isLoggedIn = false;

  List<Channel> channels = [];
  bool loadingChannels = false;

  List<VodCategory> vodCategories = [];

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    portal = prefs.getString('portal') ?? '';
    mac = prefs.getString('mac') ?? '';
    token = prefs.getString('token') ?? '';
    isLoggedIn = portal.isNotEmpty && mac.isNotEmpty && token.isNotEmpty;
    notifyListeners();
  }

  Future<bool> login(String portalUrl, String macAddress) async {
    portal = portalUrl.trim();
    mac = macAddress.trim().toUpperCase();

    final t = await _api.handshake(portal, mac);
    if (t == null) return false;

    token = t;
    await _api.getProfile(portal, mac, token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('portal', portal);
    await prefs.setString('mac', mac);
    await prefs.setString('token', token);

    isLoggedIn = true;
    notifyListeners();
    return true;
  }

  Future<void> loadChannels() async {
    if (loadingChannels) return;
    loadingChannels = true;
    notifyListeners();
    channels = await _api.getChannels(portal, mac, token);
    loadingChannels = false;
    notifyListeners();
  }

  Future<String?> getStreamUrl(String cmd) async {
    return _api.createLink(portal, mac, token, cmd);
  }

  Future<List<VodCategory>> getVodCategories() async {
    if (vodCategories.isEmpty) {
      vodCategories = await _api.getVodCategories(portal, mac, token);
    }
    return vodCategories;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    portal = mac = token = '';
    isLoggedIn = false;
    channels = [];
    vodCategories = [];
    notifyListeners();
  }

  StalkerApi get api => _api;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
