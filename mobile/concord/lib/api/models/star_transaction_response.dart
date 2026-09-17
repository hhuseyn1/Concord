import 'enums.dart';
import 'json_utils.dart';

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

  int get signedAmount {
    if (amount < 0) return amount;
    return type.isDebit ? -amount : amount;
  }
}
