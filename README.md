# TECH_VOID — TechStore (Flutter FE)

A dark, neon-cyberpunk **tech e-commerce mobile app** (Vietnamese) — the Flutter
front-end for **TechStoreAPI**. Built for the **PRM (mobile programming)** course
at FPT University, from the *TECH_VOID Design System*.

The backend isn't ready yet, so every screen runs on **mock data** served by the
service layer. All API endpoints + `baseUrl` are **configurable constants**, so
switching to the real backend is a two-line change (see *Connecting the backend*).

## Run

```bash
flutter pub get
flutter run            # pick an Android/iOS device or emulator
# or, for a quick preview:
flutter run -d chrome
```

> Fonts (Chakra Petch · Be Vietnam Pro · JetBrains Mono) load via `google_fonts`
> and are cached after first launch. The first run needs network; offline it
> falls back to a system font. To ship fully offline, bundle the `.ttf` files
> and declare them under `flutter: fonts:` in `pubspec.yaml`.

## Architecture — layered / Clean Architecture

```
lib/
├─ main.dart                      # App entry, providers, theme, phone-frame on wide screens
├─ core/
│  ├─ config/
│  │  ├─ api_config.dart          # ⭐ baseUrl + ALL endpoints (swap here)
│  │  └─ app_config.dart          # useMockData flag, mock latency, layout consts
│  ├─ theme/                      # design tokens → Flutter
│  │  ├─ app_colors.dart  app_typography.dart  app_spacing.dart
│  │  ├─ app_effects.dart (shadows/glows/gradients)  app_theme.dart  app_icons.dart
│  └─ utils/formatters.dart       # VND currency (34.990.000đ), mm:ss countdown
├─ data/
│  ├─ models/                     # DTO-shaped: Product, CartItem, PaymentMethod,
│  │                              #   ShippingOption, AppNotification (+ fromJson/toJson)
│  └─ services/
│     ├─ api_client.dart          # thin http wrapper (dormant until backend is live)
│     ├─ mock_data.dart           # in-memory sample data (port of the design's data.js)
│     ├─ product_service.dart  cart_service.dart  auth_service.dart
│     ├─ order_service.dart    notification_service.dart
└─ presentation/
   ├─ state/                      # CartController, AppNav (provider / ChangeNotifier)
   ├─ routing/app_routes.dart
   ├─ widgets/                    # 20-component library mirroring the design system
   │                              #   (TvButton, TvAppBar, ProductCard, TvOptionRow, …)
   └─ screens/
      ├─ auth/   (login, register, method, email_wait, otp)
      ├─ shop/   (product_list, product_detail, cart, checkout)
      ├─ notifications/  profile/
      └─ root_shell.dart          # bottom-nav shell (Explore / Search / Cart / Profile)
```

**Dependency direction:** `presentation → data → core`. The UI never builds a URL
or knows whether data is mock or live — it only talks to services.

## Connecting the backend

Everything funnels through two files:

1. **`lib/core/config/api_config.dart`** — point `baseUrl` at the real host. The
   endpoint paths already mirror TechStoreAPI (`/api/Products`, `/api/Cart`,
   `/api/auth/*`, `/api/order/checkout`). Add the auth header in
   `api_client.dart`'s `_headers` once login returns a token.
2. **`lib/core/config/app_config.dart`** — set `useMockData = false`.

That's it — every service has a real-HTTP branch ready (`apiClient.get/post/put/delete`)
and the models already (de)serialise the documented DTOs.

```dart
// api_config.dart
static const String baseUrl = 'https://api.techstore.vn'; // ← change me
// Android emulator → http://10.0.2.2:5000 · iOS/web → http://localhost:5000
```

## Screens & flow

`Login → verify method (Email Link | OTP) → email-wait / 6-box OTP → Home`.
`Home (search · categories · grid) → Detail → Cart → Checkout → success`.
Bell → Notifications. Bottom nav: Explore / Search / Cart / Profile.

## Notes

- Product images under `assets/products/` are cropped from the design export —
  swap for production photography. `ProductImage` auto-switches to network
  loading once the backend returns `http(s)` image URLs.
- Numbers (voucher, shipping fees) are illustrative sample values.
- Mock services add a small artificial delay (`AppConfig.mockLatency`) so loading
  spinners behave exactly as they will against the real network.
