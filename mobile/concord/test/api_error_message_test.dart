import 'package:concord/api/api.dart';
import 'package:concord/l10n/app_localizations_en.dart';
import 'package:concord/utils/api_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('apiErrorMessage', () {
    test('never leaks the underlying exception text for a network error', () {
      const exception = ApiException(
        ApiException.networkErrorStatusCode,
        'A network error occurred.',
      );

      final message = apiErrorMessage(l10n, exception);

      expect(message, l10n.errorCouldNotReachServer);
      expect(message.contains('localhost'), isFalse);
      expect(message.contains('SocketException'), isFalse);
    });

    test('maps a client-side timeout to the same friendly connectivity copy', () {
      const exception = ApiException(ApiException.timeoutStatusCode, 'The request timed out.');

      expect(apiErrorMessage(l10n, exception), l10n.errorCouldNotReachServer);
    });

    test('falls back to the server-trouble message for a 5xx with no useful body', () {
      const exception = ApiException(500, '');

      expect(apiErrorMessage(l10n, exception), l10n.errorServerTrouble);
    });

    test('shows a real backend validation message for a 4xx as-is', () {
      const exception = ApiException(400, 'Enter a valid email address');

      expect(apiErrorMessage(l10n, exception), 'Enter a valid email address');
    });
  });
}
