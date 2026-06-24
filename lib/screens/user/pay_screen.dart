import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_services.dart';
import '../../core/api/api_client.dart';
import '../../core/constants.dart';
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
    final uri = Uri.parse(_token!.upiDeepLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Could not open UPI app. Please install GPay or PhonePe.');
    }
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
      AppToast.showSuccess(context, msg);
    } else {
      AppToast.showError(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Pay Monthly Contribution')),
      body: LoadingOverlay(
        isLoading: _loading,
        child: _loading && _token == null
            ? const SizedBox()
            : _error != null && _token == null
                ? ErrorRetry(message: _error!, onRetry: _loadToken)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_resultMessage != null)
                        ResultBanner(
                          message: _resultMessage!,
                          success: _autoVerified == true,
                          aiSummary: _aiSummary,
                        )
                      else if (_token != null) ...[
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
                              const Text(
                                'This code is pre-filled as the payment note in UPI. Do NOT change it.',
                                style: TextStyle(
                                    color: AppTheme.textGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppTheme.primary.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _token!.token,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primary,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_outline_rounded,
                                            size: 13,
                                            color: AppTheme.textGrey),
                                        SizedBox(width: 4),
                                        Text(
                                          'Locked — do not change in UPI app',
                                          style: TextStyle(
                                              color: AppTheme.textGrey,
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
                                  const Icon(Icons.schedule_rounded,
                                      size: 13, color: AppTheme.textGrey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expires in ${_token!.expiresInText}',
                                    style: const TextStyle(
                                        color: AppTheme.textGrey,
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
                              const Text(
                                'Amount and note are pre-filled. Do NOT change them in the UPI app.',
                                style: TextStyle(
                                    color: AppTheme.textGrey, fontSize: 13),
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
                              const Text(
                                "After paying, upload the success screenshot. We'll verify it automatically.",
                                style: TextStyle(
                                    color: AppTheme.textGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _uploadScreenshot,
                                icon: const Icon(Icons.upload_rounded),
                                label: const Text('Select Screenshot'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  side: const BorderSide(
                                      color: AppTheme.primary),
                                  foregroundColor: AppTheme.primary,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(_error!,
                                    style: const TextStyle(
                                        color: AppTheme.error, fontSize: 13)),
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
            ? const Color(0xFFFFF7ED)
            : AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPenalty
              ? const Color(0xFFFED7AA)
              : AppTheme.primary.withOpacity(0.3),
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
                    ? const Color(0xFFF97316)
                    : AppTheme.primary,
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
                      ? const Color(0xFF9A3412)
                      : AppTheme.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Monthly contribution',
              '₹${token.amount.toStringAsFixed(0)}'),
          if (hasPenalty)
            _row(
              'Penalty (late payment)',
              '+ ₹${token.penaltyAmount.toStringAsFixed(0)}',
              highlight: true,
            ),
          const Divider(height: 16),
          _row(
            'Total to pay',
            '₹${token.totalAmount.toStringAsFixed(0)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, bool highlight = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textDark)),
            Text(value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w500,
                  color: highlight
                      ? const Color(0xFFF97316)
                      : bold
                          ? AppTheme.textDark
                          : AppTheme.textGrey,
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
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
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
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textDark)),
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
