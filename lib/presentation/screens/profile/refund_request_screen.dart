import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/order_service.dart';
import '../../widgets/widgets.dart';

/// Form khách yêu cầu hoàn tiền cho 1 đơn đã giao (`Delivered` + `Paid`).
/// Chọn lý do (preset) + mô tả (tùy chọn, bắt buộc nếu chọn "Khác") + ảnh
/// đính kèm (tùy chọn). Pop `true` khi gửi thành công — màn gọi lo toast + reload.
class RefundRequestScreen extends StatefulWidget {
  const RefundRequestScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final _service = OrderService();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  /// Danh sách lý do preset — chốt trong spec refund.
  static const _reasons = <String>[
    'Hàng lỗi/hư hỏng',
    'Sai sản phẩm',
    'Thiếu hàng',
    'Không đúng mô tả',
    'Đổi ý',
    'Khác',
  ];

  String? _reason;
  XFile? _pickedImage;
  bool _submitting = false;

  /// key lỗi → thông điệp, hiện dưới nhóm tương ứng.
  final Map<String, String> _errors = {};

  /// Số lượng hoàn cho mỗi dòng đơn (orderDetailId → qty), mặc định = full.
  late final Map<String, int> _refundQty = {
    for (final l in widget.order.lines) l.id: l.quantity,
  };

  bool get _hasLines => widget.order.lines.isNotEmpty;

  double get _refundGoods => widget.order.lines
      .fold(0.0, (s, l) => s + l.unitPrice * (_refundQty[l.id] ?? 0));

  bool get _isFullRefund =>
      _hasLines &&
      widget.order.lines.every((l) => (_refundQty[l.id] ?? 0) == l.quantity);

  int get _totalRefundQty => _refundQty.values.fold(0, (s, q) => s + q);

  /// Số tiền dự kiến hoàn: hoàn hết (hoặc đơn không có chi tiết) = cả đơn (gồm ship);
  /// hoàn 1 phần = tổng tiền hàng các đơn vị chọn.
  double get _previewAmount {
    if (!_hasLines) return widget.order.totalAmount;
    return _isFullRefund ? widget.order.totalAmount : _refundGoods;
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  String _shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ảnh đính kèm', style: AppText.h3()),
              const SizedBox(height: 12),
              TvOptionRow(
                title: 'Chọn từ thư viện',
                icon: const TvIcon('image'),
                showRadio: false,
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
              TvOptionRow(
                title: 'Chụp ảnh mới',
                icon: const TvIcon('camera'),
                showRadio: false,
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 1600);
      if (picked != null && mounted) {
        setState(() => _pickedImage = picked);
      }
    } catch (_) {
      if (mounted) TvToast.show(context, 'Không chọn được ảnh.');
    }
  }

