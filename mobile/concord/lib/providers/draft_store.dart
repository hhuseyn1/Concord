import 'package:shared_preferences/shared_preferences.dart';

abstract final class DraftStore {
  static const _prefix = 'concord.draft.';

  static Future<String?> read(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$channelId');
  }

  static Future<void> save(String channelId, String content) async {
    final prefs = await SharedPreferences.getInstance();
    if (content.isEmpty) {
      await prefs.remove('$_prefix$channelId');
    } else {
      await prefs.setString('$_prefix$channelId', content);
    }
  }

  static Future<void> clear(String channelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$channelId');
  }
}
