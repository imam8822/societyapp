import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_services.dart';
import '../../core/api/api_client.dart';
import '../../core/constants.dart';
import '../../models/loan_models.dart';
import '../../models/payment_models.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';

// ═════════════════════════════════════════════
// Loan Review
// ═════════════════════════════════════════════
class LoanReviewScreen extends ConsumerWidget {
  const LoanReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(allLoansProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Loan Applications')),
      body: loansAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(allLoansProvider)),
        data: (loans) => loans.isEmpty
            ? const EmptyState(
                icon: Icons.account_balance_outlined,
                title: 'No loan applications')
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async => ref.invalidate(allLoansProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: loans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _LoanReviewCard(
                    loan: loans[i],
                    onAction: () => ref.invalidate(allLoansProvider),
                  ),
                ),
              ),
      ),
    );
  }
}

class _LoanReviewCard extends StatefulWidget {
  final LoanApplication loan;
  final VoidCallback onAction;
  const _LoanReviewCard({required this.loan, required this.onAction});

  @override
  State<_LoanReviewCard> createState() => _LoanReviewCardState();
}

class _LoanReviewCardState extends State<_LoanReviewCard> {
  bool _loading = false;

  Future<void> _approve() async {
    // Ask for optional remarks
    final remarks = await _showRemarksDialog(
      title: 'Approve Loan',
      subtitle: 'Add a note for the member (optional)',
      confirmLabel: 'Approve',
      confirmColor: const Color(0xFF16A34A),
      confirmIcon: Icons.check_circle_rounded,
      required: false,
    );
    if (remarks == null) return; // cancelled

    setState(() => _loading = true);
    try {
      await LoanApi.reviewLoan(
        widget.loan.id,
        true,
        remarks.isEmpty ? null : remarks,
      );
      widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    // Ask for required rejection reason
    final reason = await _showRemarksDialog(
      title: 'Reject Loan',
      subtitle: 'Please provide a reason for rejection',
      confirmLabel: 'Reject',
      confirmColor: AppTheme.error,
      confirmIcon: Icons.cancel_rounded,
      required: true,
    );
    if (reason == null || reason.isEmpty) return; // cancelled or empty

    setState(() => _loading = true);
    try {
      await LoanApi.reviewLoan(widget.loan.id, false, reason);
      widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _disburse() async {
    // Confirm before disbursing
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.payments_rounded, color: Color(0xFF7C3AED)),
          SizedBox(width: 10),
          Text('Confirm Disbursement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disburse ₹${NumberFormat('#,##,###').format(widget.loan.amount)} to ${widget.loan.applicantName}?',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              'Repayment due date will be automatically set to the 15th of the month that is ${widget.loan.tenureMonths} months from today.',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.payments_rounded, size: 16),
            label: const Text('Disburse'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await LoanApi.disburseLoan(widget.loan.id);
      widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Returns the typed text on confirm, null on cancel.
  /// If [required] is true, confirm button is disabled until text is entered.
  Future<String?> _showRemarksDialog({
    required String title,
    required String subtitle,
    required String confirmLabel,
    required Color confirmColor,
    required IconData confirmIcon,
    required bool required,
  }) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(confirmIcon, color: confirmColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _DialogRow(
                        label: 'Applicant',
                        value: widget.loan.applicantName),
                    _DialogRow(
                        label: 'Amount',
                        value:
                            '₹${NumberFormat('#,##,###').format(widget.loan.amount)}'),
                    if (widget.loan.tenureMonths != null)
                      _DialogRow(
                          label: 'Tenure',
                          value: '${widget.loan.tenureMonths} months'),
                    if (widget.loan.guarantorName != null)
                      _DialogRow(
                          label: 'Guarantor',
                          value: widget.loan.guarantorName!,
                          last: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 3,
                onChanged: (_) => setLocal(() {}),
                decoration: InputDecoration(
                  hintText: required
                      ? 'Enter reason...'
                      : 'Add a note... (optional)',
                  filled: true,
                  fillColor: AppTheme.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppTheme.divider),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textGrey)),
            ),
            ElevatedButton.icon(
              onPressed: required && ctrl.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, ctrl.text.trim()),
              icon: Icon(confirmIcon, size: 16),
              label: Text(confirmLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                disabledBackgroundColor: AppTheme.divider,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.loan;
    final fmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  l.applicantName.isNotEmpty ? l.applicantName[0] : '?',
                  style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.applicantName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textDark)),
                    Text(l.applicantPhone,
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(status: l.status),
            ],
          ),
          const Divider(height: 20),

          // Loan details
          InfoRow(label: 'Amount', value: fmt.format(l.amount)),
          if (l.tenureMonths != null)
            InfoRow(
                label: 'Tenure', value: '${l.tenureMonths} months'),
          if (l.guarantorName != null)
            InfoRow(
                label: 'Guarantor',
                value: '${l.guarantorName} · ${l.guarantorPhone ?? ""}'),
          InfoRow(
              label: 'Applied',
              value: DateFormat('d MMM yyyy').format(l.appliedDate),
              last: l.repaymentDueDate == null && l.rejectionReason == null),
          if (l.rejectionReason != null)
            InfoRow(
                label: 'Reason',
                value: l.rejectionReason!,
                last: true),
          if (l.repaymentDueDate != null)
            InfoRow(
              label: 'Due Date',
              value: 'On or before ${DateFormat('d MMM yyyy').format(l.repaymentDueDate!)}',
              last: true,
            ),

          // Actions
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else if (l.isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Reject
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Approve
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _approve,
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (l.isApproved) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _disburse,
              icon: const Icon(Icons.payments_rounded, size: 16),
              label: const Text('Mark as Disbursed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Small helper widget for dialog rows
class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;
  const _DialogRow(
      {required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textGrey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Screenshot Review
// ═════════════════════════════════════════════
class ScreenshotReviewScreen extends ConsumerWidget {
  const ScreenshotReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenshotsAsync = ref.watch(pendingScreenshotsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Screenshot Reviews')),
      body: screenshotsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(pendingScreenshotsProvider)),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'All clear!',
                subtitle: 'No screenshots pending review')
            : RefreshIndicator(
                color: AppTheme.primary,
                onRefresh: () async =>
                    ref.invalidate(pendingScreenshotsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ScreenshotCard(
                    item: items[i],
                    onAction: () => ref.invalidate(pendingScreenshotsProvider),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ScreenshotCard extends StatefulWidget {
  final PendingScreenshot item;
  final VoidCallback onAction;
  const _ScreenshotCard({required this.item, required this.onAction});

  @override
  State<_ScreenshotCard> createState() => _ScreenshotCardState();
}

class _ScreenshotCardState extends State<_ScreenshotCard> {
  bool _loading = false;

  Future<void> _verify(bool approve) async {
    setState(() => _loading = true);
    try {
      await PaymentApi.adminVerify(
          widget.item.contributionId,
          approve,
          approve ? 'Verified by admin' : null);
      widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _viewScreenshot() {
    if (widget.item.screenshotUrl == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(
                  '${widget.item.userName} - ${widget.item.monthName}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context))
              ],
            ),
            Image.memory(
              Uri.parse(widget.item.screenshotUrl!).data!.contentAsBytes(),
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.item;
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
              CircleAvatar(
                backgroundColor: AppTheme.primaryLight,
                child: Text(s.userName[0],
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textDark)),
                    Text('${s.userPhone} • ${s.monthName}',
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              Text('₹${s.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
            ],
          ),

          if (s.aiSummary != null || s.token != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.token != null) ...[
                    const Text('Token expected:',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textGrey)),
                    Text(s.token!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontSize: 13,
                            letterSpacing: 1)),
                    const SizedBox(height: 6),
                  ],
                  if (s.aiSummary != null)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 12, color: AppTheme.textGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(s.aiSummary!,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textGrey)),
                        ),
                      ],
                    ),
                  if (s.aiExtractedAmount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'AI extracted: ₹${s.aiExtractedAmount!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textGrey),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _viewScreenshot,
            icon: const Icon(Icons.image_outlined, size: 16),
            label: const Text('View Screenshot'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 40),
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
            ),
          ),

          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary)),
            )
          else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verify(false),
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verify(true),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Reports
// ═════════════════════════════════════════════
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final now = DateTime.now();
  bool _loading = false;
  dynamic _report;
  bool _isMonthly = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Future<void> _load() async {
    setState(() { _loading = true; _report = null; });
    try {
      if (_isMonthly) {
        _report = await ContributionApi.getMonthlyReport(
            _selectedMonth, _selectedYear);
      } else {
        _report = await ContributionApi.getYearlyReport(_selectedYear);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Container(
            color: AppTheme.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TabBtn(
                        label: 'Monthly',
                        selected: _isMonthly,
                        onTap: () {
                          setState(() => _isMonthly = true);
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TabBtn(
                        label: 'Yearly',
                        selected: !_isMonthly,
                        onTap: () {
                          setState(() => _isMonthly = false);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_isMonthly) ...[
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10)),
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(months[i + 1])),
                          ),
                          onChanged: (v) {
                            setState(() => _selectedMonth = v!);
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10)),
                        items: List.generate(
                          5,
                          (i) => DropdownMenuItem(
                              value: now.year - i,
                              child: Text('${now.year - i}')),
                        ),
                        onChanged: (v) {
                          setState(() => _selectedYear = v!);
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _report == null
                    ? const EmptyState(
                        icon: Icons.bar_chart_rounded,
                        title: 'No data available')
                    : _isMonthly
                        ? _MonthlyReportView(report: _report)
                        : _YearlyReportView(report: _report),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.bgGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: selected ? Colors.white : AppTheme.textGrey,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MonthlyReportView extends StatelessWidget {
  final dynamic report;
  const _MonthlyReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
                child: StatCard(
                    label: 'Paid',
                    value: '${report.paidCount}',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF16A34A))),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Unpaid',
                    value: '${report.unpaidCount}',
                    icon: Icons.cancel_outlined,
                    iconColor: AppTheme.error)),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Collected',
                    value: '₹${report.totalCollected.toStringAsFixed(0)}',
                    icon: Icons.savings_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        ...report.contributions
            .map<Widget>((c) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c.userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark)),
                      ),
                      StatusBadge(
                          status: c.isVerified ? 'Verified' : 'Pending'),
                      const SizedBox(width: 8),
                      Text('₹${c.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }
}

class _YearlyReportView extends StatelessWidget {
  final dynamic report;
  const _YearlyReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        StatCard(
            label: 'Total Collected ${report.year}',
            value: '₹${report.totalCollected.toStringAsFixed(0)}',
            icon: Icons.savings_rounded),
        const SizedBox(height: 16),
        ...report.memberRows.map<Widget>((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark)),
                        Text('${r.monthsPaid}/12 months paid',
                            style: const TextStyle(
                                color: AppTheme.textGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('₹${r.totalSaved.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                ],
              ),
            )),
      ],
    );
  }
}

// ═════════════════════════════════════════════
// Settings Screen
// ═════════════════════════════════════════════
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _upiNameCtrl = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  SocietySettings? _settings;
  String? _logoBase64;
  bool _logoChanged = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year}, $h:$m';
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final base64Str = 'data:image/png;base64,${base64Encode(bytes)}';
    setState(() { _logoBase64 = base64Str; _logoChanged = true; });
  }

  void _removeLogo() =>
      setState(() { _logoBase64 = null; _logoChanged = true; });

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final s = await SettingsApi.getSettings();
      _settings = s;
      _logoBase64 = s.logoBase64;
      _nameCtrl.text = s.societyName;
      _upiCtrl.text = s.upiId;
      _upiNameCtrl.text = s.upiDisplayName;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'societyName': _nameCtrl.text.trim(),
        'upiId': _upiCtrl.text.trim(),
        'upiDisplayName': _upiNameCtrl.text.trim(),
        if (_logoChanged) 'logoBase64': _logoBase64,
      };
      await SettingsApi.updateSettings(payload);
      setState(() => _logoChanged = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _upiCtrl.dispose();
    _upiNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Society Settings')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : LoadingOverlay(
              isLoading: _saving,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SOCIETY LOGO',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                                fontSize: 12,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 16),
                        Row(children: [
                          GestureDetector(
                            onTap: _pickLogo,
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.bgGrey,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.divider, width: 1.5),
                              ),
                              child: _logoBase64 != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.memory(
                                        base64Decode(_logoBase64!.contains(',')
                                            ? _logoBase64!.split(',')[1]
                                            : _logoBase64!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            color: AppTheme.textGrey, size: 28),
                                        SizedBox(height: 4),
                                        Text('Add Logo',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppTheme.textGrey)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Society Logo',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppTheme.textDark)),
                                const SizedBox(height: 4),
                                const Text(
                                    'Shown on member dashboard.\nJPG or PNG, max 2MB.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textGrey)),
                                const SizedBox(height: 10),
                                Row(children: [
                                  OutlinedButton.icon(
                                    onPressed: _pickLogo,
                                    icon: const Icon(Icons.upload_rounded,
                                        size: 16),
                                    label: Text(_logoBase64 != null
                                        ? 'Change'
                                        : 'Upload'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      textStyle:
                                          const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  if (_logoBase64 != null) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _removeLogo,
                                      icon: const Icon(Icons.delete_outline,
                                          size: 16),
                                      label: const Text('Remove'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        textStyle:
                                            const TextStyle(fontSize: 12),
                                        foregroundColor: AppTheme.error,
                                        side: const BorderSide(
                                            color: AppTheme.error),
                                      ),
                                    ),
                                  ],
                                ]),
                              ],
                            ),
                          ),
                        ]),
                        if (_logoChanged)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(children: [
                              const Icon(Icons.info_outline,
                                  size: 14, color: AppTheme.warning),
                              const SizedBox(width: 6),
                              Text(
                                _logoBase64 != null
                                    ? 'New logo selected — save to apply.'
                                    : 'Logo will be removed on save.',
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.warning),
                              ),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Society name
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GENERAL',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                                fontSize: 12,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Society Name',
                            prefixIcon: Icon(Icons.home_work_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // UPI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('UPI PAYMENT',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                                fontSize: 12,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _upiCtrl,
                          decoration: const InputDecoration(
                            labelText: 'UPI ID',
                            hintText: 'e.g. society@okicici',
                            prefixIcon:
                                Icon(Icons.account_balance_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _upiNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'UPI Display Name',
                            hintText: 'Name shown in payment app',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This name appears in GPay/PhonePe when members pay.',
                          style: TextStyle(
                              color: AppTheme.textGrey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_settings?.updatedAt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(children: [
                        const Icon(Icons.history_rounded,
                            size: 16, color: AppTheme.textGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textGrey),
                              children: [
                                const TextSpan(text: 'Last updated by '),
                                TextSpan(
                                  text: _settings!.updatedByName ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark),
                                ),
                                TextSpan(
                                  text:
                                      ' on ${_formatDate(_settings!.updatedAt!)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
    );
  }
}