  bool _validate() {
    final errors = <String, String>{};
    if (_reason == null) {
      errors['reason'] = 'Vui lòng chọn lý do hoàn tiền.';
    } else if (_reason == 'Khác' && _descCtrl.text.trim().isEmpty) {
      errors['desc'] = 'Vui lòng mô tả lý do khi chọn "Khác".';
    }
    if (_hasLines && _totalRefundQty <= 0) {
      errors['items'] = 'Chọn số lượng hoàn cho ít nhất 1 sản phẩm.';
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final desc = _descCtrl.text.trim();
    final reason = desc.isEmpty ? _reason! : '$_reason: $desc';

    // Hoàn 1 phần → gửi danh sách món+SL; hoàn hết (hoặc đơn không chi tiết) → null (hoàn cả đơn).
    String? itemsJson;
    if (_hasLines && !_isFullRefund) {
      itemsJson = jsonEncode([
        for (final l in widget.order.lines)
          if ((_refundQty[l.id] ?? 0) > 0)
            {'orderDetailId': l.id, 'quantity': _refundQty[l.id]},
      ]);
    }

    setState(() => _submitting = true);
    try {
      await _service.requestRefund(
        orderId: widget.order.id,
        reason: reason,
        imagePath: _pickedImage?.path,
        itemsJson: itemsJson,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? e.message
            : 'Gửi yêu cầu hoàn tiền thất bại. Thử lại nhé.';
        TvToast.show(context, msg);
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            title: 'Yêu cầu hoàn tiền',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvCard(
                    padding: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Đơn #${_shortId(o.id)}',
                            style: AppText.mono(
                                size: 12, color: AppColors.textTertiary)),
                        Text('Hoàn ${formatVnd(_previewAmount)}',
                            style: AppText.price().copyWith(fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Số tiền sẽ được cộng vào Ví TechStore sau khi được duyệt.',
                      style: AppText.xs(AppColors.textTertiary)),
                  if (_hasLines) ...[
                    const SizedBox(height: 18),
                    Text('Sản phẩm & số lượng hoàn', style: AppText.label()),
                    const SizedBox(height: 8),
                    for (final l in o.lines) ...[
                      _refundLineRow(l),
                      const SizedBox(height: 8),
                    ],
                    if (_errors['items'] != null)
                      Text(_errors['items']!,
                          style: AppText.xs(AppColors.danger500)),
                  ],
                  const SizedBox(height: 18),
                  Text('Lý do hoàn tiền *', style: AppText.label()),
                  const SizedBox(height: 8),
                  for (final r in _reasons) ...[
                    TvOptionRow(
                      title: r,
                      selected: _reason == r,
                      onTap: () => setState(() {
                        _reason = r;
                        _errors.remove('reason');
                      }),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_errors['reason'] != null) ...[
                    const SizedBox(height: 2),
                    Text(_errors['reason']!,
                        style: AppText.xs(AppColors.danger500)),
                  ],
                  const SizedBox(height: 14),
                  Text('Mô tả chi tiết', style: AppText.label()),
                  const SizedBox(height: 6),
                  TvInput(
                    controller: _descCtrl,
                    hintText: 'Mô tả thêm về vấn đề (tùy chọn)...',
                    maxLines: 3,
                    onChanged: (_) {
                      if (_errors.containsKey('desc')) {
                        setState(() => _errors.remove('desc'));
                      }
                    },
                  ),
                  if (_errors['desc'] != null) ...[
                    const SizedBox(height: 4),
                    Text(_errors['desc']!,
                        style: AppText.xs(AppColors.danger500)),
                  ],
                  const SizedBox(height: 14),
                  Text('Ảnh đính kèm (tùy chọn)', style: AppText.label()),
                  const SizedBox(height: 6),
                  _imageSection(),
                  const SizedBox(height: 20),
                  TvButton(
                    label: 'Gửi yêu cầu hoàn tiền',
                    fullWidth: true,
                    loading: _submitting,
                    leadingIcon: const TvIcon('refund', size: 16),
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Một dòng sản phẩm trong đơn + stepper chọn số lượng hoàn (0..đã mua).
  Widget _refundLineRow(OrderLine l) {
    final q = _refundQty[l.id] ?? 0;
    return TvCard(
      padding: 12,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: ColoredBox(
                color: AppColors.ink900,
                child: ProductImage(url: l.imageUrl),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong().copyWith(fontSize: 13)),
                const SizedBox(height: 2),
                Text('${formatVnd(l.unitPrice)} · đã mua ${l.quantity}',
                    style: AppText.xs(AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TvQuantityStepper(
            value: q,
            min: 0,
            max: l.quantity,
            onChanged: (v) => setState(() {
              _refundQty[l.id] = v;
              _errors.remove('items');
            }),
          ),
        ],
      ),
    );
  }

  /// Khung ảnh: bấm để chọn; hiện ảnh vừa chọn hoặc placeholder "Đính kèm ảnh".
  Widget _imageSection() {
    Widget content;
    if (_pickedImage != null) {
      content = Image.file(File(_pickedImage!.path), fit: BoxFit.cover);
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TvIcon('image', size: 32, color: AppColors.textTertiary),
          const SizedBox(height: 8),
          Text('Đính kèm ảnh', style: AppText.xs(AppColors.textTertiary)),
        ],
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _submitting ? null : _pickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(12),
          ),
          child: content,
        ),
      ),
    );
  }
}
