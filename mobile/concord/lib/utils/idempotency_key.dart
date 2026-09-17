import 'dart:math';

/// A fresh idempotency key for one spend attempt (transfer, trial activation).
/// Generated once per attempt and reused verbatim while the user retries *that
/// same* attempt, so a double-tap or a retried request can't spend twice;
/// regenerated once the attempt finally succeeds or the form is reopened.
///
/// This is a RFC 4122 version-4 UUID built from [Random.secure] rather than a
/// `uuid` package dependency - the app needs exactly this one function, and the
/// backend only requires the key to be a non-blank string that's unique per
/// attempt (it's stored and compared verbatim, never parsed as a UUID).
String newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
      '-${hex.substring(16, 20)}-${hex.substring(20)}';
}
