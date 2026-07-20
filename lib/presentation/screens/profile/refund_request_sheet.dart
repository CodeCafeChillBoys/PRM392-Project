import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/widgets.dart';

/// Dữ liệu khách nhập khi xin hoàn tiền: lý do (bắt buộc) + ảnh minh chứng (tuỳ chọn).
class RefundRequest {
  const RefundRequest({required this.reason, this.imagePath});
  final String reason;
  final String? imagePath;
}

/// Mở bottom-sheet nhập yêu cầu hoàn tiền. Trả [RefundRequest] nếu khách gửi,
/// null nếu huỷ.
Future<RefundRequest?> showRefundRequestSheet(BuildContext context) {
  return showModalBottomSheet<RefundRequest>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _RefundRequestSheet(),
  );
}

class _RefundRequestSheet extends StatefulWidget {
  const _RefundRequestSheet();

  @override
  State<_RefundRequestSheet> createState() => _RefundRequestSheetState();
}

class _RefundRequestSheetState extends State<_RefundRequestSheet> {
  final _reason = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Ảnh minh chứng', style: AppText.h3().copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            ListTile(
              leading: TvIcon('camera', color: AppColors.textAccent),
              title: Text('Chụp ảnh', style: AppText.body()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: TvIcon('image', color: AppColors.textAccent),
              title: Text('Chọn từ thư viện', style: AppText.body()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final XFile? photo = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (photo != null && mounted) setState(() => _imagePath = photo.path);
  }

  void _submit() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      TvToast.show(context, 'Nhập lý do hoàn tiền nhé.');
      return;
    }
    Navigator.of(
      context,
    ).pop(RefundRequest(reason: reason, imagePath: _imagePath));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
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
          Text('Yêu cầu hoàn tiền', style: AppText.h2().copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'Tiền sẽ được hoàn vào Ví TECH_VOID sau khi được duyệt. '
            'Chỉ áp dụng trong 1 ngày kể từ khi nhận hàng.',
            style: AppText.sm(AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TvInput(
            controller: _reason,
            hintText: 'Lý do hoàn tiền (bắt buộc)',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          if (_imagePath != null) _imagePreview() else _attachButton(),
          const SizedBox(height: 16),
          TvButton(
            label: 'Gửi yêu cầu',
            size: TvButtonSize.lg,
            fullWidth: true,
            leadingIcon: const TvIcon('send', size: 18),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _attachButton() {
    return PressableScale(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TvIcon('image-plus', size: 18, color: AppColors.textAccent),
            const SizedBox(width: 8),
            Text(
              'Đính ảnh minh chứng (tuỳ chọn)',
              style: AppText.sm(AppColors.textAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_imagePath!),
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: PressableScale(
            onTap: () => setState(() => _imagePath = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.bgBase.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: TvIcon('x', size: 16, color: AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
