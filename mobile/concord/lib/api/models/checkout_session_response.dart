import 'json_utils.dart';

class CheckoutSessionResponse {
  const CheckoutSessionResponse({required this.url});

  factory CheckoutSessionResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutSessionResponse(url: json.field('Url') as String);
  }

  final String url;
}
