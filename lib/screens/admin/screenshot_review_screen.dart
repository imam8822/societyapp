import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/app_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../models/payment_models.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/api/api_services.dart';
import '../../core/api/api_client.dart';

class ScreenshotReviewScreen extends ConsumerWidget {
  const ScreenshotReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.bgGrey,
        appBar: AppBar(
          title: const Text('Screenshot Reviews'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                ref.invalidate(pendingScreenshotsProvider);
                ref.invalidate(pendingLoanRepaymentsProvider);
              },
            ),
          ],
          bottom: TabBar(
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textGrey,
            indicatorColor: context.colors.primary,
            tabs: const [
              Tab(text: 'Contributions'),
              Tab(text: 'Loan Repayments'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ContributionsTab(),
            _LoanRepaymentsTab(),
          ],
        ),
      ),
    );
  }
}

class _ContributionsTab extends ConsumerWidget {
  const _ContributionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingScreenshotsProvider);

    return state.when(
      loading: () =>
          Center(child: const AppSpinner()),
      error: (e, _) => ErrorRetry(
        message: apiError(e),
        onRetry: () => ref.invalidate(pendingScreenshotsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 64, color: context.colors.primary),
                const SizedBox(height: 16),
                Text('All caught up!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textDark)),
                const SizedBox(height: 6),
                Text('No contribution screenshots pending review.',
                    style: TextStyle(color: context.colors.textGrey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (ctx, i) => _ScreenshotCard(item: list[i]),
        );
      },
    );
  }
}

class _LoanRepaymentsTab extends ConsumerWidget {
  const _LoanRepaymentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingLoanRepaymentsProvider);

    return state.when(
      loading: () =>
          Center(child: const AppSpinner()),
      error: (e, _) => ErrorRetry(
        message: apiError(e),
        onRetry: () => ref.invalidate(pendingLoanRepaymentsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 64, color: context.colors.primary),
                const SizedBox(height: 16),
                Text('All caught up!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textDark)),
                const SizedBox(height: 6),
                Text('No loan repayment screenshots pending review.',
                    style: TextStyle(color: context.colors.textGrey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (ctx, i) => _LoanRepaymentCard(item: list[i]),
        );
      },
    );
  }
}

// ── Card per pending screenshot ───────────────────────────────
class _ScreenshotCard extends ConsumerStatefulWidget {
  final PendingScreenshot item;
  const _ScreenshotCard({required this.item});

  @override
  ConsumerState<_ScreenshotCard> createState() => _ScreenshotCardState();
}

class _ScreenshotCardState extends ConsumerState<_ScreenshotCard> {
  final bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.colors.primaryLight,
                  child: Text(
                    item.userName.isNotEmpty ? item.userName[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: context.colors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.userName,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: context.colors.textDark)),
                      Text(item.userPhone,
                          style: TextStyle(
                              color: context.colors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                // Month badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item.monthName,
                      style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: context.colors.divider),
          const SizedBox(height: 12),

          // ── Amount row ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _AmountChip(
                    label: 'Contribution',
                    value: fmt.format(item.amount),
                    color: context.colors.primary),
                if (item.penaltyAmount > 0) ...[
                  const SizedBox(width: 8),
                  _AmountChip(
                      label: 'Penalty',
                      value: fmt.format(item.penaltyAmount),
                      color: context.colors.error),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total',
                        style:
                            TextStyle(color: context.colors.textGrey, fontSize: 11)),
                    Text(fmt.format(item.totalAmount),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textDark)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── AI / OCR status row ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (item.aiVerificationStatus.toLowerCase() == 'pendingreview')
                  const _StatusChip(label: 'Pending Review', isOk: false)
                else ...[
                  _StatusChip(
                      label: 'OCR: ${item.ocrStatus}',
                      isOk: item.ocrStatus.toLowerCase() == 'completed'),
                  const SizedBox(width: 8),
                  _StatusChip(
                      label: 'AI: ${item.aiVerificationStatus}',
                      isOk: item.aiVerificationStatus.toLowerCase() == 'verified'),
                ],
                if (item.screenshotUrl != null && item.screenshotUrl!.isNotEmpty) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showFullImage(context, item),
                    child: Row(
                      children: [
                        Text(
                          'Show screenshot',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: context.colors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),



          // ── AI summary ────────────────────────────────
          if (item.aiSummary != null && item.aiSummary!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.smart_toy_outlined,
                        size: 15, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.aiSummary!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF38BDF8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── AI extracted amount mismatch warning ──────
          if (item.aiExtractedAmount != null &&
              item.aiExtractedAmount != item.totalAmount) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.colors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 15, color: context.colors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'AI detected ${fmt.format(item.aiExtractedAmount)}, expected ${fmt.format(item.totalAmount)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.colors.warning,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],



          const SizedBox(height: 14),

          // ── Action buttons ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.colors.error,
                        side: BorderSide(color: context.colors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () =>
                          _confirmAction(context, ref, item, approve: false),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () =>
                          _confirmAction(context, ref, item, approve: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build image from base64 or URL ────────────────────────
  Widget _buildImage(String url, {double? height}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        final Uint8List bytes = base64Decode(base64Str);
        return Image.memory(bytes,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imageFallback(height));
      } catch (_) {
        return _imageFallback(height);
      }
    }
    return Image.network(url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(height));
  }

  Widget _imageFallback(double? height) => Container(
        height: height ?? 160,
        color: context.colors.bgGrey,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: context.colors.textGrey, size: 32),
              const SizedBox(height: 4),
              Text('Image unavailable',
                  style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
            ],
          ),
        ),
      );

