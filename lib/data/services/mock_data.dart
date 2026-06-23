import '../models/app_notification.dart';
import '../models/cart_item.dart';
import '../models/payment_method.dart';
import '../models/product.dart';
import '../models/shipping_option.dart';

/// In-memory sample data — a faithful port of `ui_kits/techvoid-app/data.js`,
/// with shapes aligned to TechStoreAPI DTOs. Used by the service layer while
/// [AppConfig.useMockData] is `true`.
///
/// Image URLs point at bundled assets; once the backend is live it returns
/// `http(s)` URLs and the [ProductImage] widget switches to network loading
/// automatically.
class MockData {
  MockData._();

  static const List<String> categories = [
    'Tất cả',
    'Điện thoại',
    'Laptop',
    'Máy tính bảng',
    'Phụ kiện',
  ];

  static const List<Product> products = [
    Product(
      id: 'ip15pm',
      name: 'iPhone 15 Pro Max',
      brand: 'Apple',
      categoryName: 'Điện thoại',
      price: 34990000,
      stockQuantity: 24,
      imageUrl: 'assets/products/iphone-list.png',
      heroImageUrl: 'assets/products/iphone-detail.png',
      description:
          'Khung Titanium chuẩn hàng không vũ trụ, chip A17 Pro 6 nhân mạnh mẽ, '
          'camera 48MP và cổng USB-C. Màn hình 6.7" Super Retina XDR ProMotion 120Hz.',
    ),
    Product(
      id: 'sgs24',
      name: 'Samsung Galaxy S24 Ultra',
      brand: 'Samsung',
      categoryName: 'Điện thoại',
      price: 29990000,
      stockQuantity: 12,
      imageUrl: 'assets/products/samsung-list.png',
      description:
          'Galaxy AI, bút S Pen tích hợp, camera 200MP zoom quang 5x. Khung Titanium, '
          'màn hình Dynamic AMOLED 2X 6.8" siêu sáng.',
    ),
    Product(
      id: 'mbp',
      name: 'MacBook Pro 14" M3',
      brand: 'Apple',
      categoryName: 'Laptop',
      price: 74990000,
      stockQuantity: 6,
      imageUrl: 'assets/products/macbook-list.png',
      description:
          'Chip Apple M3 với CPU 8 nhân và GPU 10 nhân, 18GB RAM hợp nhất, SSD 512GB. '
          'Màn hình Liquid Retina XDR, thời lượng pin lên đến 22 giờ.',
    ),
    Product(
      id: 'ipadpro',
      name: 'iPad Pro M2 12.9"',
      brand: 'Apple',
      categoryName: 'Máy tính bảng',
      price: 26490000,
      stockQuantity: 0,
      imageUrl: 'assets/products/ipad-list.png',
      description:
          'Chip M2, màn hình Liquid Retina XDR 12.9" mini-LED, hỗ trợ Apple Pencil hover. '
          'Kết nối Thunderbolt / USB 4 tốc độ cao.',
    ),
    Product(
      id: 'sony',
      name: 'Sony WH-1000XM5',
      brand: 'Sony',
      categoryName: 'Phụ kiện',
      price: 8490000,
      stockQuantity: 40,
      imageUrl: 'assets/products/iphone-cart.png',
      description:
          'Tai nghe chống ồn đầu bảng với 8 micro và 2 chip xử lý. Thời lượng pin 30 giờ, '
          'sạc nhanh, âm thanh Hi-Res Wireless.',
    ),
  ];

  /// Seed cart (CartResponseDTO shape).
  static List<CartItem> get cart => const [
        CartItem(
          id: 'c1',
          productId: 'ip15pm',
          productName: 'iPhone 15 Pro Max',
          brand: 'Apple',
          productImageUrl: 'assets/products/iphone-list.png',
          unitPrice: 34990000,
          quantity: 1,
        ),
        CartItem(
          id: 'c2',
          productId: 'ipadpro',
          productName: 'iPad Pro M2 12.9"',
          brand: 'Apple',
          productImageUrl: 'assets/products/ipad-list.png',
          unitPrice: 26490000,
          quantity: 1,
        ),
        CartItem(
          id: 'c3',
          productId: 'sony',
          productName: 'Sony WH-1000XM5',
          brand: 'Sony',
          productImageUrl: 'assets/products/iphone-cart.png',
          unitPrice: 8490000,
          quantity: 1,
        ),
      ];

