import 'package:society_app/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_services.dart';
import '../../core/constants.dart';
import '../../core/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../core/api/api_client.dart';
import '../../models/loan_models.dart';

/// A single unpaid month from the API.
class _UnpaidMonth {
  final int month;
  final int year;
  final double contributionAmount;
  final double penaltyAmount;

  _UnpaidMonth({
    required this.month,
    required this.year,
    required this.contributionAmount,
    required this.penaltyAmount,
  });

  factory _UnpaidMonth.fromJson(Map<String, dynamic> j) => _UnpaidMonth(
        month: j['month'],
        year: j['year'],
        contributionAmount:
            (j['contributionAmount'] as num?)?.toDouble() ?? 0,
        penaltyAmount: (j['penaltyAmount'] as num?)?.toDouble() ?? 0,
      );

  String get label {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${names[month]} $year';
  }
}

/// Lightweight member with pending info.
class _PendingMember {
  final int id;
  final String fullName;
  final String phone;
  final double pendingAmount;
  final int unpaidMonthsCount;
  final List<_UnpaidMonth> unpaidMonths;

  _PendingMember({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.pendingAmount,
    required this.unpaidMonthsCount,
    required this.unpaidMonths,
  });

  factory _PendingMember.fromJson(Map<String, dynamic> j) {
    final list = j['unpaidMonths'] as List?;
    return _PendingMember(
      id: j['id'],
      fullName: j['fullName'],
      phone: j['phone'],
      pendingAmount: (j['pendingAmount'] as num?)?.toDouble() ?? 0,
      unpaidMonthsCount: j['unpaidMonthsCount'] ?? 0,
      unpaidMonths: list != null
          ? list.map((e) => _UnpaidMonth.fromJson(e as Map<String, dynamic>)).toList()
          : <_UnpaidMonth>[],
    );
  }
}

class CollectCashScreen extends StatelessWidget {
  const CollectCashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.colors.bgGrey,
        appBar: AppBar(
          backgroundColor: context.colors.bgGrey,
          title: const Text('Collect Cash',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          bottom: TabBar(
            labelColor: context.colors.primary,
            unselectedLabelColor: context.colors.textGrey,
            indicatorColor: context.colors.primary,
            tabs: const [
              Tab(text: 'Contributions'),
              Tab(text: 'Loan Repayments'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ContributionsTab(),
            _LoanRepaymentsTab(),
          ],
        ),
      ),
    );
  }
}

class _ContributionsTab extends StatefulWidget {
  const _ContributionsTab();
  @override
  State<_ContributionsTab> createState() => _ContributionsTabState();
}

class _ContributionsTabState extends State<_ContributionsTab> {
  final _remarksCtrl = TextEditingController();

  _PendingMember? _selectedMember;
  Set<int> _selectedMonthIndices = {}; // indices into member's unpaidMonths
  bool _loading = false;
  bool _loadingData = true;
  List<_PendingMember> _members = [];
  double _monthlyAmount = 0;
  DateTime _paidDate = DateTime.now();

