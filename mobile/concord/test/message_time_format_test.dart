import 'package:concord/utils/message_time_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatShortTime renders a 12-hour "H:MM AM/PM" string', () {
    final utc = DateTime.utc(2026, 1, 1, 15, 5);
    expect(formatShortTime(utc), matches(RegExp(r'^\d{1,2}:\d{2} (AM|PM)$')));
  });

  test('formatGroupTimestamp labels a just-now message as "Today"', () {
    final now = DateTime.now().toUtc();
    expect(formatGroupTimestamp(now), startsWith('Today at '));
  });

  test('formatGroupTimestamp labels a message from exactly a day ago as "Yesterday"', () {
    final yesterday = DateTime.now().toUtc().subtract(const Duration(hours: 20));
    final formatted = formatGroupTimestamp(yesterday);
    expect(formatted.startsWith('Today at ') || formatted.startsWith('Yesterday at '), isTrue);
  });

  test('formatAbsoluteTimestamp renders a full date + time', () {
    final utc = DateTime.utc(2026, 3, 15, 9, 30);
    expect(formatAbsoluteTimestamp(utc), matches(RegExp(r'^[A-Z][a-z]{2} \d{1,2}, \d{4}, \d{1,2}:\d{2} (AM|PM)$')));
  });
}
