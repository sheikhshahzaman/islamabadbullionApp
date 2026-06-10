import "package:intl/intl.dart";
import "package:flutter/material.dart";

DateTime pakistanTimeFromUnixSeconds(int seconds) {
  // Treat API timestamp as UTC epoch seconds, then convert to Pakistan time (UTC+5).
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).add(const Duration(hours: 5));
}

String formatPakistanTime(int seconds, Locale locale) {
  if (seconds <= 0) return "-";
  final dt = pakistanTimeFromUnixSeconds(seconds);

  // Professional readable format; will localize month/day language where supported.
  final df = DateFormat("dd MMM, yyyy  h:mm a", locale.languageCode);
  return df.format(dt);
}
