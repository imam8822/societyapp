import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api/api_services.dart';
import '../../core/api/api_client.dart';
import '../../core/constants.dart';
import '../../models/payment_models.dart';
import '../../widgets/shared_widgets.dart';

class LoanRepayScreen extends ConsumerStatefulWidget {
  final int loanId;
  const LoanRepayScreen({super.key, required this.loanId});

  @override
  ConsumerState<LoanRepayScreen> createState() => _LoanRepayScreenState();
}

class _LoanRepayScreenState extends ConsumerState<LoanRepayScreen> {
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

  Future<void> _loadToken() async {
    setState(() { _loading = true; _error = null; });
    try {
      final token = await PaymentApi.getOrCreateLoanToken(widget.loanId);
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
      final result = await PaymentApi.uploadLoanScreenshot(
          widget.loanId, base64Str);
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
    if (msg.contains('success') || msg.contains('verified') || msg.contains('uploaded') || msg.contains('repaid')) {
      AppToast.showSuccess(context, msg);
    } else {
      AppToast.showError(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(title: const Text('Repay Loan')),
      body: LoadingOverlay(
        isLoading: _loading,
        child: _loading && _token == null
            ? const SizedBox()
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
                        // ── Amount Card ─────────────────────────
                        _LoanRepaymentAmountCard(token: _token!),
                        const SizedBox(height: 12),

                        // ── Step 1: Token ───────────────────────
                        _StepCard(
                          step: '1',
                          title: 'Your Repayment Code',
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
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _token!.token,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2563EB),
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

                        // ── Step 2: Pay ─────────────────────────
                        _StepCard(
                          step: '2',
                          title:
                              'Pay ${fmt.format(_token!.totalAmount)} via UPI',
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
                                icon:
                                    const Icon(Icons.open_in_new_rounded),
                                label: Text(
                                  'Pay ${fmt.format(_token!.totalAmount)} — Open UPI App',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Step 3: Upload ──────────────────────
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
                                  minimumSize:
                                      const Size(double.infinity, 50),
                                  side: const BorderSide(
                                      color: Color(0xFF2563EB)),
                                  foregroundColor: const Color(0xFF2563EB),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(_error!,
                                    style: TextStyle(
                                        color: context.colors.error,
                                        fontSize: 13)),
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

// ── Loan Repayment Amount Card ────────────────────────────────
class _LoanRepaymentAmountCard extends StatelessWidget {
  final PaymentToken token;
  const _LoanRepaymentAmountCard({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_rounded,
                  color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 8),
              Text(
                'Loan Repayment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(context, 'Repayment amount',
              '₹${token.amount.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) => Padding(
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
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold
                      ? const Color(0xFF1E40AF)
                      : context.colors.textGrey,
                )),
          ],
        ),
      );
}

// ── Step Card (reused from pay_screen pattern) ────────────────
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
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
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

