import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's in-app position so that when the Android process is
/// killed while backgrounded (e.g. after pressing Home or taking a phone
/// call) and the app cold-starts, we can send them back to where they were
/// instead of the welcome/login screen.
///
/// Two things are remembered:
///   - the last bottom-nav tab (Discover / Matches / Messages / Profile ...)
///   - the last opened conversation (user id + display name + photo) so a
///     mid-chat session can be restored.
class SessionRestore {
  SessionRestore._();

  static const _kLastTabIndex = 'session_restore_last_tab_index';
  static const _kChatUserId = 'session_restore_chat_user_id';
  static const _kChatName = 'session_restore_chat_name';
  static const _kChatPhotoUrl = 'session_restore_chat_photo_url';

  /// Default tab when nothing was saved (Discover).
  static const int defaultTabIndex = 0;

  // ── Last tab ─────────────────────────────────────────────────────────────
  static Future<void> saveLastTab(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastTabIndex, index);
    } catch (_) {
      // Best-effort; never let a storage failure break navigation.
    }
  }

  static Future<int> loadLastTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_kLastTabIndex) ?? defaultTabIndex;
    } catch (_) {
      return defaultTabIndex;
    }
  }

  // ── Last conversation ────────────────────────────────────────────────────
  static Future<void> saveLastChat({
    required String userId,
    required String name,
    String? photoUrl,
  }) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_kChatUserId, userId),
        prefs.setString(_kChatName, name),
        if (photoUrl != null && photoUrl.isNotEmpty)
          prefs.setString(_kChatPhotoUrl, photoUrl),
      ]);
    } catch (_) {
      // Best-effort; never let a storage failure break opening a chat.
    }
  }

  /// Returns {userId, name, photoUrl?} or null if no conversation was saved.
  static Future<Map<String, String>?> loadLastChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_kChatUserId);
      if (userId == null || userId.isEmpty) return null;
    return {
      'userId': userId,
      'name': prefs.getString(_kChatName) ?? '',
      'photoUrl': prefs.getString(_kChatPhotoUrl) ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  /// Clears everything — called on explicit logout so a fresh login doesn't
  /// restore a previous user's position.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_kLastTabIndex),
        prefs.remove(_kChatUserId),
        prefs.remove(_kChatName),
        prefs.remove(_kChatPhotoUrl),
      ]);
    } catch (_) {
      // Best-effort.
    }
  }
}
