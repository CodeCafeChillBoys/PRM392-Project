import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_effects.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/widgets.dart';

/// Trung tâm hỗ trợ & Chính sách — trang TĨNH (không gọi BE): liên hệ CSKH,
/// bảo hành, đổi trả/hoàn tiền, bảo mật, FAQ và phiên bản ứng dụng.
/// Vào từ tile "Trung tâm hỗ trợ" ở tab Hồ sơ (MaterialPageRoute).
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // Thông tin liên hệ demo (tĩnh — không thu thập / gửi đi đâu).
  static const String _hotline = '1900 1234';
  static const String _email = 'cskh@techvoid.vn';
  static const String _hours = '8:00 – 22:00 (T2 – CN)';
  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Column(
        children: [
          TvAppBar(
            mode: TvAppBarMode.page,
            title: 'Trung tâm hỗ trợ',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                16,
                AppSpacing.gutter,
                28 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                _intro(),
                const SizedBox(height: 20),
                _contactCard(),
                const SizedBox(height: 14),
                _warrantyCard(),
                const SizedBox(height: 14),
                _returnCard(),
                const SizedBox(height: 14),
                _privacyCard(),
                const SizedBox(height: 20),
                _faqSection(),
                const SizedBox(height: 22),
                _versionFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _intro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHÚNG TÔI LUÔN LẮNG NGHE',
          style: AppText.label(AppColors.textAccent),
        ),
        const SizedBox(height: 8),
        Text('Hỗ trợ & Chính sách', style: AppText.h1()),
        const SizedBox(height: 6),
        Text(
          'Mọi thắc mắc về đơn hàng, bảo hành hay đổi trả đều có lời giải ở đây.',
          style: AppText.sm(AppColors.textSecondary).copyWith(height: 1.5),
        ),
      ],
    );
  }

  // ── Liên hệ CSKH ─────────────────────────────────────────────────────────
  Widget _contactCard() {
    return _sectionCard(
      icon: 'headphones',
      title: 'Liên hệ CSKH',
      children: [
        _contactRow('phone', 'Hotline', _hotline),
        _contactRow('mail', 'Email', _email),
        _contactRow('clock', 'Giờ làm việc', _hours),
        const SizedBox(height: 2),
        Text(
          'Tổng đài miễn phí, hỗ trợ cả cuối tuần và ngày lễ.',
          style: AppText.xs(AppColors.textTertiary),
        ),
      ],
    );
  }

  // ── Bảo hành ───────────────────────────────────────────────────────────────
  Widget _warrantyCard() {
    return _sectionCard(
      icon: 'shield-check',
      title: 'Chính sách bảo hành',
      children: [
        _bullet('Bảo hành chính hãng 24 tháng cho toàn bộ sản phẩm.'),
        _bullet(
          'Lỗi kỹ thuật do nhà sản xuất: đổi mới trong 30 ngày đầu, sửa hoặc '
          'thay linh kiện miễn phí trong thời gian bảo hành.',
        ),
        _bullet(
          'Xuất trình đơn hàng trong ứng dụng để xác minh — không cần giữ '
          'phiếu giấy.',
        ),
      ],
    );
  }

  // ── Đổi trả & Hoàn tiền ──────────────────────────────────────────────────
  Widget _returnCard() {
    return _sectionCard(
      icon: 'refresh-cw',
      title: 'Đổi trả & Hoàn tiền',
      children: [
        _bullet(
          'Đổi trả miễn phí trong 7 ngày nếu sản phẩm còn nguyên tem, hộp.',
        ),
        _bullet(
          'Tiền hoàn được cộng thẳng vào Ví TECH_VOID trong vòng 1 ngày làm '
          'việc kể từ khi duyệt yêu cầu.',
        ),
        _bullet('Số dư ví dùng ngay cho đơn kế tiếp hoặc rút về ngân hàng.'),
      ],
    );
  }

  // ── Bảo mật ────────────────────────────────────────────────────────────────
  Widget _privacyCard() {
    return _sectionCard(
      icon: 'shield',
      title: 'Chính sách bảo mật',
      children: [
        _bullet('Thông tin thanh toán được mã hoá AES-256 xuyên suốt phiên.'),
        _bullet(
          'Chúng tôi không bán hay chia sẻ dữ liệu cá nhân cho bên thứ ba vì '
          'mục đích quảng cáo.',
        ),
        _bullet('Địa chỉ đã lưu chỉ nằm trên thiết bị của bạn.'),
      ],
    );
  }

  // ── FAQ ────────────────────────────────────────────────────────────────────
  Widget _faqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TvSectionHeader(
          icon: TvIcon('message-circle'),
          title: 'Câu hỏi thường gặp',
        ),
        const SizedBox(height: 12),
        const _FaqTile(
          question: 'Bao lâu thì tôi nhận được hàng?',
          answer:
              'Đơn nội thành thường giao trong 2–4 giờ, các khu vực khác từ 1–3 '
              'ngày. Bạn theo dõi hành trình và ETA trực tiếp trên bản đồ đơn hàng.',
        ),
        const SizedBox(height: 10),
        const _FaqTile(
          question: 'Tôi thanh toán bằng những hình thức nào?',
          answer:
              'Bạn có thể trả qua VNPay, Ví TECH_VOID (trừ số dư) hoặc COD — '
              'thanh toán khi nhận hàng.',
        ),
        const SizedBox(height: 10),
        const _FaqTile(
          question: 'Khi nào tiền hoàn về ví?',
          answer:
              'Ngay khi yêu cầu đổi trả được duyệt, tiền hoàn vào Ví trong vòng '
              '1 ngày làm việc và có thể dùng hoặc rút ngay.',
        ),
        const SizedBox(height: 10),
        const _FaqTile(
          question: 'Làm sao để lưu nhiều địa chỉ giao hàng?',
          answer:
              'Vào Hồ sơ → Sổ địa chỉ để thêm và đặt địa chỉ mặc định. Khi thanh '
              'toán, chỉ cần chọn từ sổ là điền xong và tính phí ship tự động.',
        ),
      ],
    );
  }

  Widget _versionFooter() {
    return Center(
      child: Column(
        children: [
          const TvLogo(size: TvLogoSize.sm),
          const SizedBox(height: 8),
          Text(
            'Phiên bản ứng dụng: $_appVersion',
            style: AppText.xs(AppColors.textTertiary),
          ),
          const SizedBox(height: 2),
          Text('© 2026 TECH_VOID', style: AppText.xs(AppColors.textTertiary)),
        ],
      ),
    );
  }

  // ── Khối tái dùng ──────────────────────────────────────────────────────────
  Widget _sectionCard({
    required String icon,
    required String title,
    required List<Widget> children,
  }) {
    return TvCard(
      padding: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.accentSoftLine),
                ),
                child: TvIcon(icon, size: 20, color: AppColors.textAccent),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppText.h3())),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TvIcon('check', size: 15, color: AppColors.textAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppText.sm(AppColors.textSecondary).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          TvIcon(icon, size: 18, color: AppColors.textAccent),
          const SizedBox(width: 12),
          Text(label, style: AppText.sm(AppColors.textTertiary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.body().copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một mục FAQ mở/gập được — chạm cả hàng để bung câu trả lời.
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      haptic: PressHaptic.selection,
      onTap: () => setState(() => _open = !_open),
      child: TvCard(
        padding: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: AppText.body().copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: AppEffects.durBase,
                  curve: AppEffects.easeStandard,
                  child: TvIcon(
                    'chevron-down',
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: AppEffects.durBase,
              curve: AppEffects.easeStandard,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        widget.answer,
                        style: AppText.sm(
                          AppColors.textSecondary,
                        ).copyWith(height: 1.55),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