  static const List<PaymentMethod> paymentMethods = [
    PaymentMethod(
      value: 'VNPay',
      iconName: 'qr-code',
      title: 'Ví VNPay',
      subtitle: 'Khuyên dùng · QR / thẻ ATM nội địa',
    ),
    PaymentMethod(
      value: 'CreditCard',
      iconName: 'credit-card',
      title: 'Thẻ tín dụng / Ghi nợ',
      subtitle: 'Visa, Mastercard, JCB',
    ),
    PaymentMethod(
      value: 'BankTransfer',
      iconName: 'landmark',
      title: 'Chuyển khoản ngân hàng',
      subtitle: 'Chuyển khoản trực tiếp 24/7',
    ),
    PaymentMethod(
      value: 'COD',
      iconName: 'banknote',
      title: 'Thanh toán khi nhận hàng (COD)',
      subtitle: 'Tiền mặt khi giao tới',
    ),
  ];

  static const List<ShippingOption> shippingOptions = [
    ShippingOption(
      value: 'fast',
      iconName: 'zap',
      title: 'Hỏa tốc',
      subtitle: 'Nhận hàng trong 2h',
      fee: 35000,
    ),
    ShippingOption(
      value: 'std',
      iconName: 'clock',
      title: 'Tiêu chuẩn',
      subtitle: 'Dự kiến 2-3 ngày',
      fee: 15000,
    ),
  ];

  static const NotificationFeeds notifications = NotificationFeeds(
    promo: [
      AppNotification(
        iconName: 'tag',
        tone: NotificationTone.accent,
        unread: true,
        title: 'Deal hời: iPhone 15 Pro Max giảm 2 triệu',
        body: 'Ưu đãi có hạn dành riêng cho thành viên VIP. Kiểm tra ngay để không bỏ lỡ!',
        time: '10 phút trước',
      ),
      AppNotification(
        iconName: 'percent',
        tone: NotificationTone.violet,
        unread: false,
        title: 'Flash Sale: Đồ công nghệ giảm tới 50%',
        body: 'Hàng trăm sản phẩm tai nghe, chuột gaming đang chờ đón bạn.',
        time: '2 giờ trước',
      ),
      AppNotification(
        iconName: 'truck',
        tone: NotificationTone.accent,
        unread: true,
        title: 'Voucher vận chuyển 0đ đã sẵn sàng',
        body: 'Áp dụng cho mọi đơn hàng từ 500k trong hôm nay.',
        time: '5 giờ trước',
      ),
      AppNotification(
        iconName: 'gift',
        tone: NotificationTone.violet,
        unread: false,
        title: 'Chúc mừng sinh nhật TECH_VOID',
        body: 'Cùng nhìn lại hành trình 2 năm phát triển của cộng đồng công nghệ.',
        time: '1 ngày trước',
      ),
    ],
    orders: [
      AppNotification(
        iconName: 'check-circle',
        tone: NotificationTone.accent,
        unread: true,
        title: 'Đơn #TV24902 đã được xác nhận',
        body: 'Thanh toán VNPay thành công. Đơn hàng đang được chuẩn bị.',
        time: '20 phút trước',
      ),
      AppNotification(
        iconName: 'truck',
        tone: NotificationTone.violet,
        unread: true,
        title: 'Đơn #TV24871 đang vận chuyển',
        body: 'Dự kiến giao trong hôm nay, 14:00 - 18:00.',
        time: '6 giờ trước',
      ),
      AppNotification(
        iconName: 'package-check',
        tone: NotificationTone.accent,
        unread: false,
        title: 'Đơn #TV24817 đã giao thành công',
        body: 'Cảm ơn bạn đã mua sắm tại TECH_VOID!',
        time: '2 ngày trước',
      ),
    ],
  );
}