  final _fmt = NumberFormat.currency(
      locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await ApiClient.instance
          .get('/contributions/cash/pending-members');
      final data = res.data as Map<String, dynamic>;

      _monthlyAmount =
          (data['monthlyContributionAmount'] as num?)?.toDouble() ?? 0;

      final list = (data['members'] as List)
          .map((e) => _PendingMember.fromJson(e))
          .toList();

      if (mounted) {
        setState(() {
          _members = list;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  /// Select member & auto-select all unpaid months.
  void _onMemberSelected(_PendingMember m) {
    setState(() {
      _selectedMember = m;
      _selectedMonthIndices =
          Set<int>.from(List.generate(m.unpaidMonths.length, (i) => i));
    });
  }

  /// Calculate totals from selected months.
  double get _totalContribution {
    if (_selectedMember == null) return 0;
    double sum = 0;
    for (final i in _selectedMonthIndices) {
      sum += _selectedMember!.unpaidMonths[i].contributionAmount;
    }
    return sum;
  }

  double get _totalPenalty {
    if (_selectedMember == null) return 0;
    double sum = 0;
    for (final i in _selectedMonthIndices) {
      final m = _selectedMember!.unpaidMonths[i];
      final monthDate = DateTime(m.year, m.month, 1);
      final pMonthStart = DateTime(_paidDate.year, _paidDate.month, 1);
      final pastDue = monthDate.isBefore(pMonthStart) || 
                      (monthDate.year == _paidDate.year && monthDate.month == _paidDate.month && _paidDate.day > 15);
      final actualPenalty = pastDue ? m.penaltyAmount : 0.0;
      sum += actualPenalty;
    }
    return sum;
  }

  double get _grandTotal => _totalContribution + _totalPenalty;

  // ── Member picker bottom sheet ──────────────────────
  void _pickMember() {
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final query = searchCtrl.text.toLowerCase().trim();
            final filtered = query.isEmpty
                ? _members
                : _members
                    .where((m) =>
                        m.fullName.toLowerCase().contains(query) ||
                        m.phone.contains(query))
                    .toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.7,
              decoration: BoxDecoration(
                color: context.colors.surfaceWhite,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Select Member',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: context.colors.textDark)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      '${_members.length} member${_members.length == 1 ? '' : 's'} with pending dues',
                      style: TextStyle(
                          color: context.colors.textGrey, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setLocal(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name or phone...',
                        prefixIcon:
                            const Icon(Icons.search, size: 20),
                        suffixIcon: searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setLocal(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: context.colors.bgGrey,
                        contentPadding:
                            const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: context.colors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: context.colors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: context.colors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text('No members found',
                                style: TextStyle(
                                    color: context.colors.textGrey)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                Divider(
                                    height: 1,
                                    indent: 56,
                                    color: context.colors.divider),
                            itemBuilder: (_, i) {
                              final m = filtered[i];
                              final isSelected =
                                  _selectedMember?.id == m.id;
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected
                                      ? context.colors.primary
                                      : context.colors.primaryLight,
                                  child: Text(
                                    m.fullName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : context.colors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(m.fullName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: context.colors.textDark)),
                                subtitle: Row(
                                  children: [
                                    Text(m.phone,
                                        style: TextStyle(
                                            color:
                                                context.colors.textGrey,
                                            fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1),
                                      decoration: BoxDecoration(
                                        color: context.colors.error
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${_fmt.format(m.pendingAmount)} • ${m.unpaidMonthsCount}mo',
                                        style: TextStyle(
                                            color: context.colors.error,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: context.colors.primary,
                                        size: 20)
                                    : null,
                                onTap: () {
                                  _onMemberSelected(m);
                                  Navigator.pop(ctx);
                                },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Submit ──────────────────────────────────────────
  Future<void> _submit() async {
    if (_selectedMember == null) {
      AppUtils.showError(context, 'Please select a member');
      return;
    }
    if (_selectedMonthIndices.isEmpty) {
      AppUtils.showError(context, 'Please select at least one month');
      return;
    }

    setState(() => _loading = true);
    try {
      final months = _selectedMonthIndices.map((i) {
        final m = _selectedMember!.unpaidMonths[i];
        final monthDate = DateTime(m.year, m.month, 1);
        final pMonthStart = DateTime(_paidDate.year, _paidDate.month, 1);
        final pastDue = monthDate.isBefore(pMonthStart) || 
                        (monthDate.year == _paidDate.year && monthDate.month == _paidDate.month && _paidDate.day > 15);
        final actualPenalty = pastDue ? m.penaltyAmount : 0.0;

        return {
          'month': m.month,
          'year': m.year,
          'penaltyAmount': actualPenalty,
        };
      }).toList();

      await ApiClient.instance.post('/contributions/cash/bulk',
          data: {
            'userId': _selectedMember!.id,
            'months': months,
            if (_remarksCtrl.text.trim().isNotEmpty)
              'remarks': _remarksCtrl.text.trim(),
            'paidDate': _paidDate.toIso8601String(),
          });

      if (mounted) {
        AppUtils.showSuccess(context, 'Contribution of ${_fmt.format(_grandTotal)} recorded for ${_selectedMember!.fullName}');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showError(context, apiError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loadingData
          ? Center(
              child: const AppSpinner())
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green.shade400, size: 64),
                      const SizedBox(height: 16),
                      Text('All Caught Up!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textDark)),
                      const SizedBox(height: 8),
                      Text(
                          'No members have pending dues.',
                          style: TextStyle(
                              color: context.colors.textGrey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.colors.primary,
                              const Color(0xFF2ECC71)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.payments_rounded,
                                color: Colors.white, size: 40),
                            const SizedBox(height: 8),
                            const Text('Cash Collection',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              '${_members.length} member${_members.length == 1 ? '' : 's'} with pending dues',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Select Member ──────────────────
                      _sectionCard(
                        title: 'Member',
                        child: GestureDetector(
                          onTap: _pickMember,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: context.colors.bgGrey,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                  color: context.colors.divider),
                            ),
                            child: Row(
                              children: [
                                if (_selectedMember != null) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        context.colors.primaryLight,
                                    child: Text(
                                      _selectedMember!.fullName[0]
                                          .toUpperCase(),
                                      style: TextStyle(
                                          color: context.colors.primary,
                                          fontWeight:
                                              FontWeight.w700,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            _selectedMember!
                                                .fullName,
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 14,
                                                color: AppTheme
                                                    .textDark)),
                                        Row(
                                          children: [
                                            Text(
                                                _selectedMember!
                                                    .phone,
                                                style: TextStyle(
                                                    color: AppTheme
                                                        .textGrey,
                                                    fontSize: 12)),
                                            const SizedBox(
                                                width: 8),
                                            Text(
                                              '${_fmt.format(_selectedMember!.pendingAmount)} due',
                                              style:
                                                  TextStyle(
                                                      color: AppTheme
                                                          .error,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight
                                                              .w600),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                      Icons
                                          .person_search_rounded,
                                      color: context.colors.textGrey,
                                      size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                        'Tap to select member',
                                        style: TextStyle(
                                            color:
                                                context.colors.textGrey,
                                            fontSize: 14)),
                                  ),
                                ],
                                Icon(
                                    Icons
                                        .keyboard_arrow_down_rounded,
                                    color: context.colors.textGrey),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Unpaid Months ──────────────────
                      if (_selectedMember != null) ...[
                        _sectionCard(
                          title:
                              'Unpaid Months (${_selectedMonthIndices.length}/${_selectedMember!.unpaidMonths.length} selected)',
                          child: Column(
                            children: [
                              // Select/Deselect all
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        if (_selectedMonthIndices
                                                .length ==
                                            _selectedMember!
                                                .unpaidMonths
                                                .length) {
                                          _selectedMonthIndices
                                              .clear();
                                        } else {
                                          _selectedMonthIndices =
                                              Set<int>.from(
                                                  List.generate(
                                                      _selectedMember!
                                                          .unpaidMonths
                                                          .length,
                                                      (i) => i));
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      _selectedMonthIndices
                                                  .length ==
                                              _selectedMember!
                                                  .unpaidMonths
                                                  .length
                                          ? Icons
                                              .deselect
                                          : Icons
                                              .select_all,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _selectedMonthIndices
                                                  .length ==
                                              _selectedMember!
                                                  .unpaidMonths
                                                  .length
                                          ? 'Deselect All'
                                          : 'Select All',
                                      style: const TextStyle(
                                          fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          context.colors.primary,
                                      padding:
                                          EdgeInsets.zero,
                                      minimumSize:
                                          const Size(0, 30),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final total = _selectedMember!.unpaidMonths.length;
                                  double chipWidth;
                                  if (total == 1) {
                                    chipWidth = constraints.maxWidth;
                                  } else if (total == 2 || total == 4) {
                                    // Two per row looks better for 2 or 4
                                    chipWidth = (constraints.maxWidth - 8) / 2.01;
                                  } else {
                                    // Three per row
                                    chipWidth = (constraints.maxWidth - 16) / 3.02;
                                  }

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(
                                      total,
                                      (i) {
                                        final m = _selectedMember!.unpaidMonths[i];
                                        final selected = _selectedMonthIndices.contains(i);
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              if (selected) {
                                                _selectedMonthIndices.remove(i);
                                              } else {
                                                _selectedMonthIndices.add(i);
                                              }
                                            });
                                          },
                                          child: Container(
                                            width: chipWidth,
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: selected ? context.colors.primary : context.colors.bgGrey,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: selected ? context.colors.primary : context.colors.divider,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  selected ? Icons.check_circle : Icons.circle_outlined,
                                                  size: 16,
                                                  color: selected ? Colors.white : context.colors.textGrey,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    m.label,
                                                    style: TextStyle(
                                                      color: selected ? Colors.white : context.colors.textGrey,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (m.penaltyAmount > 0) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '+${_fmt.format(m.penaltyAmount)}',
                                                    style: TextStyle(
                                                      color: selected ? Colors.white70 : context.colors.warning,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Payment Date ──────────────────────
                        _sectionCard(
                          title: 'Payment Date',
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _paidDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _paidDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.colors.divider),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(DateFormat('dd MMM yyyy').format(_paidDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                        if (_paidDate.day <= 15)
                                          const Text('Date is on/before 15th (Penalty waived)', style: TextStyle(color: Colors.green, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Summary ──────────────────────
                        _sectionCard(
                          title: 'Payment Summary',
                          child: Column(
                            children: [
                              _summaryRow(
                                  'Contribution',
                                  '${_selectedMonthIndices.length} × ${_fmt.format(_monthlyAmount)}',
                                  _fmt.format(
                                      _totalContribution)),
                              Divider(
                                  color: context.colors.divider,
                                  height: 16),
                              _summaryRow('Penalty', '',
                                  _fmt.format(_totalPenalty)),
                              Divider(
                                  color: context.colors.divider,
                                  height: 16),
                              _summaryRow(
                                'Total',
                                '',
                                _fmt.format(_grandTotal),
                                bold: true,
                                color: context.colors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Remarks ──────────────────────
                        _sectionCard(
                          title: 'Remarks',
                          child: TextFormField(
                            controller: _remarksCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Remarks (optional)',
                              prefixIcon:
                                  Icon(Icons.notes_rounded),
                              hintText:
                                  'e.g. Cash received at meeting',
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Submit ───────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: (_loading ||
                                    _selectedMonthIndices
                                        .isEmpty)
                                ? null
                                : _submit,
                            icon: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child:
                                        const AppSpinner(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons
                                        .check_circle_rounded,
                                    size: 20),
                            label: Text(
                              _loading
                                  ? 'Recording...'
                                  : 'Record ${_fmt.format(_grandTotal)}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  context.colors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                );
  }

  Widget _summaryRow(String label, String detail, String value,
          {bool bold = false, Color? color}) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color ?? context.colors.textGrey,
                        fontSize: 13,
                        fontWeight: bold
                            ? FontWeight.w700
                            : FontWeight.w500)),
                if (detail.isNotEmpty)
                  Text(detail,
                      style: TextStyle(
                          color: context.colors.textGrey,
                          fontSize: 11)),
              ],
            ),
          ),
          Text(value,
              style: TextStyle(
                  color: color ?? context.colors.textDark,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 16 : 14)),
        ],
      );

  Widget _sectionCard(
          {required String title, required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textGrey,
                    fontSize: 12)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}
class _LoanRepaymentsTab extends ConsumerStatefulWidget {
  const _LoanRepaymentsTab();

  @override
  ConsumerState<_LoanRepaymentsTab> createState() => _LoanRepaymentsTabState();
}

class _LoanRepaymentsTabState extends ConsumerState<_LoanRepaymentsTab> {
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  
  LoanApplication? _selectedLoan;
  bool _loading = false;
  
  final _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _pickLoan(List<LoanApplication> activeLoans) {
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final query = searchCtrl.text.toLowerCase().trim();
            final filtered = query.isEmpty
                ? activeLoans
                : activeLoans
                    .where((LoanApplication l) =>
                        l.applicantName.toLowerCase().contains(query) ||
                        l.applicantPhone.contains(query))
                    .toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.7,
              decoration: BoxDecoration(
                color: context.colors.surfaceWhite,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Select Active Loan',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: context.colors.textDark)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '${activeLoans.length} active loan${activeLoans.length == 1 ? '' : 's'}',
                      style: TextStyle(color: context.colors.textGrey, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setLocal(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name or phone...',
                        prefixIcon: Icon(Icons.search, color: context.colors.textGrey),
                        filled: true,
                        fillColor: context.colors.bgGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final l = filtered[i];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                            child: Text(
                              l.applicantName.isNotEmpty ? l.applicantName[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: context.colors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(l.applicantName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${l.applicantPhone} • Due: ${_fmt.format(l.outstandingAmount)}',
                              style: const TextStyle(fontSize: 12)),
                          onTap: () {
                            setState(() {
                              _selectedLoan = l;
                              // Pre-fill amount with outstanding or fixed monthly installment
                              double prefillAmount = l.outstandingAmount;
                              _amountCtrl.text = prefillAmount.toStringAsFixed(0);
                            });
                            Navigator.pop(ctx);
                          },
                        ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_selectedLoan == null) return;
    
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0 || amount > _selectedLoan!.outstandingAmount) {
      AppUtils.showError(context, 'Enter a valid amount (Max: ${_fmt.format(_selectedLoan!.outstandingAmount)})');
      return;
    }

    setState(() => _loading = true);
    try {
      await LoanApi.recordRepayment(
        _selectedLoan!.id,
        amount,
        _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : null,
      );
      
      if (mounted) {
        AppUtils.showSuccess(context, 'Repayment of ${_fmt.format(amount)} recorded for ${_selectedLoan!.applicantName}');
        ref.invalidate(allLoansProvider);
        ref.invalidate(adminDashboardProvider);
        setState(() {
          _selectedLoan = null;
          _amountCtrl.clear();
          _remarksCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showError(context, apiError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLoansAsync = ref.watch(allLoansProvider);
    
    return allLoansAsync.when(
      loading: () => Center(child: const AppSpinner()),
      error: (e, _) => Center(child: Text(apiError(e))),
      data: (loans) {
        // Filter for active (Disbursed) loans with outstanding amount > 0
        final activeLoans = loans.where((l) => l.status == 'Disbursed' && l.outstandingAmount > 0).toList();
        
        if (activeLoans.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: context.colors.accent),
                const SizedBox(height: 16),
                Text('No active loans pending repayment.',
                    style: TextStyle(color: context.colors.textGrey, fontSize: 16)),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: context.colors.primary.withValues(alpha: 0.05),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: context.colors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Collect cash repayments for active loans.',
                        style: TextStyle(color: context.colors.primary.withValues(alpha: 0.8), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select Member',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textDark)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickLoan(activeLoans),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                color: _selectedLoan != null ? context.colors.primary : context.colors.textGrey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedLoan?.applicantName ?? 'Tap to select member...',
                                style: TextStyle(
                                  color: _selectedLoan != null ? context.colors.textDark : context.colors.textGrey,
                                  fontWeight: _selectedLoan != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down, color: context.colors.textGrey),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_selectedLoan != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Loan Details',
                                style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.textGrey, fontSize: 12)),
                            const SizedBox(height: 12),
                            _summaryRow('Loan Amount', '', _fmt.format(_selectedLoan!.amount)),
                            const SizedBox(height: 8),
                            _summaryRow('Total Repaid', '', _fmt.format(_selectedLoan!.totalRepaid), color: context.colors.accent),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            _summaryRow('Outstanding Balance', '', _fmt.format(_selectedLoan!.outstandingAmount), bold: true, color: context.colors.error),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Text('Repayment Amount',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textDark)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          prefixText: '₹ ',
                          filled: true,
                          fillColor: context.colors.surfaceWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.colors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.colors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.colors.primary),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Text('Remarks (Optional)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textDark)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _remarksCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'E.g., Cash collected at society office',
                          filled: true,
                          fillColor: context.colors.surfaceWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.colors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.colors.divider),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(height: 20, width: 20, child: const AppSpinner(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle_rounded, size: 20),
                          label: Text(
                            _loading ? 'Recording...' : 'Record Repayment',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String detail, String value,
          {bool bold = false, Color? color}) =>
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color ?? context.colors.textGrey,
                        fontSize: 13,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
                if (detail.isNotEmpty)
                  Text(detail,
                      style: TextStyle(color: context.colors.textGrey, fontSize: 11)),
              ],
            ),
          ),
          Text(value,
              style: TextStyle(
                  color: color ?? context.colors.textDark,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 16 : 14)),
        ],
      );
}
