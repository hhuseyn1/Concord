library;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _time(DateTime local) {
  final hour24 = local.hour;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $period';
}

String _dateTime(DateTime local) {
  return '${_months[local.month - 1]} ${local.day}, ${local.year}, ${_time(local)}';
}

String formatShortTime(DateTime utc) => _time(utc.toLocal());

String formatGroupTimestamp(DateTime utc) {
  final date = utc.toLocal();
  final now = DateTime.now();
  if (_isSameDay(date, now)) return 'Today at ${_time(date)}';
  final yesterday = now.subtract(const Duration(days: 1));
  if (_isSameDay(date, yesterday)) return 'Yesterday at ${_time(date)}';
  return _dateTime(date);
}

String formatAbsoluteTimestamp(DateTime utc) => _dateTime(utc.toLocal());
