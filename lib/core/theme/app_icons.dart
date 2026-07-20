import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Maps the design system's Lucide icon names to Flutter [IconData].
///
/// VOID LUXE: dùng bộ Lucide THẬT (lucide_icons_flutter, icon-font stroke
/// 1.5-2px) thay cho Material glyphs đội lốt — điểm "generic" lớn nhất của
/// giao diện cũ. String keys giữ nguyên nên 0 call-site phải đổi.
class AppIcons {
  AppIcons._();

  static const Map<String, IconData> _map = {
    // navigation / app bars
    'compass': LucideIcons.compass,
    'search': LucideIcons.search,
    'shopping-bag': LucideIcons.shoppingBag,
    'shopping-cart': LucideIcons.shoppingCart,
    'user': LucideIcons.user,
    'bell': LucideIcons.bell,
    'arrow-left': LucideIcons.arrowLeft,
    'arrow-right': LucideIcons.arrowRight,
    'chevron-right': LucideIcons.chevronRight,
    'chevron-down': LucideIcons.chevronDown,
    'plus': LucideIcons.plus,
    'sliders-horizontal': LucideIcons.slidersHorizontal,

    // status / feedback
    'check': LucideIcons.check,
    'check-check': LucideIcons.checkCheck,
    'check-circle': LucideIcons.circleCheck,
    'x-circle': LucideIcons.circleX,
    'shield-check': LucideIcons.shieldCheck,
    'message-circle': LucideIcons.messageCircle,

    // auth / forms
    'mail': LucideIcons.mail,
    'mail-check': LucideIcons.mailCheck,
    'mail-open': LucideIcons.mailOpen,
    'lock': LucideIcons.lock,
    'eye': LucideIcons.eye,
    'eye-off': LucideIcons.eyeOff,
    'phone': LucideIcons.phone,
    'home': LucideIcons.house,
    'map-pin': LucideIcons.mapPin,

    // commerce
    'trash-2': LucideIcons.trash2,
    'ticket-percent': LucideIcons.ticketPercent,
    'heart': LucideIcons.heart,
    'star': LucideIcons.star,

    // shipping / payment
    'truck': LucideIcons.truck,
    'zap': LucideIcons.zap,
    'sun': LucideIcons.sun, // toggle theme sáng
    'moon': LucideIcons.moon, // toggle theme tối
    // Category tiles (Home merchandising)
    'cpu': LucideIcons.cpu,
    'laptop': LucideIcons.laptop,
    'smartphone': LucideIcons.smartphone,
    'headphones': LucideIcons.headphones,
    'monitor': LucideIcons.monitor,
    'mouse': LucideIcons.mouse,
    'keyboard': LucideIcons.keyboard,
    'gamepad': LucideIcons.gamepad2,
    'clock': LucideIcons.clock,
    'credit-card': LucideIcons.creditCard,
    'qr-code': LucideIcons.qrCode,
    'landmark': LucideIcons.landmark,
    'banknote': LucideIcons.banknote,
    'wallet': LucideIcons.wallet,
    'external-link': LucideIcons.externalLink,

    // promo / orders
    'tag': LucideIcons.tag,
    'percent': LucideIcons.percent,
    'gift': LucideIcons.gift,
    'package-check': LucideIcons.packageCheck,
    'package': LucideIcons.package,
    'inbox': LucideIcons.inbox,
    'bar-chart': LucideIcons.chartBar,
    'log-out': LucideIcons.logOut,
    'camera': LucideIcons.camera,
    'image': LucideIcons.image,

    // device status bar
    'signal': LucideIcons.signal,
    'wifi': LucideIcons.wifi,
    'battery-full': LucideIcons.batteryFull,

    // media / image upload
    'edit': LucideIcons.squarePen,

    // chat AI
    'bot': LucideIcons.bot,
    'send': LucideIcons.send,

    // admin dashboard (khu quản trị & giám sát vận hành)
    'layout-dashboard': LucideIcons.layoutDashboard,
    'users': LucideIcons.users,
    'activity': LucideIcons.activity,
    'shield': LucideIcons.shield,
    'shield-alert': LucideIcons.shieldAlert,
    'trending-up': LucideIcons.trendingUp,
    'monitor-smartphone': LucideIcons.monitorSmartphone,
    'user-cog': LucideIcons.userCog,
    'refresh-cw': LucideIcons.refreshCw,
    'boxes': LucideIcons.boxes,
    'circle-alert': LucideIcons.circleAlert,
    // Bổ sung cho ví / hoàn tiền / chi tiết đơn / SP liên quan / lọc.
    'alert-circle': LucideIcons.circleAlert,
    'layout-grid': LucideIcons.layoutGrid,
    'receipt': LucideIcons.receipt,
    'image-plus': LucideIcons.imagePlus,
    'rotate-ccw': LucideIcons.rotateCcw,
    'plus-circle': LucideIcons.circlePlus,
    'arrow-up-right': LucideIcons.arrowUpRight,
    'x': LucideIcons.x,
  };

  /// Resolve a Lucide name to an [IconData], falling back to a neutral glyph.
  static IconData get(String name) => _map[name] ?? LucideIcons.circle;
}
