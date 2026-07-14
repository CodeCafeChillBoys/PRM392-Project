import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/state/app_nav.dart';
import 'presentation/state/cart_controller.dart';
import 'presentation/state/catalog_controller.dart';
import 'presentation/state/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/services/local_notification_service.dart';
import 'data/services/recently_viewed_service.dart';
import 'presentation/screens/shop/payment_result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  try {
    await LocalNotificationService.initialize();
  } catch (e) {
    debugPrint('Local Notification initialization failed: $e');
  }

  // Nạp danh sách "vừa xem" (local) trước khi dựng Home.
  await RecentlyViewedService.instance.load();

  // Light status-bar icons on the near-black canvas.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Please configure Firebase or add google-services.json if you want to use Firebase features.');
  }
  // Mặc định LIGHT (VOID PAPER) → icon status bar tối trên nền giấy sáng.
  // ThemeController tự cập nhật lại khi người dùng đổi theme/khôi phục pref.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const TechVoidApp());
}

/// TECH_VOID — Vietnamese tech e-commerce storefront (TechStore).
///
/// Clean Architecture layering:
///   * `core/`         — config (swappable [ApiConfig]), theme tokens, utils
///   * `data/models`   — DTO-shaped models
///   * `data/services` — API/mock data sources (mock while backend is offline)
///   * `presentation/` — screens, widgets and state
class TechVoidApp extends StatefulWidget {
  const TechVoidApp({super.key});

  @override
  State<TechVoidApp> createState() => _TechVoidAppState();
}

class _TechVoidAppState extends State<TechVoidApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
  }

  void _initDeepLinking() {
    _appLinks = AppLinks();

    // Handle links when app is running in background/foreground
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Incoming deep link: $uri');
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Deep link error: $err');
    });

    // Handle initial link if app was closed
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        debugPrint('Initial deep link: $uri');
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'payment-result' || uri.path == '/payment-result' || uri.path == 'payment-result') {
      final success = uri.queryParameters['success'] == 'true';
      final orderId = uri.queryParameters['orderId'] ?? '';
      final amount = double.tryParse(uri.queryParameters['amount'] ?? '') ?? 0.0;
      final paymentMethod = uri.queryParameters['paymentMethod'] ?? 'VNPay';

      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => PaymentResultScreen(
            success: success,
            orderId: orderId,
            totalAmount: amount,
            paymentMethod: paymentMethod,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => CatalogController()),
        ChangeNotifierProvider(create: (_) => AppNav()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      // Watch ThemeController để MaterialApp (theme, letterbox) rebuild khi
      // đổi VOID LUXE (dark) ↔ VOID PAPER (light).
      child: Builder(builder: (context) {
        context.watch<ThemeController>();
        return MaterialApp(
        title: 'TECH_VOID',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.current(),
        // Key theo theme: LoginScreen là const nên không tự rebuild khi
        // ThemeController notify (vd pref light nạp xong sau khi màn đã dựng).
        home: KeyedSubtree(
          key: ValueKey('home-${AppColors.isLight}'),
          child: const LoginScreen(),
        ),
        onGenerateRoute: (settings) {
          final name = settings.name;
          if (name == null) return null;

          final uri = Uri.tryParse(name);
          if (uri == null) return null;

          if (uri.host == 'payment-result' || uri.path == '/payment-result' || uri.path == 'payment-result') {
            final success = uri.queryParameters['success'] == 'true';
            final orderId = uri.queryParameters['orderId'] ?? '';
            final amount = double.tryParse(uri.queryParameters['amount'] ?? '') ?? 0.0;
            final paymentMethod = uri.queryParameters['paymentMethod'] ?? 'VNPay';

            return MaterialPageRoute(
              builder: (_) => PaymentResultScreen(
                success: success,
                orderId: orderId,
                totalAmount: amount,
                paymentMethod: paymentMethod,
              ),
            );
          }
          return null;
        },
        // Keep the layout phone-shaped (max 430px) and centered on wide screens
        // (web/desktop), matching the design's mobile canvas.
        builder: (context, child) => ColoredBox(
          // Letterbox theo theme: void-black (dark) / giấy sẫm nhẹ (light).
          color: AppColors.isLight
              ? const Color(0xFFEDE8DF)
              : const Color(0xFF030303),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConfig.appMaxWidth,
              ),
              child: ColoredBox(
                color: AppColors.bgBase,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        );
      }),
    );
  }
}
