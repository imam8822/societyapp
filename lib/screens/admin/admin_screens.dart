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

  Future<void> _review(bool approve) async {
    DateTime? dueDate;
    String? reason;

    if (approve) {
      dueDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 90)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        helpText: 'Set Repayment Due Date',
      );
      if (dueDate == null) return;
    } else {
      reason = await _askReason();
      if (reason == null) return;
    }

    setState(() => _loading = true);
    try {
      await LoanApi.reviewLoan(
          widget.loan.id, approve, reason, dueDate);
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
    final dueDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Set Repayment Due Date',
    );
    if (dueDate == null) return;

    setState(() => _loading = true);
    try {
      await LoanApi.disburseLoan(widget.loan.id, dueDate);
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

  Future<String?> _askReason() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: ctrl,
          decoration:
              const InputDecoration(hintText: 'Enter reason...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text('Reject')),
        ],
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
          Row(
            children: [
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
          InfoRow(
              label: 'Amount', value: fmt.format(l.requestedAmount)),
          InfoRow(label: 'Purpose', value: l.purpose),
          InfoRow(
              label: 'Saved',
              value: fmt.format(l.applicantTotalSaved)),
          if (l.guarantorName != null)
            InfoRow(
                label: 'Guarantor',
                value: '${l.guarantorName} (${l.guarantorPhone})'),
          InfoRow(
              label: 'Applied',
              value: DateFormat('d MMM yyyy').format(l.appliedDate),
              last: l.repaymentDueDate == null),
          if (l.repaymentDueDate != null)
            InfoRow(
              label: 'Due Date',
              value: DateFormat('d MMM yyyy').format(l.repaymentDueDate!),
              last: true,
            ),

          // Actions
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primary)),
            )
          else if (l.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _review(false),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _review(true),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ] else if (l.isApproved) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _disburse,
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Mark as Disbursed'),
            ),
          ],
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
          widget.item.tokenId, approve, approve ? 'Verified by admin' : null);
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
              title: Text('${widget.item.userName} - ${widget.item.monthName}'),
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

          if (s.ocrExtractedText != null) ...[
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
                  const Text('Token expected:',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textGrey)),
                  Text(s.token,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  const Text('OCR could not confirm this token in screenshot.',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.textGrey)),
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
                  child: CircularProgressIndicator(
                      color: AppTheme.primary)),
            )
          else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _verify(false),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error)),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _verify(true),
                    child: const Text('Approve'),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      setState(() => _loading = false);
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
          // Controls
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

          // Results
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primary))
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

  const _TabBtn(
      {required this.label, required this.selected, required this.onTap});

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
  final report;
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
  final report;
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
  String? _logoBase64;       // current logo from DB
  bool _logoChanged = false; // user picked a new logo

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
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final base64Str = 'data:image/png;base64,${base64Encode(bytes)}';
    setState(() { _logoBase64 = base64Str; _logoChanged = true; });
  }

  void _removeLogo() {
    setState(() { _logoBase64 = null; _logoChanged = true; });
  }

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
      setState(() => _loading = false);
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
      setState(() => _saving = false);
    }
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
                  // ── Society Logo ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('SOCIETY LOGO',
                          style: TextStyle(fontWeight: FontWeight.w600,
                              color: AppTheme.textGrey, fontSize: 12, letterSpacing: 0.5)),
                      const SizedBox(height: 16),
                      Row(children: [
                        // Logo preview
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.bgGrey,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.divider, width: 1.5),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined,
                                          color: AppTheme.textGrey, size: 28),
                                      SizedBox(height: 4),
                                      Text('Add Logo',
                                          style: TextStyle(
                                              fontSize: 10, color: AppTheme.textGrey)),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Society Logo',
                                style: TextStyle(fontWeight: FontWeight.w600,
                                    fontSize: 14, color: AppTheme.textDark)),
                            const SizedBox(height: 4),
                            const Text('Shown on member dashboard and receipts.\nJPG or PNG, max 2MB.',
                                style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                            const SizedBox(height: 10),
                            Row(children: [
                              OutlinedButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.upload_rounded, size: 16),
                                label: Text(_logoBase64 != null ? 'Change' : 'Upload'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                              if (_logoBase64 != null) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _removeLogo,
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Remove'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                    foregroundColor: AppTheme.error,
                                    side: const BorderSide(color: AppTheme.error),
                                  ),
                                ),
                              ],
                            ]),
                          ]),
                        ),
                      ]),
                      if (_logoChanged)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(children: [
                            const Icon(Icons.info_outline, size: 14, color: AppTheme.warning),
                            const SizedBox(width: 6),
                            Text(
                              _logoBase64 != null ? 'New logo selected — save to apply.' : 'Logo will be removed on save.',
                              style: const TextStyle(fontSize: 12, color: AppTheme.warning),
                            ),
                          ]),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 14),
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
                        const Text('General',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                                fontSize: 12)),
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
                        const Text('UPI Payment',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                                fontSize: 12)),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _upiCtrl,
                          decoration: const InputDecoration(
                            labelText: 'UPI ID',
                            hintText: 'e.g. society@okicici',
                            prefixIcon: Icon(Icons.account_balance_outlined),
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
                  // Last updated info
                  if (_settings?.updatedAt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(children: [
                        const Icon(Icons.history_rounded, size: 16, color: AppTheme.textGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                              children: [
                                const TextSpan(text: 'Last updated by '),
                                TextSpan(
                                  text: _settings!.updatedByName ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                ),
                                TextSpan(
                                  text: ' on ${_formatDate(_settings!.updatedAt!)}',
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _upiCtrl.dispose();
    _upiNameCtrl.dispose();
    super.dispose();
  }
}