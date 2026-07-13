import 'package:flutter/material.dart';

/// Maps the design system's Lucide icon names to Flutter [IconData].
///
/// The Stitch source uses Lucide line icons; Material's *_outlined glyphs are
/// the closest always-available, offline-safe match. Centralising the mapping
/// here means swapping to a real Lucide package later touches ONE file.
class AppIcons {
  AppIcons._();

  static const Map<String, IconData> _map = {
    // navigation / app bars
    'compass': Icons.explore_outlined,
    'search': Icons.search,
    'shopping-bag': Icons.shopping_bag_outlined,
    'shopping-cart': Icons.shopping_cart_outlined,
    'user': Icons.person_outline,
    'bell': Icons.notifications_none_rounded,
    'arrow-left': Icons.arrow_back_rounded,
    'arrow-right': Icons.arrow_forward_rounded,
    'chevron-right': Icons.chevron_right_rounded,
    'chevron-down': Icons.keyboard_arrow_down_rounded,
    'plus': Icons.add_rounded,
    'sliders-horizontal': Icons.tune_rounded,

    // status / feedback
    'check': Icons.check_rounded,
    'check-check': Icons.done_all_rounded,
    'check-circle': Icons.check_circle_outline_rounded,
    'x-circle': Icons.highlight_off_rounded,
    'shield-check': Icons.verified_user_outlined,
    'message-circle': Icons.chat_bubble_outline_rounded,

    // auth / forms
    'mail': Icons.mail_outline_rounded,
    'mail-check': Icons.mark_email_read_outlined,
    'mail-open': Icons.drafts_outlined,
    'lock': Icons.lock_outline_rounded,
    'eye': Icons.visibility_outlined,
    'eye-off': Icons.visibility_off_outlined,
    'phone': Icons.phone_outlined,
    'home': Icons.home_outlined,
    'map-pin': Icons.location_on_outlined,

    // commerce
    'trash-2': Icons.delete_outline_rounded,
    'ticket-percent': Icons.confirmation_number_outlined,
    'heart': Icons.favorite_border_rounded,
    'star': Icons.star_rounded,

    // shipping / payment
    'truck': Icons.local_shipping_outlined,
    'zap': Icons.bolt_rounded,
    'clock': Icons.schedule_rounded,
    'credit-card': Icons.credit_card_rounded,
    'qr-code': Icons.qr_code_2_rounded,
    'landmark': Icons.account_balance_outlined,
    'banknote': Icons.payments_outlined,
    'wallet': Icons.account_balance_wallet_outlined,
    'external-link': Icons.open_in_new_rounded,

    // promo / orders
    'tag': Icons.sell_outlined,
    'percent': Icons.percent_rounded,
    'gift': Icons.card_giftcard_rounded,
    'package-check': Icons.inventory_2_outlined,
    'package': Icons.inventory_2_outlined,
    'inbox': Icons.inbox_outlined,
    'bar-chart': Icons.bar_chart_rounded,
    'log-out': Icons.logout_rounded,
    'camera': Icons.photo_camera_outlined,
    'image': Icons.image_outlined,

    // device status bar
    'signal': Icons.signal_cellular_alt_rounded,
    'wifi': Icons.wifi_rounded,
    'battery-full': Icons.battery_full_rounded,

    // media / image upload
    'edit': Icons.edit_outlined,

    // chat AI
    'bot': Icons.smart_toy_outlined,
    'send': Icons.send_rounded,
  };

  /// Resolve a Lucide name to an [IconData], falling back to a neutral glyph.
  static IconData get(String name) => _map[name] ?? Icons.circle_outlined;
}
