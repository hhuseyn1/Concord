library;

import '../l10n/app_localizations.dart';

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _time(AppLocalizations l10n, DateTime local) {
  final hour24 = local.hour;
  final period = hour24 >= 12 ? l10n.pmLabel : l10n.amLabel;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

String _dateTime(DateTime local) {
  final day = _twoDigits(local.day);
  final month = _twoDigits(local.month);
  final hour = _twoDigits(local.hour);
  final minute = _twoDigits(local.minute);
  return '$day.$month.${local.year}, $hour:$minute';
}

String formatShortTime(AppLocalizations l10n, DateTime utc) => _time(l10n, utc.toLocal());

String formatGroupTimestamp(AppLocalizations l10n, DateTime utc) {
  final date = utc.toLocal();
  final now = DateTime.now();
  if (_isSameDay(date, now)) return l10n.todayAtLabel(_time(l10n, date));
  final yesterday = now.subtract(const Duration(days: 1));
  if (_isSameDay(date, yesterday)) return l10n.yesterdayAtLabel(_time(l10n, date));
  return _dateTime(date);
}

String formatAbsoluteTimestamp(DateTime utc) => _dateTime(utc.toLocal());

String formatRelativeTime(AppLocalizations l10n, DateTime utc) {
  final diff = DateTime.now().difference(utc.toLocal());
  if (diff.inMinutes < 1) return l10n.justNowLabel;
  if (diff.inMinutes < 60) return l10n.minutesAgoLabel(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgoLabel(diff.inHours);
  return l10n.daysAgoLabel(diff.inDays);
}
