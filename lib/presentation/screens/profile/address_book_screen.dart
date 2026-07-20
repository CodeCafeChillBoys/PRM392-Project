import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/place_suggestion.dart';
import '../../../data/models/saved_address.dart';
import '../../../data/services/address_service.dart';
import '../../../data/services/goong_service.dart';
import '../../widgets/widgets.dart';

/// Sổ địa chỉ (LOCAL) — danh sách địa chỉ giao hàng đã lưu: xem, thêm (Goong
/// autocomplete → toạ độ), đặt mặc định, xoá. Không gọi BE, dữ liệu nằm trong
/// [AddressService]. Vào từ tile "Sổ địa chỉ" ở tab Hồ sơ (MaterialPageRoute).
class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  @override
  void initState() {
    super.initState();
    // Nạp sổ địa chỉ (an toàn khi đã nạp trước đó ở nơi khác).
    AddressService.instance.load();
  }

  Future<void> _openAddForm() async {
    final created = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddressFormSheet(),
    );
    if (created == null) return;
    await AddressService.instance.add(created);
    if (mounted) TvToast.show(context, 'Đã lưu địa chỉ mới.');
  }

  Future<void> _setDefault(SavedAddress a) async {
    if (a.isDefault) return;
    await AddressService.instance.setDefault(a.id);
    if (mounted) TvToast.show(context, 'Đã đặt "${a.label}" làm mặc định.');
  }

  Future<void> _confirmDelete(SavedAddress a) async {
    final ok = await showTvConfirm(
      context,
      title: 'Xoá địa chỉ?',
      message: '"${a.label}" sẽ bị gỡ khỏi sổ địa chỉ của bạn.',
      confirmLabel: 'Xoá',
    );
    if (ok != true) return;
    await AddressService.instance.remove(a.id);
    if (mounted) TvToast.show(context, 'Đã xoá địa chỉ.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Sổ địa chỉ',
            onBack: () => Navigator.of(context).pop(),
            actions: [
              TvIconButton(
                icon: const TvIcon('plus', size: 22),
                onPressed: _openAddForm,
                tooltip: 'Thêm địa chỉ',
              ),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder<List<SavedAddress>>(
              valueListenable: AddressService.instance.notifier,
              builder: (context, items, _) {
                if (items.isEmpty) return _emptyState();
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    16,
                    AppSpacing.gutter,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i == items.length) {
                      return TvButton(
                        label: 'Thêm địa chỉ mới',
                        variant: TvButtonVariant.secondary,
                        size: TvButtonSize.md,
                        fullWidth: true,
                        leadingIcon: const TvIcon('plus', size: 18),
                        onPressed: _openAddForm,
                      );
                    }
                    return _addressCard(items[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(SavedAddress a) {
    return TvCard(
      padding: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TvIcon(
                _labelIcon(a.label),
                size: 18,
                color: AppColors.textAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        a.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong(),
                      ),
                    ),
                    if (a.isDefault) ...[
                      const SizedBox(width: 8),
                      TvBadge('Mặc định', variant: TvBadgeVariant.accent),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PressableScale(
                onTap: () => _confirmDelete(a),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: TvIcon(
                    'trash-2',
                    size: 18,
                    color: AppColors.danger500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.address,
            style: AppText.sm(AppColors.textSecondary).copyWith(height: 1.45),
          ),
          if (!a.isDefault) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.borderSubtle),
            ),
            PressableScale(
              haptic: PressHaptic.selection,
              onTap: () => _setDefault(a),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvIcon('check-circle', size: 16, color: AppColors.textAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Đặt làm mặc định',
                    style: AppText.sm(
                      AppColors.textAccent,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentSoft,
                border: Border.all(color: AppColors.accentSoftLine),
              ),
              child: TvIcon('map-pin', size: 30, color: AppColors.textAccent),
            ),
            const SizedBox(height: 14),
            Text(
              'Chưa có địa chỉ đã lưu',
              style: AppText.h2().copyWith(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              'Lưu địa chỉ giao hàng để lần sau thanh toán nhanh hơn — chỉ cần chọn là xong.',
              textAlign: TextAlign.center,
              style: AppText.sm(AppColors.textTertiary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              child: TvButton(
                label: 'Thêm địa chỉ',
                size: TvButtonSize.md,
                fullWidth: true,
                leadingIcon: const TvIcon('plus', size: 18),
                onPressed: _openAddForm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chọn icon gợi ý theo nhãn — thuần thẩm mỹ, không ràng buộc nhập liệu.
  String _labelIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('nhà')) return 'home';
    if (l.contains('cơ quan') ||
        l.contains('công ty') ||
        l.contains('văn phòng')) {
      return 'landmark';
    }
    return 'map-pin';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Form thêm địa chỉ (bottom sheet): gõ → Goong autocomplete → chọn gợi ý →
// placeLatLng lấy toạ độ → đặt nhãn → Lưu. Trả về [SavedAddress] qua pop().
// ═══════════════════════════════════════════════════════════════════════════
class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet();

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  static const _labelPresets = ['Nhà', 'Cơ quan', 'Người thân', 'Khác'];

  final _goong = GoongService();
  final _addressCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _searching = false;
  bool _resolving = false; // đang lấy toạ độ cho gợi ý vừa chọn

  LatLng? _dest; // toạ độ đã lấy được
  String _selectedAddress = '';

  bool get _canSave =>
      _dest != null &&
      _selectedAddress.isNotEmpty &&
      _labelCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _debounce?.cancel();
    _addressCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _onAddressChanged(String v) {
    _debounce?.cancel();
    if (v.trim() == _selectedAddress.trim()) return;
    // Sửa lại địa chỉ → toạ độ cũ không còn đúng.
    if (_dest != null) setState(() => _dest = null);
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(v));
  }

  Future<void> _search(String input) async {
    if (input.trim().length < 3) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final list = await _goong.autocomplete(input);
      if (mounted) setState(() => _suggestions = list);
    } catch (_) {
      if (mounted) setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion p) async {
    FocusScope.of(context).unfocus();
    _selectedAddress = p.description;
    _addressCtrl.text = p.description;
    _addressCtrl.selection = TextSelection.collapsed(
      offset: p.description.length,
    );
    setState(() {
      _suggestions = [];
      _dest = null;
      _resolving = true;
    });
    try {
      final latLng = await _goong.placeLatLng(p.placeId);
      if (!mounted) return;
      if (latLng == null) {
        setState(() => _dest = null);
        TvToast.show(context, 'Không lấy được toạ độ cho địa chỉ này.');
        return;
      }
      setState(() => _dest = latLng);
    } catch (_) {
      if (mounted) {
        setState(() => _dest = null);
        TvToast.show(context, 'Không lấy được toạ độ cho địa chỉ này.');
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  void _pickLabel(String value) {
    setState(() {
      _labelCtrl.text = value;
      _labelCtrl.selection = TextSelection.collapsed(offset: value.length);
    });
  }

  void _save() {
    final label = _labelCtrl.text.trim();
    final dest = _dest;
    if (dest == null || _selectedAddress.isEmpty) {
      TvToast.show(context, 'Hãy chọn địa chỉ từ gợi ý để lấy toạ độ.');
      return;
    }
    if (label.isEmpty) {
      TvToast.show(context, 'Đặt tên cho địa chỉ (VD: Nhà, Cơ quan).');
      return;
    }
    Navigator.of(context).pop(
      SavedAddress(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: label,
        address: _selectedAddress,
        lat: dest.latitude,
        lng: dest.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Thêm địa chỉ', style: AppText.h2().copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(
                'Tìm địa chỉ để lấy toạ độ chính xác cho việc tính phí ship.',
                style: AppText.xs(AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              Text(
                'Địa chỉ',
                style: AppText.sm(
                  AppColors.textSecondary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TvInput(
                controller: _addressCtrl,
                leading: const TvIcon('search'),
                hintText: 'Nhập địa chỉ giao hàng...',
                size: TvInputSize.lg,
                onChanged: _onAddressChanged,
                trailing: _searching
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textAccent,
                        ),
                      )
                    : null,
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 6),
                _suggestionList(),
              ],
              if (_resolving) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Đang lấy toạ độ...',
                      style: AppText.sm(AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
              if (_dest != null && !_resolving) ...[
                const SizedBox(height: 12),
                _resolvedBanner(),
              ],
              const SizedBox(height: 18),
              Text(
                'Nhãn địa chỉ',
                style: AppText.sm(
                  AppColors.textSecondary,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _labelPresets.map(_labelChip).toList(),
              ),
              const SizedBox(height: 10),
              TvInput(
                controller: _labelCtrl,
                leading: const TvIcon('edit'),
                hintText: 'Hoặc tự đặt tên...',
                size: TvInputSize.lg,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              TvButton(
                label: 'Lưu địa chỉ',
                size: TvButtonSize.lg,
                fullWidth: true,
                leadingIcon: const TvIcon('check', size: 18),
                onPressed: _canSave ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestionList() {
    final shown = _suggestions.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.borderSubtle),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectSuggestion(shown[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    TvIcon('map-pin', size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        shown[i].description,
                        style: AppText.sm(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resolvedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.accentSoftLine),
      ),
      child: Row(
        children: [
          TvIcon('check-circle', size: 16, color: AppColors.textAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đã xác định vị trí — sẵn sàng lưu.',
              style: AppText.sm(
                AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelChip(String value) {
    final selected = _labelCtrl.text.trim() == value;
    return PressableScale(
      haptic: PressHaptic.selection,
      onTap: () => _pickLabel(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.accentSoftLine
                : AppColors.borderDefault,
          ),
        ),
        child: Text(
          value,
          style: AppText.sm(
            selected ? AppColors.textAccent : AppColors.textSecondary,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
