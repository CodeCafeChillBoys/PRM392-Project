import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Central, swappable configuration for the TechStoreAPI backend.
///
/// The backend is not ready yet, so [AppConfig.useMockData] is `true` and the
/// services in `data/services/` return mock data. When the backend is live:
///   1. Point [baseUrl] at the real host (or read it from a build-time env var).
///   2. Flip [AppConfig.useMockData] to `false`.
///   3. The endpoint paths below already mirror the TechStoreAPI DTOs/routes,
///      so the service layer can call them without touching the UI.
///
/// Keep ALL endpoint strings here — never hard-code a URL inside a screen,
/// widget, or service body.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the TechStoreAPI. Swap this single constant to retarget the
  /// app (local emulator, staging, production).
  ///
  /// Handy values while developing against a local backend:
  ///   * Android emulator → `http://10.0.2.2:5173`
  ///   * iOS simulator / web / desktop → `http://localhost:5173`
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5173';
    }
    try {
      if (Platform.isAndroid) {
        // Máy ảo Android → 10.0.2.2 = localhost của PC (demo hằng ngày).
        // ĐIỆN THOẠI THẬT: đổi thành 'http://localhost:5173' + `adb reverse
        // tcp:5173 tcp:5173` (qua cáp), hoặc URL tunnel (ngrok/cloudflared) khi đi 4G.
        return 'http://10.0.2.2:5173';
      }
    } catch (_) {}
    return 'http://localhost:5173';
  }

  /// Default network timeout for requests. BE localhost trả lời ~60-150ms nên
  /// 12s là dư; ngắn hơn 20s để lỗi mạng ảo emulator surface nhanh (đỡ "xoay lâu")
  /// và giới hạn tổng thời gian khi ApiClient.get auto-retry.
  static const Duration timeout = Duration(seconds: 12);

  // ----------------------------------------------------------------------
  // Auth — mirrors "Luồng BE / Register" (email-link OR email-OTP verify).
  // ----------------------------------------------------------------------
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String googleLogin = '/api/auth/google-login';

  /// Request an email magic-link to verify/sign in.
  static const String sendEmailLink = '/api/auth/send-verify-link';

  /// Request a 6-digit OTP to the user's email.
  static const String sendOtp = '/api/auth/send-otp';

  /// Verify the 6-digit OTP.
  static const String verifyOtp = '/api/auth/verify-otp';

  /// Check current status of the magic link sign-in session.
  static const String sessionStatus = '/api/auth/session-status';

  // ----------------------------------------------------------------------
  // Products — mirrors "API Design (TechStoreAPI) / Product".
  // ----------------------------------------------------------------------
  static const String products = '/api/Products';
  static String productById(String id) => '/api/Products/$id';
  static const String categories = '/api/Category';
  // ----------------------------------------------------------------------
  // Cart — mirrors "TechStoreAPI / Cart" (add / update-qty / remove).
  // ----------------------------------------------------------------------
  static String cartByUserId(String userId) => '/api/Carts/user/$userId';
  static const String cartAdd = '/api/Carts/add';
  static String cartItemById(String id) => '/api/Carts/$id';
  static String cartClear(String userId) => '/api/Carts/clear/$userId';

  // ----------------------------------------------------------------------
  // Order / Checkout — mirrors "Checkout & Billing".
  // ----------------------------------------------------------------------
  static const String checkout = '/api/order/checkout';
  static const String orders = '/api/Orders';
  static String orderById(String id) => '/api/Orders/$id';
  static String ordersByUser(String userId) => '/api/Orders/user/$userId';
  static String orderStatusById(String id) => '/api/Orders/$id/status';

  /// VNPay payment-gateway hand-off path (used by both the mock and real flows).
  static String vnpayGateway(String orderId) => '/payment/vnpay?order=$orderId';

  // ----------------------------------------------------------------------
  // Wallet — "Ví TechStore": nạp tiền qua VNPay + thanh toán bằng số dư.
  // ----------------------------------------------------------------------
  static const String wallet = '/api/wallet';
  static const String walletTransactions = '/api/wallet/transactions';
  static const String walletTopUp = '/api/wallet/top-up';

  // ----------------------------------------------------------------------
  // Shipping (Goong qua BE) — tính phí theo khoảng cách thực tế.
  // ----------------------------------------------------------------------
  static const String shippingCalculate = '/api/shipping/calculate';

  // ----------------------------------------------------------------------
  // Tracking giao hàng realtime (SignalR + REST) — dùng ở giai đoạn sau.
  // ----------------------------------------------------------------------
  /// SignalR hub theo dõi vị trí shipper realtime.
  static const String trackingHub = '/trackingHub';

  /// Lấy vị trí shipper hiện tại của 1 đơn (gọi lần đầu khi mở map).
  static String trackingByOrder(String orderId) => '/api/tracking/order/$orderId';

  /// Shipper cập nhật vị trí của mình.
  static const String trackingLocation = '/api/tracking/location';

  /// Gán shipper cho đơn (Staff) — kèm `?staffId=<guid>`.
  static String assignShipper(String orderId) => '/api/orders/$orderId/assign-shipper';

  /// Xác nhận giao hàng + ảnh (Staff, multipart).
  static String confirmDelivery(String orderId) => '/api/orders/$orderId/confirm-delivery';

  // ----------------------------------------------------------------------
  // Notifications.
  // ----------------------------------------------------------------------
  static const String notifications = '/api/notifications';
  static String markNotificationRead(String id) => '/api/notifications/$id/read';
  static const String markAllNotificationsRead = '/api/notifications/read-all';

  // ----------------------------------------------------------------------
  // Chat AI — "Trợ lý TechStore" (Gemini phía BE, không lưu history).
  // ----------------------------------------------------------------------
  static const String chat = '/api/Chat';

  // ----------------------------------------------------------------------
  // Admin — quản trị & giám sát vận hành (CHỈ role Admin; JWT policy AdminOnly).
  // Mirror UsersController + AdminController phía BE.
  // ----------------------------------------------------------------------
  /// Danh sách người dùng (kèm `?role=Customer|Staff|Admin` để lọc).
  static const String usersList = '/api/users';
  static String userById(String id) => '/api/users/$id';

  /// Đổi role người dùng (PUT body `{role}`) — đường an toàn thay set-role cũ.
  static String userRole(String id) => '/api/users/$id/role';

  /// Thống kê tổng hợp cho dashboard (kèm `?from=&to=` ISO-8601 UTC).
  static const String adminStats = '/api/admin/stats';
  static const String adminSessions = '/api/admin/sessions';
  static const String adminDevices = '/api/admin/devices';

  /// Sản phẩm sắp hết hàng (kèm `?threshold=10`).
  static const String adminLowStock = '/api/admin/products/low-stock';

  /// Cập nhật tồn kho 1 sản phẩm (PUT body `{stockQuantity}`).
  static String adminProductStock(String id) => '/api/admin/products/$id/stock';

  /// Build an absolute URL from one of the endpoint constants above.
  static Uri uri(String endpoint, [Map<String, dynamic>? query]) {
    final base = Uri.parse('$baseUrl$endpoint');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        ...query.map((k, v) => MapEntry(k, '$v')),
      },
    );
  }
}