  // ── Full screen image viewer ──────────────────────────────
  void _showFullImage(BuildContext context, PendingScreenshot item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: _buildImage(item.screenshotUrl!),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm approve/reject dialog ─────────────────────────
  void _confirmAction(BuildContext context, WidgetRef ref, PendingScreenshot item,
      {required bool approve}) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final remarkCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(approve ? 'Approve Payment?' : 'Reject Payment?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Member: ${item.userName}'),
                  Text('Month: ${item.monthName}'),
                  Text('Amount: ${fmt.format(item.totalAmount)}'),
                  if (!approve) ...[
                    const SizedBox(height: 12),
                    Text(
                      'The member will need to re-upload their payment screenshot.',
                      style: TextStyle(color: context.colors.textGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarkCtrl,
                      decoration: InputDecoration(
                        labelText: 'Rejection Remark (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: approve ? context.colors.primary : context.colors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(100, 44),
                  ),
                  onPressed: isProcessing ? null : () async {
                    setState(() => isProcessing = true);
                    try {
                      final remark = remarkCtrl.text.trim().isEmpty ? null : remarkCtrl.text.trim();
                      await PaymentApi.adminVerify(item.contributionId, approve, remark);
                      
                      ref.invalidate(pendingScreenshotsProvider);
                      ref.invalidate(adminDashboardProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      
                      if (context.mounted) {
                        if (approve) {
                          AppUtils.showSuccess(context, 'Payment approved for ${item.userName}');
                        } else {
                          AppUtils.showInfo(context, 'Payment rejected for ${item.userName}');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppUtils.showError(context, 'Error: ${e.toString()}');
                      }
                    } finally {
                      if (ctx.mounted) setState(() => isProcessing = false);
                    }
                  },
                  child: isProcessing
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: const AppSpinner(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(approve ? 'Approve' : 'Reject'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

class _LoanRepaymentCard extends ConsumerStatefulWidget {
  final PendingLoanRepayment item;
  const _LoanRepaymentCard({required this.item});

  @override
  ConsumerState<_LoanRepaymentCard> createState() => _LoanRepaymentCardState();
}

class _LoanRepaymentCardState extends ConsumerState<_LoanRepaymentCard> {
  final bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.colors.primaryLight,
                  child: Text(
                    item.userName.isNotEmpty ? item.userName[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: context.colors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.userName,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: context.colors.textDark)),
                      Text(item.userPhone,
                          style: TextStyle(
                              color: context.colors.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: context.colors.divider),
          const SizedBox(height: 12),

          // ── Amount row ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _AmountChip(
                    label: 'Loan Repayment',
                    value: fmt.format(item.amount),
                    color: context.colors.primary),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total',
                        style:
                            TextStyle(color: context.colors.textGrey, fontSize: 11)),
                    Text(fmt.format(item.amount),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textDark)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── AI / OCR status row ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (item.aiVerificationStatus.toLowerCase() == 'pendingreview')
                  const _StatusChip(label: 'Pending Review', isOk: false)
                else ...[
                  _StatusChip(
                      label: 'OCR: ${item.ocrStatus}',
                      isOk: item.ocrStatus.toLowerCase() == 'completed'),
                  const SizedBox(width: 8),
                  _StatusChip(
                      label: 'AI: ${item.aiVerificationStatus}',
                      isOk: item.aiVerificationStatus.toLowerCase() == 'verified'),
                ],
                if (item.screenshotUrl != null && item.screenshotUrl!.isNotEmpty) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showFullImage(context, item),
                    child: Row(
                      children: [
                        Text(
                          'Show screenshot',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: context.colors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── AI summary ────────────────────────────────
          if (item.aiSummary != null && item.aiSummary!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.bgGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.aiSummary!,
                  style:
                      TextStyle(fontSize: 12, color: context.colors.textDark),
                ),
              ),
            ),
          ],



          const SizedBox(height: 14),

          // ── Actions ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0).copyWith(bottom: 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.colors.error,
                      side: BorderSide(color: context.colors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _confirmAction(context, ref, item,
                        approve: false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _confirmAction(context, ref, item,
                        approve: true),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url, {double? height}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        final Uint8List bytes = base64Decode(base64Str);
        return Image.memory(bytes,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imageFallback(height));
      } catch (_) {
        return _imageFallback(height);
      }
    }
    return Image.network(url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(height));
  }

  Widget _imageFallback(double? height) => Container(
        height: height ?? 160,
        color: context.colors.bgGrey,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: context.colors.textGrey, size: 32),
              const SizedBox(height: 4),
              Text('Image unavailable',
                  style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
            ],
          ),
        ),
      );

  void _showFullImage(BuildContext context, PendingLoanRepayment item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: _buildImage(item.screenshotUrl!),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAction(BuildContext context, WidgetRef ref, PendingLoanRepayment item,
      {required bool approve}) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final remarkCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(approve ? 'Approve Repayment?' : 'Reject Repayment?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Member: ${item.userName}'),
                  Text('Amount: ${fmt.format(item.amount)}'),
                  if (!approve) ...[
                    const SizedBox(height: 12),
                    Text(
                      'The member will need to re-upload their payment screenshot.',
                      style: TextStyle(color: context.colors.textGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarkCtrl,
                      decoration: InputDecoration(
                        labelText: 'Rejection Remark (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: approve ? context.colors.primary : context.colors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size(100, 44),
                  ),
                  onPressed: isProcessing ? null : () async {
                    setState(() => isProcessing = true);
                    try {
                      final remark = remarkCtrl.text.trim().isEmpty ? null : remarkCtrl.text.trim();
                      await PaymentApi.adminVerifyLoanRepayment(item.loanRepaymentId, approve, remark);
                      
                      ref.invalidate(pendingLoanRepaymentsProvider);
                      ref.invalidate(adminDashboardProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                      
                      if (context.mounted) {
                        if (approve) {
                          AppUtils.showSuccess(context, 'Repayment approved for ${item.userName}');
                        } else {
                          AppUtils.showInfo(context, 'Repayment rejected for ${item.userName}');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppUtils.showError(context, 'Error: ${e.toString()}');
                      }
                    } finally {
                      if (ctx.mounted) setState(() => isProcessing = false);
                    }
                  },
                  child: isProcessing
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: const AppSpinner(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(approve ? 'Approve' : 'Reject'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────
class _AmountChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AmountChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: context.colors.textGrey, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isOk;
  const _StatusChip({required this.label, required this.isOk});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (isOk ? context.colors.primary : context.colors.warning).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  (isOk ? context.colors.primary : context.colors.warning).withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOk ? context.colors.primary : context.colors.warning)),
      );
}
