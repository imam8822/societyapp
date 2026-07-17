import 'dart:convert';
import 'package:society_app/core/app_utils.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_services.dart';
import '../../core/api/api_client.dart';
import '../../core/constants.dart';
import '../../providers/data_providers.dart';
import '../../models/payment_models.dart';
import '../../widgets/shared_widgets.dart';

class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({super.key});

  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> {
  bool _loading = false;
  PaymentToken? _token;
  String? _error;
  String? _resultMessage;
  bool? _autoVerified;
  String? _aiSummary;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  /// Gets existing valid token or creates a new one — single call
  Future<void> _loadToken() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await PaymentApi.getOrCreateToken();
      if (token.isPendingReview) {
        setState(() {
          _resultMessage = token.pendingMessage ?? "⌛ Screenshot sent to admin for manual review.";
          _autoVerified = false;
        });
      } else {
        setState(() => _token = token);
      }
    } catch (e) {
      setState(() => _error = apiError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openUpi() async {
    if (_token == null) return;
    AppUtils.showUpiAppsBottomSheet(context, _token!.upiDeepLink, (Uri uri) async {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack('Could not open the selected UPI app. Please install it.');
      }
    });
  }

  Future<void> _uploadScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() { _loading = true; _error = null; _resultMessage = null; });
    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      // No tokenId needed — backend finds active token by userId
      final result = await PaymentApi.uploadScreenshot(base64Str);
      ref.invalidate(userDashboardProvider);
      ref.invalidate(myContributionsProvider);
      setState(() {
        _resultMessage = result.message;
        _autoVerified = result.autoVerified;
        _aiSummary = result.aiSummary;
      });
    } catch (e) {
      setState(() => _error = apiError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (msg.contains('success') || msg.contains('verified') || msg.contains('uploaded')) {
      AppUtils.showSuccess(context, msg);
    } else {
      AppUtils.showError(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(title: const Text('Pay Monthly Contribution')),
      body: LoadingOverlay(
        isLoading: _loading && _token != null,
        child: _loading && _token == null
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  ShimmerBox(height: 120, width: double.infinity, borderRadius: 12),
                  SizedBox(height: 16),
                  ShimmerBox(height: 180, width: double.infinity, borderRadius: 12),
                  SizedBox(height: 16),
                  ShimmerBox(height: 100, width: double.infinity, borderRadius: 12),
                ],
              )
            : _error != null && _token == null
                ? ErrorRetry(message: _error!, onRetry: _loadToken)
                : _resultMessage != null
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: ResultBanner(
                              message: _resultMessage!,
                              success: _autoVerified == true,
                              aiSummary: _aiSummary,
                            ),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_token != null) ...[
                        // ── Amount Breakdown ──────────────────────
                        _AmountBreakdownCard(token: _token!),
                        const SizedBox(height: 12),

                        // ── Step 1: Token ─────────────────────────
                        _StepCard(
                          step: '1',
                          title: 'Your Payment Code',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This code is pre-filled as the payment note in UPI. Do NOT change it.',
                                style: TextStyle(
                                    color: context.colors.textGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: context.colors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: context.colors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _token!.token,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: context.colors.primary,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_outline_rounded,
                                            size: 13,
                                            color: context.colors.textGrey),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Locked — do not change in UPI app',
                                          style: TextStyle(
                                              color: context.colors.textGrey,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.schedule_rounded,
                                      size: 13, color: context.colors.textGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires in ${_token!.expiresInText}',
                                    style: TextStyle(
                                        color: context.colors.textGrey,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Step 2: Pay ───────────────────────────
                        _StepCard(
                          step: '2',
                          title:
                              'Pay ₹${_token!.totalAmount.toStringAsFixed(0)} via UPI',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount and note are pre-filled. Do NOT change them in the UPI app.',
                                style: TextStyle(
                                    color: context.colors.textGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _openUpi,
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: Text(
                                  'Pay ₹${_token!.totalAmount.toStringAsFixed(0)} — Open UPI App',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Step 3: Upload ────────────────────────
                        _StepCard(
                          step: '3',
                          title: 'Upload Payment Screenshot',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "After paying, upload the success screenshot. We'll verify it automatically.",
                                style: TextStyle(
                                    color: context.colors.textGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _uploadScreenshot,
                                icon: const Icon(Icons.upload_rounded),
                                label: const Text('Select Screenshot'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  side: BorderSide(
                                      color: context.colors.primary),
                                  foregroundColor: context.colors.primary,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(_error!,
                                    style: TextStyle(
                                        color: context.colors.error, fontSize: 13)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

// ── Amount Breakdown Card ─────────────────────────────────────
class _AmountBreakdownCard extends StatelessWidget {
  final PaymentToken token;
  const _AmountBreakdownCard({required this.token});

  @override
  Widget build(BuildContext context) {
    final hasPenalty = token.penaltyAmount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPenalty
            ? context.colors.warning.withValues(alpha: 0.1)
            : context.colors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPenalty
              ? context.colors.warning.withValues(alpha: 0.3)
              : context.colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPenalty
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: hasPenalty
                    ? context.colors.warning
                    : context.colors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                hasPenalty
                    ? 'Payment includes penalty'
                    : 'Payment summary',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasPenalty
                      ? context.colors.warning
                      : context.colors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(context, 'Monthly contribution', '₹${token.amount.toStringAsFixed(0)}'),
          _row(context, 'Penalty', '₹${token.penaltyAmount.toStringAsFixed(0)}', highlight: token.penaltyAmount > 0),
          const Divider(height: 16),
          _row(context, 'Total Payable', '₹${token.totalAmount.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false, bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: context.colors.textDark)),
            Text(value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w500,
                  color: highlight
                      ? context.colors.warning
                      : bold
                          ? context.colors.textDark
                          : context.colors.textGrey,
                )),
          ],
        ),
      );
}

// ── Step Card ─────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final String step;
  final String title;
  final Widget child;
  const _StepCard(
      {required this.step, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(step,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: context.colors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

