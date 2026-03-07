/// Client-side profanity / offensive name filter.
///
/// Three-pass pipeline:
/// 1. **Normalize** — strip accents, collapse repeats, de-leet, remove
///    separators, resolve homoglyphs.
/// 2. **Exact match** — the normalized name IS a blocked word.
/// 3. **Substring match** — the name *contains* a blocked word ≥ 4 chars.
///
/// This is a best-effort client gate, not a security boundary.
/// Server-side moderation (OpenAI Moderation API via SafetyService)
/// should be the real enforcement layer.
class ProfanityFilter {
  ProfanityFilter._();

  // ── Leet-speak / symbol mapping (ported from better-profanity) ─────
  static const _leetMap = <String, String>{
    // Digits
    '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's',
    '7': 't', '8': 'b', '9': 'g',
    // Symbols
    '@': 'a', r'$': 's', '!': 'i', '+': 't',
    '(': 'c', '|': 'l', '¡': 'i', '€': 'e',
    '£': 'l', '¥': 'y',
    // Common Unicode confusables (Cyrillic → Latin)
    'а': 'a', 'с': 'c', 'е': 'e', 'о': 'o', 'р': 'p',
    'х': 'x', 'у': 'y', 'А': 'a', 'С': 'c', 'Е': 'e',
    'О': 'o', 'Р': 'p', 'Х': 'x', 'К': 'k',
    // Fullwidth Latin
    'Ａ': 'a', 'Ｂ': 'b', 'Ｃ': 'c', 'Ｄ': 'd', 'Ｅ': 'e',
    'Ｆ': 'f', 'Ｇ': 'g', 'Ｈ': 'h', 'Ｉ': 'i', 'Ｊ': 'j',
    'Ｋ': 'k', 'Ｌ': 'l', 'Ｍ': 'm', 'Ｎ': 'n', 'Ｏ': 'o',
    'Ｐ': 'p', 'Ｑ': 'q', 'Ｒ': 'r', 'Ｓ': 's', 'Ｔ': 't',
    'Ｕ': 'u', 'Ｖ': 'v', 'Ｗ': 'w', 'Ｘ': 'x', 'Ｙ': 'y', 'Ｚ': 'z',
    'ａ': 'a', 'ｂ': 'b', 'ｃ': 'c', 'ｄ': 'd', 'ｅ': 'e',
    'ｆ': 'f', 'ｇ': 'g', 'ｈ': 'h', 'ｉ': 'i', 'ｊ': 'j',
    'ｋ': 'k', 'ｌ': 'l', 'ｍ': 'm', 'ｎ': 'n', 'ｏ': 'o',
    'ｐ': 'p', 'ｑ': 'q', 'ｒ': 'r', 'ｓ': 's', 'ｔ': 't',
    'ｕ': 'u', 'ｖ': 'v', 'ｗ': 'w', 'ｘ': 'x', 'ｙ': 'y', 'ｚ': 'z',
    // Latin look-alikes
    'ƒ': 'f', 'ß': 'ss', 'ø': 'o', 'đ': 'd', 'ð': 'd',
    'æ': 'ae', 'œ': 'oe',
  };

  // ── Accents to strip (common diacritics → base letter) ─────────────
  static const _accentMap = <String, String>{
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y', 'ñ': 'n', 'ç': 'c',
  };

  /// Normalize input to defeat evasion techniques.
  ///
  /// Pipeline:
  /// 1. Lowercase
  /// 2. Strip accents (ü→u, é→e, etc.)
  /// 3. De-leet + resolve homoglyphs (@ → a, 0 → o, Cyrillic а → a)
  /// 4. Remove non-letter separators (dots, dashes, underscores, spaces, emoji)
  /// 5. Collapse repeated letters (fuuuck → fuck, fukkboy → fukboy)
  static String _normalize(String input) {
    final lower = input.toLowerCase();

    // Step 1+2+3: char-by-char mapping
    final buf = StringBuffer();
    for (var i = 0; i < lower.length; i++) {
      final char = lower[i];
      final mapped = _accentMap[char] ?? _leetMap[char] ?? char;
      buf.write(mapped);
    }
    var result = buf.toString();

    // Step 4: strip non-letter chars (keep only a-z)
    result = result.replaceAll(RegExp(r'[^a-z]'), '');

    // Step 5: collapse runs of same letter (2+ → 1)
    // "fuuuck" → "fuck", "fukkboy" → "fukboy"
    // NOTE: Must use replaceAllMapped — Dart's replaceAll doesn't
    // support backreferences ($1).
    result = result.replaceAllMapped(
      RegExp(r'(.)\1+'),
      (m) => m.group(1)!,
    );

    return result;
  }

  // ── English blocklist ──────────────────────────────────────────────
  // Include both canonical + common leet-normalized forms so that
  // both "fuck" (normalized from "f.u.c.k") and "fack" (from "f4ck")
  // are caught.
  static const _english = <String>[
    // Profanity / sexual — canonical
    'fuck', 'shit', 'ass', 'asshole', 'bitch', 'bastard', 'cunt',
    'dick', 'cock', 'pussy', 'whore', 'slut', 'wanker', 'twat',
    'bollocks', 'prick', 'motherfucker', 'fucker', 'fuckboy',
    'fuckface', 'fukboy', 'dumbass', 'jackass', 'dipshit', 'shithead',
    'blowjob', 'handjob', 'dildo', 'orgasm', 'penis', 'vagina',
    'boobs', 'tits', 'cum', 'jizz', 'porn', 'anal', 'anus',
    // Common leet re-spellings (4=a mapping produces these)
    'fack', 'shat', 'dack', 'cack',
    // Slurs / hate
    'nigger', 'nigga', 'faggot', 'fag', 'retard', 'tranny',
    'spic', 'chink', 'gook', 'kike', 'wetback', 'beaner',
    'cracker', 'honky', 'coon', 'darkie', 'negro',
    'dyke', 'homo',
    // Extremism
    'nazi', 'hitler', 'heil', 'jihad', 'isis', 'alqaeda',
    'kkk', 'aryan', 'whitesupremacy', 'whitepower',
  ];

  // ── Swedish blocklist ──────────────────────────────────────────────
  static const _swedish = <String>[
    'fan', 'javla', 'javlar', 'helvete', 'skit', 'fitta',
    'kuk', 'hora', 'bog', 'neger', 'blatte', 'svansen',
    'knull', 'knulla', 'ransen', 'arsle', 'idiot',
    'cp', 'mongo', 'subba', 'slansen',
  ];

  /// Pre-normalized blocklist: each word is run through [_normalize] once at
  /// class load time so runtime checks are fast set lookups.
  static final Set<String> _normalizedBlocklist = {
    for (final w in _english) _normalize(w),
    for (final w in _swedish) _normalize(w),
  };

  /// Returns `true` if [name] is considered offensive.
  ///
  /// The name is normalized (de-leet, collapse repeats, strip separators)
  /// before checking, so "Fukkboy", "f.u.c.k", "sh1t", "a$$", "fück"
  /// and Cyrillic homoglyphs are all caught.
  static bool isOffensive(String name) {
    final normalized = _normalize(name.trim());
    if (normalized.isEmpty) return false;

    // 1. Exact match against normalized blocklist
    if (_normalizedBlocklist.contains(normalized)) return true;

    // 2. Substring match — only for normalized words ≥ 4 chars
    //    to limit false positives (e.g. "Ash" shouldn't trigger "ass",
    //    but "Fuckboy" should still trigger "fuck").
    for (final word in _normalizedBlocklist) {
      if (word.length >= 4 && normalized.contains(word)) return true;
    }

    return false;
  }
}
