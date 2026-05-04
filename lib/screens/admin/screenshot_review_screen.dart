import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../models/pending_screenshot.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';

class ScreenshotReviewScreen extends ConsumerWidget {
  const ScreenshotReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pendingScreenshotsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: const Text('Screenshot Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(pendingScreenshotsProvider),
          ),
        ],
      ),
      body: state.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(pendingScreenshotsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 64, color: AppTheme.primary),
                  SizedBox(height: 16),
                  Text('All caught up!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                  SizedBox(height: 6),
                  Text('No screenshots pending review.',
                      style: TextStyle(color: AppTheme.textGrey)),
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
      ),
    );
  }
}

// ── Card per pending screenshot ───────────────────────────────
class _ScreenshotCard extends StatelessWidget {
  final PendingScreenshot item;
  const _ScreenshotCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
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
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    item.userName.isNotEmpty ? item.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textDark)),
                      Text(item.userPhone,
                          style: const TextStyle(
                              color: AppTheme.textGrey, fontSize: 12)),
                    ],
                  ),
                ),
                // Month badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(item.monthName,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 12),

          // ── Amount row ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _AmountChip(
                    label: 'Contribution',
                    value: fmt.format(item.amount),
                    color: AppTheme.primary),
                if (item.penaltyAmount > 0) ...[
                  const SizedBox(width: 8),
                  _AmountChip(
                      label: 'Penalty',
                      value: fmt.format(item.penaltyAmount),
                      color: AppTheme.error),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total',
                        style:
                            TextStyle(color: AppTheme.textGrey, fontSize: 11)),
                    Text(fmt.format(item.totalAmount),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark)),
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
                _StatusChip(
                    label: 'OCR: ${item.ocrStatus}',
                    isOk: item.ocrStatus.toLowerCase() == 'completed'),
                const SizedBox(width: 8),
                _StatusChip(
                    label: 'AI: ${item.aiVerificationStatus}',
                    isOk: item.aiVerificationStatus.toLowerCase() == 'verified'),
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
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.smart_toy_outlined,
                        size: 15, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.aiSummary!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF0369A1)),
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
                  color: AppTheme.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 15, color: AppTheme.warning),
                    const SizedBox(width: 6),
                    Text(
                      'AI detected ${fmt.format(item.aiExtractedAmount)}, expected ${fmt.format(item.totalAmount)}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Screenshot thumbnail ──────────────────────
          if (item.screenshotUrl != null && item.screenshotUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _showFullImage(context, item),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      _buildImage(item.screenshotUrl!, height: 160),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.zoom_in_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Tap to enlarge',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Action buttons ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () =>
                        _confirmAction(context, item, approve: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () =>
                        _confirmAction(context, item, approve: true),
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
        color: AppTheme.bgGrey,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: AppTheme.textGrey, size: 32),
              SizedBox(height: 4),
              Text('Image unavailable',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
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
  void _confirmAction(BuildContext context, PendingScreenshot item,
      {required bool approve}) {
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              const Text(
                'The member will need to re-upload their payment screenshot.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppTheme.primary : AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: wire to your approve/reject API call
              // ref.read(pendingScreenshotsProvider.notifier).approve(item.contributionId)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(approve
                      ? 'Payment approved for ${item.userName}'
                      : 'Payment rejected for ${item.userName}'),
                  backgroundColor: approve ? AppTheme.primary : AppTheme.error,
                ),
              );
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
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
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
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
          color: (isOk ? AppTheme.primary : AppTheme.warning).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  (isOk ? AppTheme.primary : AppTheme.warning).withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOk ? AppTheme.primary : AppTheme.warning)),
      );
}