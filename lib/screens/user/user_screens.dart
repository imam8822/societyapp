import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:society_app/core/api/api_client.dart';
import 'package:society_app/core/api/api_services.dart';
import 'package:society_app/core/constants.dart';
import 'package:society_app/core/storage/storage_service.dart';
import 'package:society_app/models/contribution_models.dart';
import 'package:society_app/models/loan_models.dart';
import 'package:society_app/providers/data_providers.dart';
import 'package:society_app/widgets/shared_widgets.dart';

// ═════════════════════════════════════════════
// Contribution History
// ═════════════════════════════════════════════

class ContributionHistoryScreen extends ConsumerWidget {
  const ContributionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contribAsync = ref.watch(myContributionsProvider);

    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(title: const Text('Contribution History')),
      body: contribAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: context.colors.primary)),
        error: (e, _) => ErrorRetry(
            message: apiError(e),
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
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.divider),
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
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: context.colors.textDark)),
                    const SizedBox(height: 2),
                    Text(DateFormat('d MMM yyyy').format(c.paidDate),
                        style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${c.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: context.colors.textDark)),
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
                Icon(Icons.tag_rounded, size: 14, color: context.colors.textGrey),
                const SizedBox(width: 4),
                Text(c.transactionReference ?? '-',
                    style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
                const Spacer(),
                Text(c.mode,
                    style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
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
class LoanApplyScreen extends ConsumerStatefulWidget {
  const LoanApplyScreen({super.key});
  @override
  ConsumerState<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends ConsumerState<LoanApplyScreen> {
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _formKey = GlobalKey<FormState>();

  LoanFormData? _formData;
  bool _loadingForm = true;
  bool _submitting = false;

  LoanOption? _selectedOption;
  GuarantorOption? _selectedGuarantor;
  GuarantorOption? _selectedGuarantor2;

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
      if (mounted) AppToast.showError(context, apiError(e));
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
    if (_needsGuarantor && _selectedOption!.requiredGuarantors == 2 && _selectedGuarantor2 == null) {
      _snack('Please select a second guarantor');
      return;
    }
    if (_needsGuarantor && _selectedOption!.requiredGuarantors == 2 && _selectedGuarantor?.id == _selectedGuarantor2?.id) {
      _snack('Guarantor 1 and Guarantor 2 must be different people');
      return;
    }

    setState(() => _submitting = true);
    try {
      await LoanApi.applyLoan(ApplyLoanRequest(
        loanOptionId: _selectedOption!.id,
        guarantorId: _needsGuarantor ? _selectedGuarantor?.id : null,
        guarantor2Id: (_needsGuarantor && _selectedOption!.requiredGuarantors == 2) ? _selectedGuarantor2?.id : null,
      ));
      if (mounted) {
        ref.invalidate(userDashboardProvider);
        ref.invalidate(myLoansProvider);
        _snack('Loan application submitted!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _snack(apiError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) {
    if (msg.contains('submitted') || msg.contains('success')) {
      AppToast.showSuccess(context, msg);
    } else {
      AppToast.showError(context, msg);
    }
  }

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
            color: highlight ? context.colors.primary : context.colors.textGrey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(
                fontSize: 12, color: context.colors.textGrey)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? context.colors.primary : context.colors.textDark)),
      ]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(title: const Text('Apply for Loan')),
      body: _loadingForm
          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
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
              color: _needsGuarantor 
                  ? const Color(0xFF261D15) 
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _needsGuarantor ? context.colors.warning : const Color(0xFF10B981)),
            ),
            child: Row(children: [
              Icon(
                _needsGuarantor ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                color: _needsGuarantor ? context.colors.warning : const Color(0xFF10B981),
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
                    color: _needsGuarantor ? context.colors.warning : const Color(0xFF10B981),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Loan Amount ──────────────────────────────
          _Section(title: 'Loan Amount', children: [
            InkWell(
              onTap: () => _showAmountBottomSheet(data),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: context.colors.bgGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.currency_rupee_rounded, color: context.colors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedOption != null 
                            ? '${_selectedOption!.label}' 
                            : 'Select amount',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedOption != null ? context.colors.textDark : context.colors.textGrey,
                        ),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textGrey),
                  ],
                ),
              ),
            ),

            // Eligibility feedback + repayment summary
            if (_selectedOption != null) ...[
              const SizedBox(height: 10),
              if (_selectedOption!.isEligible) ...[
                // Repayment details card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.check_circle_outline,
                            color: context.colors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text('You are eligible!',
                            style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                      const SizedBox(height: 10),
                      // Repayment amount row
                      _summaryRow(
                        Icons.payments_outlined,
                        'Repayment Amount',
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
                    color: context.colors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.error),
                  ),
                  child: Row(children: [
                    Icon(Icons.lock_outline, color: context.colors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You need ${_selectedOption!.minTenureRequired} months paid for ${_selectedOption!.label}. '
                        'You have ${data.userPaidMonths} months.',
                        style: TextStyle(color: context.colors.error, fontSize: 12),
                      ),
                    ),
                  ]),
                ),
            ],
          ]),
          const SizedBox(height: 14),

          // ── Guarantor (only if needed) ───────────────
          if (_needsGuarantor)
            _Section(title: _selectedOption!.requiredGuarantors == 2 ? 'Guarantor 1' : 'Guarantor', children: [
              data.availableGuarantors.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: context.colors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No eligible guarantors available.',
                            style: TextStyle(color: context.colors.error, fontSize: 12),
                          ),
                        ),
                      ]),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _showGuarantorBottomSheet(data, isGuarantor2: false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: context.colors.bgGrey,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: (_needsGuarantor && _submitting && _selectedGuarantor == null) ? context.colors.error : context.colors.divider),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.people_outlined, color: context.colors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedGuarantor != null 
                                        ? '${_selectedGuarantor!.fullName} (Limit: ₹${_selectedGuarantor!.availableGuaranteeLimit.toStringAsFixed(0)})' 
                                        : 'Select guarantor',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _selectedGuarantor != null ? context.colors.textDark : context.colors.textGrey,
                                    ),
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textGrey),
                              ],
                            ),
                          ),
                        ),
                        if (_needsGuarantor && _submitting && _selectedGuarantor == null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 8),
                            child: Text('Please select a guarantor', style: TextStyle(color: context.colors.error, fontSize: 12)),
                          ),
                      ],
                    ),
            ]),
          if (_needsGuarantor && _selectedOption!.requiredGuarantors == 2) ...[
            const SizedBox(height: 14),
            _Section(title: 'Guarantor 2', children: [
              data.availableGuarantors.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.warning_amber_rounded, color: context.colors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text('No eligible guarantors available.', style: TextStyle(color: context.colors.error, fontSize: 12))),
                      ]),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _showGuarantorBottomSheet(data, isGuarantor2: true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: context.colors.bgGrey,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: (_submitting && _selectedGuarantor2 == null) ? context.colors.error : context.colors.divider),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.people_outlined, color: context.colors.primary, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedGuarantor2 != null 
                                        ? '${_selectedGuarantor2!.fullName} (Limit: ₹${_selectedGuarantor2!.availableGuaranteeLimit.toStringAsFixed(0)})' 
                                        : 'Select second guarantor',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _selectedGuarantor2 != null ? context.colors.textDark : context.colors.textGrey,
                                    ),
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textGrey),
                              ],
                            ),
                          ),
                        ),
                        if (_submitting && _selectedGuarantor2 == null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 8),
                            child: Text('Please select a second guarantor', style: TextStyle(color: context.colors.error, fontSize: 12)),
                          ),
                      ],
                    ),
            ]),
          ],
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

  void _showAmountBottomSheet(LoanFormData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text('Select Loan Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textDark)),
              ),
              Divider(height: 1, color: context.colors.divider),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: data.loanOptions.length,
                  itemBuilder: (ctx, i) {
                    final o = data.loanOptions[i];
                    final isSelected = _selectedOption?.id == o.id;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedOption = o;
                          _selectedGuarantor = null;
                          _selectedGuarantor2 = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? context.colors.primary.withValues(alpha: 0.05) : Colors.transparent,
                          border: Border(bottom: BorderSide(color: context.colors.divider.withValues(alpha: 0.5))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? context.colors.primary : context.colors.surfaceWhite,
                                shape: BoxShape.circle,
                                border: isSelected ? null : Border.all(color: context.colors.divider),
                              ),
                              child: Icon(Icons.currency_rupee_rounded, 
                                  color: isSelected ? Colors.white : context.colors.textGrey, size: 18),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.label, style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? context.colors.primary : context.colors.textDark)),
                                ],
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_circle_rounded, color: context.colors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuarantorBottomSheet(LoanFormData data, {bool isGuarantor2 = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.bgGrey,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredGuarantors = data.availableGuarantors.where((g) {
              return g.fullName.toLowerCase().contains(searchQuery.toLowerCase()) || 
                     g.phone.contains(searchQuery);
            }).toList();

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(isGuarantor2 ? 'Select Second Guarantor' : 'Select Guarantor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textDark)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone...',
                          prefixIcon: Icon(Icons.search, color: context.colors.textGrey),
                          filled: true,
                          fillColor: context.colors.surfaceWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                    Divider(height: 1, color: context.colors.divider),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredGuarantors.length,
                        itemBuilder: (ctx, i) {
                          final g = filteredGuarantors[i];
                          final isSelected = isGuarantor2 
                              ? _selectedGuarantor2?.id == g.id 
                              : _selectedGuarantor?.id == g.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isGuarantor2) {
                                  _selectedGuarantor2 = g;
                                } else {
                                  _selectedGuarantor = g;
                                }
                              });
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected ? context.colors.primary.withValues(alpha: 0.05) : Colors.transparent,
                                border: Border(bottom: BorderSide(color: context.colors.divider.withValues(alpha: 0.5))),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? context.colors.primary : context.colors.surfaceWhite,
                                      shape: BoxShape.circle,
                                      border: isSelected ? null : Border.all(color: context.colors.divider),
                                    ),
                                    child: Icon(Icons.person_rounded, 
                                        color: isSelected ? Colors.white : context.colors.textGrey, size: 18),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(g.fullName, style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? context.colors.primary : context.colors.textDark)),
                                        const SizedBox(height: 4),
                                        Text('Available limit: ₹${g.availableGuaranteeLimit.toStringAsFixed(0)}', 
                                          style: TextStyle(
                                            color: g.availableGuaranteeLimit > 0 ? context.colors.textGrey : context.colors.error, 
                                            fontSize: 13,
                                            fontWeight: g.availableGuaranteeLimit > 0 ? FontWeight.normal : FontWeight.bold
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected) Icon(Icons.check_circle_rounded, color: context.colors.primary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
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
      color: context.colors.surfaceWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.colors.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.colors.textGrey,
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
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(title: const Text('My Loans')),
      body: loansAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: context.colors.primary)),
        error: (e, _) => ErrorRetry(
            message: apiError(e),
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

class _LoanDetailCard extends ConsumerStatefulWidget {
  final LoanApplication loan;
  const _LoanDetailCard({required this.loan});

  @override
  ConsumerState<_LoanDetailCard> createState() => _LoanDetailCardState();
}

class _LoanDetailCardState extends ConsumerState<_LoanDetailCard> {
  bool _updating = false;

  Future<void> _updateGuarantor(bool isGuarantor2) async {
    setState(() => _updating = true);
    try {
      final opts = await LoanApi.getLoanOptions();
      if (!mounted) return;
      
      final currentG1 = widget.loan.guarantorId;
      final currentG2 = widget.loan.guarantor2Id;

      await showModalBottomSheet(
        context: context,
        backgroundColor: context.colors.bgGrey,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          String searchQuery = '';
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              final filteredGuarantors = opts.availableGuarantors.where((g) {
                // Cannot select themselves or the other existing guarantor
                final otherG = isGuarantor2 ? currentG1 : currentG2;
                if (g.id == otherG) return false;
                return g.fullName.toLowerCase().contains(searchQuery.toLowerCase()) || 
                       g.phone.contains(searchQuery);
              }).toList();

              return SafeArea(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: context.colors.divider, borderRadius: BorderRadius.circular(2)),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(isGuarantor2 ? 'Select New Second Guarantor' : 'Select New Guarantor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textDark)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by name or phone...',
                            prefixIcon: Icon(Icons.search, color: context.colors.textGrey),
                            filled: true,
                            fillColor: context.colors.surfaceWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                      Divider(height: 1, color: context.colors.divider),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredGuarantors.length,
                          itemBuilder: (ctx, i) {
                            final g = filteredGuarantors[i];
                            return InkWell(
                              onTap: () async {
                                Navigator.pop(ctx);
                                try {
                                  setState(() => _updating = true);
                                  await LoanApi.updateGuarantors(
                                    widget.loan.id, 
                                    isGuarantor2 ? currentG1 : g.id, 
                                    isGuarantor2 ? g.id : currentG2
                                  );
                                  if (mounted) {
                                    ref.invalidate(myLoansProvider);
                                    AppToast.showSuccess(context, 'Guarantor updated successfully!');
                                  }
                                } catch (e) {
                                  if (mounted) AppToast.showError(context, apiError(e));
                                } finally {
                                  if (mounted) setState(() => _updating = false);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border(bottom: BorderSide(color: context.colors.divider.withValues(alpha: 0.5))),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: context.colors.surfaceWhite,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: context.colors.divider),
                                      ),
                                      child: Icon(Icons.person_rounded, color: context.colors.textGrey, size: 18),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(g.fullName, style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: context.colors.textDark)),
                                          const SizedBox(height: 4),
                                          Text('Available limit: ₹${g.availableGuaranteeLimit.toStringAsFixed(0)}', 
                                            style: TextStyle(
                                              color: g.availableGuaranteeLimit > 0 ? context.colors.textGrey : context.colors.error, 
                                              fontSize: 13,
                                              fontWeight: g.availableGuaranteeLimit > 0 ? FontWeight.normal : FontWeight.bold
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          );
        },
      );
    } catch (e) {
      if (mounted) AppToast.showError(context, apiError(e));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
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
          Row(children: [
            Expanded(
              child: Text(
                '₹${loan.amount.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textDark),
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
                value: '${DateFormat('d MMM yyyy').format(loan.disbursedDate!)}${loan.disbursementMode != null ? ' via ${loan.disbursementMode}' : ''}'),
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
          
          if (loan.guarantorName != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Guarantor', style: TextStyle(color: context.colors.textGrey, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(loan.guarantorName!, style: TextStyle(color: context.colors.textDark, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right),
                        if (loan.guarantorStatus != null)
                          Text(loan.guarantorStatus!, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: loan.guarantorStatus == 'Accepted' ? const Color(0xFF10B981) : loan.guarantorStatus == 'Rejected' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (loan.guarantorStatus == 'Rejected' && loan.status == 'Pending')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _updating ? null : () => _updateGuarantor(false),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Update Guarantor'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
          
          if (loan.guarantor2Name != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Guarantor 2', style: TextStyle(color: context.colors.textGrey, fontSize: 13)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(loan.guarantor2Name!, style: TextStyle(color: context.colors.textDark, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right),
                        if (loan.guarantor2Status != null)
                          Text(loan.guarantor2Status!, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: loan.guarantor2Status == 'Accepted' ? const Color(0xFF10B981) : loan.guarantor2Status == 'Rejected' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)
                          )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (loan.guarantor2Status == 'Rejected' && loan.status == 'Pending')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _updating ? null : () => _updateGuarantor(true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Update Guarantor 2'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],

          if (loan.rejectionReason != null)
            InfoRow(
                label: 'Reason',
                value: loan.rejectionReason!,
                last: true),

          // Repay Button
          if (loan.isDisbursed) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loan.hasPendingRepayment
                    ? null
                    : () => context.push('/loan/repay/${loan.id}'),
                icon: Icon(loan.hasPendingRepayment
                    ? Icons.hourglass_empty_rounded
                    : Icons.payment_rounded),
                label: Text(loan.hasPendingRepayment
                    ? 'Repayment Pending Review'
                    : 'Repay Loan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: context.colors.divider,
                  disabledForegroundColor: context.colors.textGrey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Guarantor Requests Screen
// ═════════════════════════════════════════════
class GuarantorRequestsScreen extends ConsumerStatefulWidget {
  const GuarantorRequestsScreen({super.key});

  @override
  ConsumerState<GuarantorRequestsScreen> createState() => _GuarantorRequestsScreenState();
}

class _GuarantorRequestsScreenState extends ConsumerState<GuarantorRequestsScreen> {
  List<LoanApplication> _requests = [];
  bool _loading = true;
  int? _actioningId;
  int? _currentUserId;
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uid = await StorageService.getUserId();
    if (uid != null) setState(() => _currentUserId = int.tryParse(uid));
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final reqs = await LoanApi.getGuarantorRequests(status: 'all');
      setState(() {
        _requests = reqs;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppToast.showError(context, apiError(e));
      }
    }
  }

  Future<void> _handleConsent(int loanId, bool accept) async {
    setState(() => _actioningId = loanId);
    try {
      await LoanApi.updateGuarantorConsent(loanId, accept);
      if (mounted) {
        ref.invalidate(userDashboardProvider);
        AppToast.showSuccess(context, 'Consent updated successfully');
        _loadRequests();
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, apiError(e));
    } finally {
      if (mounted) setState(() => _actioningId = null);
    }
  }

  Widget _buildList(List<LoanApplication> list) {
    if (list.isEmpty) return const Center(child: Text('No requests found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final req = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.handshake_outlined, color: context.colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req.applicantName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textDark)),
                        Text(req.applicantPhone, style: TextStyle(color: context.colors.textGrey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(_fmt.format(req.amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.primary)),
                ],
              ),
              const SizedBox(height: 16),
              Builder(builder: (context) {
                final isG1 = req.guarantorId == _currentUserId;
                final isG2 = req.guarantor2Id == _currentUserId;
                final myStatus = isG1
                    ? req.guarantorStatus
                    : isG2
                        ? req.guarantor2Status
                        : null;
                final myConsentPending = req.status == 'Pending' && (myStatus == null || myStatus == 'Pending');

                if (myConsentPending) {
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _actioningId == req.id ? null : () => _handleConsent(req.id, false),
                          child: _actioningId == req.id
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _actioningId == req.id ? null : () => _handleConsent(req.id, true),
                          child: _actioningId == req.id
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Accept'),
                        ),
                      ),
                    ],
                  );
                }

                String displayStatus = 'Loan ${req.status}';
                if (req.status == 'Pending') {
                  displayStatus = myStatus == 'Accepted' ? 'You accepted' : 'You rejected';
                }

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: myStatus == 'Accepted'
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: myStatus == 'Accepted'
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : const Color(0xFFEF4444).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        myStatus == 'Accepted' ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: myStatus == 'Accepted' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        displayStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: myStatus == 'Accepted' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.colors.bgGrey,
        appBar: AppBar(title: const Text('Guarantor Requests')),
        body: Center(child: CircularProgressIndicator(color: context.colors.primary)),
      );
    }

    final pendingList = _requests.where((req) {
      final isG1 = req.guarantorId == _currentUserId;
      final isG2 = req.guarantor2Id == _currentUserId;
      final myStatus = isG1 ? req.guarantorStatus : isG2 ? req.guarantor2Status : null;
      return req.status == 'Pending' && (myStatus == null || myStatus == 'Pending');
    }).toList();

    final historyList = _requests.where((req) {
      final isG1 = req.guarantorId == _currentUserId;
      final isG2 = req.guarantor2Id == _currentUserId;
      final myStatus = isG1 ? req.guarantorStatus : isG2 ? req.guarantor2Status : null;
      return !(req.status == 'Pending' && (myStatus == null || myStatus == 'Pending'));
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.bgGrey,
        appBar: AppBar(
          title: const Text('Guarantor Requests'),
          bottom: TabBar(
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textGrey,
            indicatorColor: context.colors.primary,
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(pendingList),
            _buildList(historyList),
          ],
        ),
      ),
    );
  }
}
