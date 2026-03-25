import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PayOSService {
  // ============================================================
  // TODO: Thay bang credentials cua ban tu PayOS Dashboard
  // Dang ky tai: https://my.payos.vn
  // ============================================================
  static const String _clientId = 'a9fddae8-14ab-419c-a0ed-3e2d8c04d386';
  static const String _apiKey = 'cc3e1923-9a6c-4b04-8489-e697c894c4ad';
  static const String _checksumKey = '7e17997773da5275ace665378f9d45a1c809106d1d3499b838d869e51f90d5fa';

  static const String _baseUrl = 'https://api-merchant.payos.vn/v2';

  /// Tao link thanh toan PayOS
  Future<Map<String, dynamic>> createPaymentLink({
    required int orderCode,
    required int amount,
    required String description,
    String? buyerName,
    String? buyerEmail,
    String? buyerPhone,
    String returnUrl = 'https://your-app.com/payment-success',
    String cancelUrl = 'https://your-app.com/payment-cancel',
  }) async {
    try {
      // Tao signature theo yeu cau PayOS
      // PayOS yeu cau: HMAC_SHA256(data, checksumKey)
      // data = "amount={amount}&cancelUrl={cancelUrl}&description={description}&orderCode={orderCode}&returnUrl={returnUrl}"
      final signData =
          'amount=$amount&cancelUrl=$cancelUrl&description=$description&orderCode=$orderCode&returnUrl=$returnUrl';

      final signature = _generateSignature(signData);

      final body = {
        'orderCode': orderCode,
        'amount': amount,
        'description': description,
        'returnUrl': returnUrl,
        'cancelUrl': cancelUrl,
        'signature': signature,
        if (buyerName != null) 'buyerName': buyerName,
        if (buyerEmail != null) 'buyerEmail': buyerEmail,
        if (buyerPhone != null) 'buyerPhone': buyerPhone,
        'items': [
          {
            'name': description,
            'quantity': 1,
            'price': amount,
          }
        ],
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/payment-requests'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': _clientId,
          'x-api-key': _apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '00') {
          return {
            'success': true,
            'checkoutUrl': data['data']['checkoutUrl'],
            'qrCode': data['data']['qrCode'],
            'orderCode': data['data']['orderCode'],
            'accountNumber': data['data']['accountNumber'],
            'accountName': data['data']['accountName'],
            'bin': data['data']['bin'],
            'amount': data['data']['amount'],
          };
        } else {
          return {
            'success': false,
            'message': data['desc'] ?? 'Tao link thanh toan that bai',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Loi server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Loi: $e',
      };
    }
  }

  /// Kiem tra trang thai thanh toan
  Future<Map<String, dynamic>> getPaymentStatus(int orderCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment-requests/$orderCode'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': _clientId,
          'x-api-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == '00') {
          return {
            'success': true,
            'status': data['data']['status'], // PAID, PENDING, CANCELLED
            'orderCode': data['data']['orderCode'],
            'amount': data['data']['amount'],
          };
        }
      }
      return {'success': false, 'message': 'Khong lay duoc trang thai'};
    } catch (e) {
      return {'success': false, 'message': 'Loi: $e'};
    }
  }

  /// Huy link thanh toan
  Future<bool> cancelPaymentLink(int orderCode) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payment-requests/$orderCode/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': _clientId,
          'x-api-key': _apiKey,
        },
        body: jsonEncode({'cancellationReason': 'User cancelled'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Tao HMAC SHA256 signature
  String _generateSignature(String data) {
    final key = utf8.encode(_checksumKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }
}
