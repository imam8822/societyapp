import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:society_app/core/api/api_client.dart';
import 'package:society_app/core/api/api_services.dart';
import 'package:society_app/core/constants.dart';
import 'package:society_app/models/contribution_models.dart';
import 'package:society_app/models/loan_models.dart';
import 'package:society_app/models/user_models.dart';
import 'package:society_app/providers/data_providers.dart';
import 'package:society_app/widgets/shared_widgets.dart';

// ═════════════════════════════════════════════
// Extracted Provider for Contributions
// ═════════════════════════════════════════════
final myContributionsProvider = FutureProvider.autoDispose<List<Contribution>>((ref) async {
  return await ContributionApi.getMyContributions();
});

// ═════════════════════════════════════════════
// Contribution History
// ═════════════════════════════════════════════
class ContributionHistoryScreen extends ConsumerWidget {
  const ContributionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the named provider instead of creating it anonymously
    final contribAsync = ref.watch(myContributionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Contribution History')),
      body: contribAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(
            message: e.toString(), 
            // 2. Invalidate the named provider to fix the type error
            onRetry: () => ref.invalidate(myContributionsProvider)),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No contributions yet',
                subtitle: 'Your monthly payments will appear here')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _ContributionCard(c: list[i]),
              ),
      ),
    );
  }
}

class _ContributionCard extends StatelessWidget {
  final Contribution c;
  const _ContributionCard({required this.c});

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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.monthName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(DateFormat('d MMM yyyy').format(c.paidDate),
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${c.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  StatusBadge(status: c.isVerified ? 'Verified' : 'Pending'),
                ],
              ),
            ],
          ),
          if (c.transactionReference != null || c.mode == 'Online') ...[
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.tag_rounded,
                    size: 14, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(c.transactionReference ?? '-',
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 12)),
                const Spacer(),
                Text(c.mode,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Loan Apply Screen
// ═════════════════════════════════════════════
class LoanApplyScreen extends ConsumerStatefulWidget {
  const LoanApplyScreen({super.key});

  @override
  ConsumerState<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends ConsumerState<LoanApplyScreen> {
  final _purposeCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '10000');
  bool _loading = false;
  UserSummary? _selectedGuarantor;

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_purposeCtrl.text.trim().isEmpty) {
      _snack('Please enter the loan purpose');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0 || amount > 10000) {
      _snack('Amount must be between ₹1 and ₹10,000');
      return;
    }

    setState(() => _loading = true);
    try {
      final req = ApplyLoanRequest(
        guarantorId: _selectedGuarantor?.id,
        requestedAmount: amount,
        purpose: _purposeCtrl.text.trim(),
      );
      await LoanApi.applyLoan(req);
      if (mounted) {
        _snack('Loan application submitted!');
        context.go('/loan/status');
      }
    } catch (e) {
      _snack(apiError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(userDashboardProvider);
    final guarantorsAsync = ref.watch(eligibleGuarantorsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Apply for Loan')),
      body: dashAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(userDashboardProvider)),
        data: (dash) {
          if (!dash.isEligibleForLoan) {
            return const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Not eligible yet',
              subtitle:
                  'You need at least 12 months of contributions to apply for a loan.',
            );
          }

          return LoadingOverlay(
            isLoading: _loading,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          dash.guarantorRequired
                              ? 'A guarantor is required for your loan as you have less than 2 years membership or less than ₹10,000 saved.'
                              : '✓ No guarantor required — you qualify based on your tenure or savings.',
                          style: const TextStyle(
                              color: AppTheme.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Loan Amount (max ₹10,000)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // Purpose
                TextFormField(
                  controller: _purposeCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Purpose',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Guarantor picker
                if (dash.guarantorRequired) ...[
                  const Text('Select Guarantor',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  guarantorsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(e.toString(),
                        style:
                            const TextStyle(color: AppTheme.error)),
                    data: (guarantors) => guarantors.isEmpty
                        ? const Text(
                            'No eligible guarantors available.',
                            style: TextStyle(color: AppTheme.error),
                          )
                        : DropdownButtonFormField<UserSummary>(
                            initialValue: _selectedGuarantor,
                            hint: const Text('Choose a guarantor'),
                            decoration: const InputDecoration(),
                            items: guarantors
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(
                                          '${g.fullName} (${g.phone})'),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGuarantor = v),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],

                ElevatedButton(
                  onPressed: _loading ? null : _apply,
                  child: const Text('Submit Application'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Loan Status Screen
// ═════════════════════════════════════════════
class LoanStatusScreen extends ConsumerWidget {
  const LoanStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(myLoansProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('My Loans')),
      body: loansAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(myLoansProvider)),
        data: (loans) => loans.isEmpty
            ? const EmptyState(
                icon: Icons.account_balance_outlined,
                title: 'No loan applications',
                subtitle: 'Apply for a loan from the dashboard')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: loans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _LoanDetailCard(loan: loans[i]),
              ),
      ),
    );
  }
}

class _LoanDetailCard extends StatelessWidget {
  final LoanApplication loan;
  const _LoanDetailCard({required this.loan});

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
              Expanded(
                child: Text('₹${loan.requestedAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
              ),
              StatusBadge(status: loan.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(loan.purpose,
              style:
                  const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          const Divider(height: 24),
          InfoRow(
              label: 'Applied',
              value: DateFormat('d MMM yyyy').format(loan.appliedDate)),
          if (loan.repaymentDueDate != null)
            InfoRow(
                label: 'Due Date',
                value: DateFormat('d MMM yyyy')
                    .format(loan.repaymentDueDate!)),
          if (loan.disbursedDate != null)
            InfoRow(
                label: 'Disbursed',
                value: DateFormat('d MMM yyyy')
                    .format(loan.disbursedDate!)),
          if (loan.guarantorName != null)
            InfoRow(label: 'Guarantor', value: loan.guarantorName!),
          if (loan.rejectionReason != null)
            InfoRow(
                label: 'Reason',
                value: loan.rejectionReason!,
                last: true),
          if (loan.repaidAmount != null)
            InfoRow(
                label: 'Repaid',
                value: '₹${loan.repaidAmount!.toStringAsFixed(0)}',
                last: true),
        ],
      ),
    );
  }
}