import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/state/app_nav.dart';
import 'presentation/state/cart_controller.dart';
import 'presentation/state/catalog_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  try {
    await LocalNotificationService.initialize();
  } catch (e) {
    debugPrint('Local Notification initialization failed: $e');
  }

  // Light status-bar icons on the near-black canvas.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Please configure Firebase or add google-services.json if you want to use Firebase features.');
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
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
class TechVoidApp extends StatelessWidget {
  const TechVoidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartController()),
        ChangeNotifierProvider(create: (_) => CatalogController()),
        ChangeNotifierProvider(create: (_) => AppNav()),
      ],
      child: MaterialApp(
        title: 'TECH_VOID',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const LoginScreen(),
        // Keep the layout phone-shaped (max 430px) and centered on wide screens
        // (web/desktop), matching the design's mobile canvas.
        builder: (context, child) => ColoredBox(
          color: const Color(0xFF060608),
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
      ),
    );
  }
}
