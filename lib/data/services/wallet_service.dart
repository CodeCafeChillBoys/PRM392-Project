import '../../core/config/api_config.dart';
import '../../core/config/app_config.dart';
import '../models/wallet_model.dart';
import '../models/wallet_transaction.dart';
import 'api_client.dart';

/// Đọc/ghi Ví TechStore — `GET /api/wallet`, `GET /api/wallet/transactions`,
/// `POST /api/wallet/top-up` (mở cổng VNPay để nạp). Returns mock data while
/// [AppConfig.useMockData].
class WalletService {
  WalletService({ApiClient? client}) : _client = client ?? apiClient;

  final ApiClient _client;

  Future<WalletModel> fetchWallet() async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return const WalletModel(balance: 0, updatedAt: null);
    }
    final json = await _client.get(ApiConfig.wallet);
    return WalletModel.fromJson(json as Map<String, dynamic>);
  }

  Future<List<WalletTransaction>> fetchTransactions({
    int skip = 0,
    int take = 50,
  }) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return const [];
    }
    final json = await _client.get(ApiConfig.walletTransactions, query: {
      'skip': skip,
      'take': take,
    });
    final List<dynamic> list =
        (json is Map<String, dynamic> && json['data'] is List)
            ? (json['data'] as List)
            : (json is List ? json : []);
    return list
        .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Tạo giao dịch nạp tiền → BE trả URL cổng VNPay để mở (`launchUrl` phía UI).
  Future<({String transactionId, String paymentUrl})> createTopUp(
      double amount) async {
    if (AppConfig.useMockData) {
      await Future.delayed(AppConfig.mockLatency);
      return (
        transactionId: 'mock-topup-${amount.round()}',
        paymentUrl: '${ApiConfig.baseUrl}${ApiConfig.vnpayGateway('mock-topup')}',
      );
    }
    final json = await _client.post(ApiConfig.walletTopUp, body: {
      'amount': amount,
    }) as Map<String, dynamic>;
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return (
      transactionId: '${data['transactionId'] ?? ''}',
      paymentUrl: '${data['paymentUrl'] ?? ''}',
    );
  }
}
