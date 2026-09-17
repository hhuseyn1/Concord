import 'enums.dart';
import 'json_utils.dart';

/// One row of the Stars ledger from `GET Stars/Transactions`.
class StarTransactionResponse {
  const StarTransactionResponse({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.counterpartyUsername,
    required this.created,
  });

  factory StarTransactionResponse.fromJson(Map<String, dynamic> json) {
    return StarTransactionResponse(
      id: json.field('Id') as String,
      type: StarTransactionType.fromWire(json.field('Type')),
      amount: json.field('Amount') as int? ?? 0,
      balanceAfter: json.field('BalanceAfter') as int? ?? 0,
      // Server-resolved; null unless this row is a transfer.
      counterpartyUsername: json.field('CounterpartyUsername') as String?,
      created: parseDateTime(json.field('Created')),
    );
  }

  final String id;
  final StarTransactionType type;
  final int amount;
  final int balanceAfter;
  final String? counterpartyUsername;
  final DateTime created;

  /// The amount as it should be *displayed*, signed. The backend already
  /// stores debits as negative numbers, but this falls back to inferring the
  /// sign from [type] so the list stays correct if a row ever arrives as a
  /// bare magnitude (same defensive rule as the web app's `starsFormat.js`).
  int get signedAmount {
    if (amount < 0) return amount;
    return type.isDebit ? -amount : amount;
  }
}
