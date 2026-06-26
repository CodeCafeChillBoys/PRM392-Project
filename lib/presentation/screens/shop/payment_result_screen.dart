import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../state/app_nav.dart';
import '../../widgets/widgets.dart';

/// PaymentResultScreen displays the outcome of a checkout payment (VNPay, COD, etc.).
class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
  });

  final bool success;
  final String orderId;
  final double totalAmount;
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    final appNav = context.read<AppNav>();

    return Scaffold(
      body: DotGridBackground(
        child: SafeArea(
          child: Column(
            children: [
              const TvAppBar(
                mode: TvAppBarMode.page,
                title: 'Kết quả thanh toán',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      // Glowing Status Circle Icon
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: success
                              ? AppColors.successSoft
                              : AppColors.dangerSoft,
                          border: Border.all(
                            color: success
                                ? AppColors.successLine
                                : AppColors.dangerLine,
                            width: 2,
                          ),
                          boxShadow: success
                              ? [
                                  BoxShadow(
                                    color: AppColors.success500.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: AppColors.danger500.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                        ),
                        child: Icon(
                          success
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          size: 54,
                          color: success
                              ? AppColors.success500
                              : AppColors.danger500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Status Headers
                      Text(
                        success
                            ? 'Thanh toán thành công!'
                            : 'Thanh toán thất bại',
                        style: AppText.h1(
                          success ? AppColors.success500 : AppColors.danger500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        success
                            ? 'Cảm ơn bạn đã tin tưởng mua sắm tại TECH_VOID. Đơn hàng của bạn đã được tiếp nhận và đang được xử lý.'
                            : 'Giao dịch của bạn đã bị từ chối hoặc gặp sự cố. Vui lòng kiểm tra lại phương thức thanh toán.',
                        style: AppText.body(AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Details Box
                      TvCard(
                        padding: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chi tiết giao dịch'.toUpperCase(),
                              style: AppText.label(AppColors.textAccent),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.0),
                              child: Divider(
                                color: AppColors.borderSubtle,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildDetailRow(
                              'Mã đơn hàng',
                              '#$orderId',
                              isMonospace: true,
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Phương thức', paymentMethod),
                            const SizedBox(height: 12),
                            _buildDetailRow('Thời gian', _formatCurrentTime()),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Tổng thanh toán',
                              formatVnd(totalAmount),
                              valueColor: AppColors.textAccent,
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 44),
                      // Continue Shopping Button
                      TvButton(
                        label: 'Tiếp tục mua sắm',
                        variant: TvButtonVariant.gradient,
                        fullWidth: true,
                        size: TvButtonSize.lg,
                        onPressed: () {
                          appNav.goExplore();
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                      ),
                      if (!success) ...[
                        const SizedBox(height: 12),
                        // Try Again Button
                        TvButton(
                          label: 'Thử thanh toán lại',
                          variant: TvButtonVariant.secondary,
                          fullWidth: true,
                          size: TvButtonSize.lg,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMonospace = false,
    bool isBold = false,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.body(AppColors.textSecondary).copyWith(fontSize: 14),
        ),
        Text(
          value,
          style: isMonospace
              ? AppText.mono(
                  size: 14,
                  color: valueColor,
                  weight: isBold ? FontWeight.bold : FontWeight.normal,
                )
              : AppText.body(valueColor).copyWith(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
        ),
      ],
    );
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year;
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month/$year';
  }
}
