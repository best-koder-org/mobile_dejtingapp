import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';

/// Parses the backend's "#RRGGBB" anonymous colour.
Color forumColorFromHex(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return const Color(0xFFFF7F50);
  return Color(0xFF000000 | value);
}

/// Localized display name for a channel slug.
///
/// The slugs are the wire format shared with the server, so they are never shown raw —
/// they only fall through when the server adds a channel this build doesn't know yet.
String forumChannelLabel(AppLocalizations l10n, String slug) {
  switch (slug) {
    case 'feedback':
      return l10n.channelFeedback;
    case 'first-dates':
      return l10n.channelFirstDates;
    case 'red-flags':
      return l10n.channelRedFlags;
    case 'vent':
      return l10n.channelVent;
    case 'success-stories':
      return l10n.channelSuccessStories;
    case 'ask':
      return l10n.channelAsk;
    default:
      return slug;
  }
}
