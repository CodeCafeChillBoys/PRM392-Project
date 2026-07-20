import '../../core/config/api_config.dart';
import '../models/wallet.dart';
import '../models/wallet_transaction.dart';
import 'api_client.dart';

/// Gọi `WalletController`. Tất cả cần token (ApiClient tự đính JWT).
/// Envelope BE: `{success, message?, data}`. Lỗi non-2xx → [ApiException] với
/// message tiếng Việt của BE (UI bắt để hiện toast).
class WalletService {
  WalletService({ApiClient? client}) : _client = client ?? apiClient;
  final ApiClient _client;

  /// Số dư ví hiện tại. Tạo ví tự động phía BE nếu chưa có.
  Future<Wallet> fetchWallet() async {
    final json = await _client.get(ApiConfig.wallet);
    return Wallet.fromJson(_data(json));
  }

  /// Lịch sử giao dịch (phân trang skip/take).
  Future<List<WalletTransaction>> fetchTransactions({
    int skip = 0,
    int take = 20,
  }) async {
    final json = await _client.get(
      ApiConfig.walletTransactions,
      query: {'skip': skip, 'take': take},
    );
    final raw = json is Map ? (json['data'] ?? const []) : json;
    return (raw as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(WalletTransaction.fromJson)
        .toList();
  }

  /// Tạo giao dịch nạp (pending) → trả URL VNPay để mở như luồng checkout.
  /// Trả chuỗi rỗng nếu BE không kèm paymentUrl.
  Future<String> topUp(double amount) async {
    final json = await _client.post(
      ApiConfig.walletTopUp,
      body: {'amount': amount},
    );
    return '${_data(json)['paymentUrl'] ?? ''}';
  }

  /// Rút về ngân hàng — BE trừ ngay. Ném [ApiException] nếu vi phạm điều kiện
  /// (tối thiểu 50.000₫, số dư phải > 50.000₫).
  Future<WalletTransaction> withdraw({
    required double amount,
    required String bankName,
    required String bankAccountNumber,
    required String accountHolderName,
  }) async {
    final json = await _client.post(
      ApiConfig.walletWithdraw,
      body: {
        'amount': amount,
        'bankName': bankName,
        'bankAccountNumber': bankAccountNumber,
        'accountHolderName': accountHolderName,
      },
    );
    return WalletTransaction.fromJson(_data(json));
  }

  /// Bóc `data` khỏi envelope `{success, data}`; nếu BE trả thẳng object thì
  /// dùng nguyên.
  static Map<String, dynamic> _data(dynamic json) {
    if (json is Map<String, dynamic>) {
      final d = json['data'];
      return d is Map<String, dynamic> ? d : json;
    }
    return <String, dynamic>{};
  }
}

/// Instance dùng chung cho tầng UI.
final WalletService walletService = WalletService();
