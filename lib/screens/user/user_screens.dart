import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:society_app/core/api/api_client.dart';
import 'package:society_app/core/api/api_services.dart';
import 'package:society_app/core/constants.dart';
import 'package:society_app/models/contribution_models.dart';
import 'package:society_app/models/loan_models.dart';
import 'package:society_app/providers/data_providers.dart';
import 'package:society_app/widgets/shared_widgets.dart';

// ═════════════════════════════════════════════
// Contribution History
// ═════════════════════════════════════════════
final myContributionsProvider = FutureProvider.autoDispose<List<Contribution>>((ref) async {
  return await ContributionApi.getMyContributions();
});

class ContributionHistoryScreen extends ConsumerWidget {
  const ContributionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contribAsync = ref.watch(myContributionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Contribution History')),
      body: contribAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
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
                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
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
                const Icon(Icons.tag_rounded, size: 14, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(c.transactionReference ?? '-',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                const Spacer(),
                Text(c.mode,
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
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
// Loads loan options + guarantors from API,
// shows eligibility inline on option selection
// ═════════════════════════════════════════════
class LoanApplyScreen extends StatefulWidget {
  const LoanApplyScreen({super.key});
  @override
  State<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends State<LoanApplyScreen> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _formKey = GlobalKey<FormState>();

  LoanFormData? _formData;
  bool _loadingForm = true;
  bool _submitting = false;

  LoanOption? _selectedOption;
  GuarantorOption? _selectedGuarantor;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadForm() async {
    try {
      final data = await LoanApi.getFormData();
      setState(() { _formData = data; _loadingForm = false; });
    } catch (e) {
      setState(() => _loadingForm = false);
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  // Use guarantorRequired flag from backend — already calculated per user
  bool get _needsGuarantor =>
      _selectedOption != null && _selectedOption!.guarantorRequired;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOption == null) {
      _snack('Please select a loan amount');
      return;
    }
    if (!_selectedOption!.isEligible) {
      _snack('You are not eligible for this loan option');
      return;
    }
    if (_needsGuarantor && _selectedGuarantor == null) {
      _snack('Please select a guarantor');
      return;
    }

    setState(() => _submitting = true);
    try {
      await LoanApi.applyLoan(ApplyLoanRequest(
        loanOptionId: _selectedOption!.id,
        guarantorId: _needsGuarantor ? _selectedGuarantor?.id : null,
      ));
      if (mounted) {
        _snack('Loan application submitted!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack(apiError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// Repayment due = on or before 15th of the month that is [tenureMonths] from today
  /// e.g. Applied March 18 + 4 months → due on or before July 15
  String _repaymentDate(int tenureMonths) {
    final now = DateTime.now();
    final dueMonth = DateTime(now.year, now.month + tenureMonths, 15);
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'On or before 15 ${months[dueMonth.month]} ${dueMonth.year}';
  }

  Widget _summaryRow(IconData icon, String label, String value,
      {bool highlight = false}) =>
      Row(children: [
        Icon(icon,
            size: 14,
            color: highlight ? AppTheme.primary : AppTheme.textGrey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textGrey)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppTheme.primary : AppTheme.textDark)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Apply for Loan')),
      body: _loadingForm
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _formData == null
              ? Center(
                  child: ErrorRetry(
                    message: 'Failed to load loan options',
                    onRetry: () {
                      setState(() => _loadingForm = true);
                      _loadForm();
                    },
                  ))
              : _buildForm(_formData!),
    );
  }

  Widget _buildForm(LoanFormData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(children: [

          // ── Guarantor/amount info banner ─────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _needsGuarantor ? const Color(0xFFFFF8E1) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _needsGuarantor ? AppTheme.warning : const Color(0xFF2ECC71)),
            ),
            child: Row(children: [
              Icon(
                _needsGuarantor ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                color: _needsGuarantor ? AppTheme.warning : const Color(0xFF2ECC71),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _needsGuarantor
                      ? 'Loan amount exceeds your invested amount (${_fmt.format(data.userTotalInvested)}). A guarantor is required.'
                      : 'Your investment of ${_fmt.format(data.userTotalInvested)} covers this loan — no guarantor needed.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _needsGuarantor ? AppTheme.warning : const Color(0xFF2ECC71),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Loan Amount ──────────────────────────────
          _Section(title: 'Loan Amount', children: [
            DropdownButtonFormField<LoanOption>(
              value: _selectedOption,
              isExpanded: true,
              hint: const Text('Select amount'),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.currency_rupee_rounded)),
              items: data.loanOptions.map((o) => DropdownMenuItem(
                value: o,
                child: Text(
                  '${o.label}  (${o.minTenureRequired} months required)',
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
              onChanged: (v) => setState(() {
                _selectedOption = v;
                _selectedGuarantor = null;
              }),
            ),

            // Eligibility feedback + repayment summary
            if (_selectedOption != null) ...[
              const SizedBox(height: 10),
              if (_selectedOption!.isEligible) ...[
                // Repayment details card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.primary, size: 16),
                        const SizedBox(width: 6),
                        const Text('You are eligible!',
                            style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                      const SizedBox(height: 10),
                      // Tenure row
                      _summaryRow(
                        Icons.calendar_month_outlined,
                        'Repayment Tenure',
                        '${_selectedOption!.maxRepaymentTenure} months',
                      ),
                      const SizedBox(height: 6),
                      // Total repayment row
                      _summaryRow(
                        Icons.receipt_long_outlined,
                        'Single Repayment',
                        _fmt.format(_selectedOption!.repaymentAmount),
                        highlight: true,
                      ),
                      const SizedBox(height: 6),
                      // Repayment due date row
                      _summaryRow(
                        Icons.event_rounded,
                        'Due Date',
                        _repaymentDate(_selectedOption!.maxRepaymentTenure),
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error),
                  ),
                  child: Row(children: [
                    const Icon(Icons.lock_outline, color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You need ${_selectedOption!.minTenureRequired} months paid for ${_selectedOption!.label}. '
                        'You have ${data.userPaidMonths} months.',
                        style: const TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                    ),
                  ]),
                ),
            ],
          ]),
          const SizedBox(height: 14),

          // ── Guarantor (only if needed) ───────────────
          if (_needsGuarantor)
            _Section(title: 'Guarantor', children: [
              data.availableGuarantors.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: AppTheme.error, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No eligible guarantors available.',
                            style: TextStyle(color: AppTheme.error, fontSize: 12),
                          ),
                        ),
                      ]),
                    )
                  : DropdownButtonFormField<GuarantorOption>(
                      value: _selectedGuarantor,
                      isExpanded: true,
                      hint: const Text('Select guarantor'),
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.people_outlined)),
                      items: data.availableGuarantors.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text('${g.fullName} (${g.phone})',
                            overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedGuarantor = v),
                      validator: (v) =>
                          _needsGuarantor && v == null ? 'Select guarantor' : null,
                    ),
            ]),
          if (_needsGuarantor) const SizedBox(height: 14),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: (_submitting || (_selectedOption != null && !_selectedOption!.isEligible))
                ? null
                : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Submit Application'),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textGrey,
              letterSpacing: 0.5)),
      const SizedBox(height: 12),
      ...children,
    ]),
  );
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
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
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
          Row(children: [
            Expanded(
              child: Text(
                '₹${loan.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark),
              ),
            ),
            StatusBadge(status: loan.status),
          ]),
          const Divider(height: 24),
          InfoRow(
              label: 'Applied',
              value: DateFormat('d MMM yyyy').format(loan.appliedDate)),
          if (loan.tenureMonths != null)
            InfoRow(label: 'Tenure', value: '${loan.tenureMonths} months'),
          if (loan.disbursedDate != null)
            InfoRow(
                label: 'Disbursed',
                value: DateFormat('d MMM yyyy').format(loan.disbursedDate!)),
          if (loan.repaymentDueDate != null)
            InfoRow(
                label: 'Due Date',
                value: 'On or before ${DateFormat('d MMM yyyy').format(loan.repaymentDueDate!)}'),
          if (loan.totalRepaid > 0)
            InfoRow(
                label: 'Repaid',
                value: '₹${loan.totalRepaid.toStringAsFixed(0)}'),
          if (loan.outstandingAmount > 0)
            InfoRow(
                label: 'Outstanding',
                value: '₹${loan.outstandingAmount.toStringAsFixed(0)}'),
          if (loan.guarantorName != null)
            InfoRow(label: 'Guarantor', value: loan.guarantorName!),
          if (loan.rejectionReason != null)
            InfoRow(
                label: 'Reason',
                value: loan.rejectionReason!,
                last: true),
        ],
      ),
    );
  }
}