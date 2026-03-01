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
  final now = DateTime.now();
  bool _loading = false;
  PaymentToken? _token;
  String? _error;
  String? _resultMessage;
  bool? _autoVerified;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateToken();
  }

  Future<void> _loadOrGenerateToken() async {
    setState(() { _loading = true; _error = null; });
    try {
      var token = await PaymentApi.getActiveToken(now.month, now.year);
      token ??= await PaymentApi.generateToken(now.month, now.year);
      setState(() => _token = token);
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
    if (_token == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() { _loading = true; _error = null; _resultMessage = null; });
    try {
      final bytes = await File(picked.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      final result = await PaymentApi.uploadScreenshot(_token!.id, base64Str);
      setState(() {
        _resultMessage = result.message;
        _autoVerified = result.autoVerified;
      });
    } catch (e) {
      setState(() => _error = apiError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
                ? ErrorRetry(message: _error!, onRetry: _loadOrGenerateToken)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_resultMessage != null)
                        _ResultBanner(
                          message: _resultMessage!,
                          success: _autoVerified == true,
                        )
                      else if (_token != null) ...[
                        // ── Amount Breakdown ──────────────────────
                        _AmountBreakdownCard(token: _token!),
                        const SizedBox(height: 12),

                        // ── Step 1: Token (locked) ─────────────────
                        _StepCard(
                          step: '1',
                          title: 'Your Payment Code',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'This code is pre-filled as the payment note in UPI. It cannot be changed.',
                                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.lock_outline_rounded,
                                            size: 13, color: AppTheme.textGrey),
                                        const SizedBox(width: 4),
                                        const Text('Locked — do not change in UPI app',
                                            style: TextStyle(
                                                color: AppTheme.textGrey, fontSize: 12)),
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
                                    'Expires in ${_token!.expiresAt.difference(DateTime.now()).inHours}h',
                                    style: const TextStyle(
                                        color: AppTheme.textGrey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Step 2: Pay ──────────────────────────────
                        _StepCard(
                          step: '2',
                          title: 'Pay ₹${_token!.totalAmount.toStringAsFixed(0)} via UPI',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'The amount and note are pre-filled. Do NOT change them in the UPI app.',
                                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _openUpi,
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: Text(
                                    'Pay ₹${_token!.totalAmount.toStringAsFixed(0)} — Open UPI App'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Step 3: Upload ────────────────────────────
                        _StepCard(
                          step: '3',
                          title: 'Upload Payment Screenshot',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'After paying, upload the success screenshot. We\'ll verify it automatically.',
                                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: _uploadScreenshot,
                                icon: const Icon(Icons.upload_rounded),
                                label: const Text('Select Screenshot'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  side: const BorderSide(color: AppTheme.primary),
                                  foregroundColor: AppTheme.primary,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(_error!,
                                    style: const TextStyle(
                                        color: AppTheme.error, fontSize: 13)),
                              ]
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

// ── Amount Breakdown Card ──────────────────────────────────────
class _AmountBreakdownCard extends StatelessWidget {
  final PaymentToken token;
  const _AmountBreakdownCard({required this.token});

  @override
  Widget build(BuildContext context) {
    final hasPenalty = token.penaltyAmount > 0;
    final hasArrears = token.amount > 0 &&
        _coveredMonthsCount(token.coveredMonths) > 1;

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
                hasPenalty ? 'Payment includes penalty' : 'Payment summary',
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
          _row('Monthly contribution', '₹${token.amount.toStringAsFixed(0)}'),
          if (hasArrears)
            _row(
              'Covers ${_coveredMonthsCount(token.coveredMonths)} months',
              '(incl. arrears)',
              small: true,
            ),
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

  int _coveredMonthsCount(String? json) {
    if (json == null) return 1;
    try {
      final list = json.split('{').length - 1;
      return list > 0 ? list : 1;
    } catch (_) {
      return 1;
    }
  }

  Widget _row(String label, String value,
      {bool bold = false, bool highlight = false, bool small = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: small ? 12 : 13,
                  color: small ? AppTheme.textGrey : AppTheme.textDark,
                )),
            Text(value,
                style: TextStyle(
                  fontSize: small ? 12 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
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

  const _StepCard({required this.step, required this.title, required this.child});

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

// ── Result Banner ─────────────────────────────────────────────
class _ResultBanner extends StatelessWidget {
  final String message;
  final bool success;

  const _ResultBanner({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: success ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
            color: success ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: success
                        ? const Color(0xFF15803D)
                        : const Color(0xFF92400E))),
          ),
        ],
      ),
    );
  }
}