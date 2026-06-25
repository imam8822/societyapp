import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_services.dart';
import '../../models/loan_models.dart';
import '../../providers/data_providers.dart';
import '../../core/api/api_client.dart';
import '../../core/constants.dart';

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
        backgroundColor: AppTheme.bgGrey,
        appBar: AppBar(
          backgroundColor: AppTheme.bgGrey,
          title: const Text('Collect Cash',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textGrey,
            indicatorColor: AppTheme.primary,
            tabs: [
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
      sum += _selectedMember!.unpaidMonths[i].penaltyAmount;
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
              decoration: const BoxDecoration(
                color: AppTheme.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Member',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textDark)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      '${_members.length} member${_members.length == 1 ? '' : 's'} with pending dues',
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 12),
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
                        fillColor: AppTheme.bgGrey,
                        contentPadding:
                            const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppTheme.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text('No members found',
                                style: TextStyle(
                                    color: AppTheme.textGrey)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(
                                    height: 1,
                                    indent: 56,
                                    color: AppTheme.divider),
                            itemBuilder: (_, i) {
                              final m = filtered[i];
                              final isSelected =
                                  _selectedMember?.id == m.id;
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isSelected
                                      ? AppTheme.primary
                                      : AppTheme.primaryLight,
                                  child: Text(
                                    m.fullName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(m.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppTheme.textDark)),
                                subtitle: Row(
                                  children: [
                                    Text(m.phone,
                                        style: const TextStyle(
                                            color:
                                                AppTheme.textGrey,
                                            fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.error
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${_fmt.format(m.pendingAmount)} • ${m.unpaidMonthsCount}mo',
                                        style: const TextStyle(
                                            color: AppTheme.error,
                                            fontSize: 10,
                                            fontWeight:
                                                FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.primary,
                                        size: 20)
                                    : null,
                                onTap: () {
                                  _onMemberSelected(m);
                                  Navigator.pop(ctx);
                                },
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a member')),
      );
      return;
    }
    if (_selectedMonthIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one month')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final months = _selectedMonthIndices.map((i) {
        final m = _selectedMember!.unpaidMonths[i];
        return {
          'month': m.month,
          'year': m.year,
          'penaltyAmount': m.penaltyAmount,
        };
      }).toList();

      await ApiClient.instance.post('/contributions/cash/bulk',
          data: {
            'userId': _selectedMember!.id,
            'months': months,
            if (_remarksCtrl.text.trim().isNotEmpty)
              'remarks': _remarksCtrl.text.trim(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_selectedMonthIndices.length} month(s) recorded for ${_selectedMember!.fullName}'),
            backgroundColor: AppTheme.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loadingData
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary))
          : _members.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green.shade400, size: 64),
                      const SizedBox(height: 16),
                      const Text('All Caught Up!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      const Text(
                          'No members have pending dues.',
                          style: TextStyle(
                              color: AppTheme.textGrey)),
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
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primary,
                              Color(0xFF2ECC71)
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
                              color: AppTheme.bgGrey,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.divider),
                            ),
                            child: Row(
                              children: [
                                if (_selectedMember != null) ...[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        AppTheme.primaryLight,
                                    child: Text(
                                      _selectedMember!.fullName[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          color: AppTheme.primary,
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
                                            style: const TextStyle(
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
                                                style: const TextStyle(
                                                    color: AppTheme
                                                        .textGrey,
                                                    fontSize: 12)),
                                            const SizedBox(
                                                width: 8),
                                            Text(
                                              '${_fmt.format(_selectedMember!.pendingAmount)} due',
                                              style:
                                                  const TextStyle(
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
                                  const Icon(
                                      Icons
                                          .person_search_rounded,
                                      color: AppTheme.textGrey,
                                      size: 20),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                        'Tap to select member',
                                        style: TextStyle(
                                            color:
                                                AppTheme.textGrey,
                                            fontSize: 14)),
                                  ),
                                ],
                                const Icon(
                                    Icons
                                        .keyboard_arrow_down_rounded,
                                    color: AppTheme.textGrey),
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
                                          AppTheme.primary,
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
                                              color: selected ? AppTheme.primary : AppTheme.bgGrey,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: selected ? AppTheme.primary : AppTheme.divider,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  selected ? Icons.check_circle : Icons.circle_outlined,
                                                  size: 16,
                                                  color: selected ? Colors.white : AppTheme.textGrey,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    m.label,
                                                    style: TextStyle(
                                                      color: selected ? Colors.white : AppTheme.textGrey,
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
                                                      color: selected ? Colors.white70 : AppTheme.warning,
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
                              const Divider(
                                  color: AppTheme.divider,
                                  height: 16),
                              _summaryRow('Penalty', '',
                                  _fmt.format(_totalPenalty)),
                              const Divider(
                                  color: AppTheme.divider,
                                  height: 16),
                              _summaryRow(
                                'Total',
                                '',
                                _fmt.format(_grandTotal),
                                bold: true,
                                color: AppTheme.primary,
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
                                        CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color:
                                                Colors.white),
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
                                  AppTheme.primary,
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
                        color: color ?? AppTheme.textGrey,
                        fontSize: 13,
                        fontWeight: bold
                            ? FontWeight.w700
                            : FontWeight.w500)),
                if (detail.isNotEmpty)
                  Text(detail,
                      style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11)),
              ],
            ),
          ),
          Text(value,
              style: TextStyle(
                  color: color ?? AppTheme.textDark,
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
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textGrey,
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
                    .where((l) =>
                        l.applicantName.toLowerCase().contains(query) ||
                        l.applicantPhone.contains(query))
                    .toList();

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.7,
              decoration: const BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Active Loan',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textDark)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '${activeLoans.length} active loan${activeLoans.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (_) => setLocal(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name or phone...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey),
                        filled: true,
                        fillColor: AppTheme.bgGrey,
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
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: Text(
                              l.applicantName.isNotEmpty ? l.applicantName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: AppTheme.primary, fontWeight: FontWeight.bold),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid amount (Max: ${_fmt.format(_selectedLoan!.outstandingAmount)})')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repayment of ${_fmt.format(amount)} recorded for ${_selectedLoan!.applicantName}'),
            backgroundColor: AppTheme.primary,
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiError(e)),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLoansAsync = ref.watch(allLoansProvider);
    
    return allLoansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(child: Text(apiError(e))),
      data: (loans) {
        // Filter for active (Disbursed) loans with outstanding amount > 0
        final activeLoans = loans.where((l) => l.status == 'Disbursed' && l.outstandingAmount > 0).toList();
        
        if (activeLoans.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: AppTheme.accent),
                SizedBox(height: 16),
                Text('No active loans pending repayment.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
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
                color: AppTheme.primary.withOpacity(0.05),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Collect cash repayments for active loans.',
                        style: TextStyle(color: AppTheme.primary.withOpacity(0.8), fontSize: 13),
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
                    const Text('Select Member',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _pickLoan(activeLoans),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                color: _selectedLoan != null ? AppTheme.primary : AppTheme.textGrey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedLoan?.applicantName ?? 'Tap to select member...',
                                style: TextStyle(
                                  color: _selectedLoan != null ? AppTheme.textDark : AppTheme.textGrey,
                                  fontWeight: _selectedLoan != null ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: AppTheme.textGrey),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_selectedLoan != null) ...[
                      const SizedBox(height: 24),
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
                            const Text('Loan Details',
                                style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textGrey, fontSize: 12)),
                            const SizedBox(height: 12),
                            _summaryRow('Loan Amount', '', _fmt.format(_selectedLoan!.amount)),
                            const SizedBox(height: 8),
                            _summaryRow('Total Repaid', '', _fmt.format(_selectedLoan!.totalRepaid), color: AppTheme.accent),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            _summaryRow('Outstanding Balance', '', _fmt.format(_selectedLoan!.outstandingAmount), bold: true, color: AppTheme.error),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text('Repayment Amount',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          prefixText: '₹ ',
                          filled: true,
                          fillColor: AppTheme.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primary),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      const Text('Remarks (Optional)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _remarksCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'E.g., Cash collected at society office',
                          filled: true,
                          fillColor: AppTheme.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.divider),
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
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_rounded, size: 20),
                          label: Text(
                            _loading ? 'Recording...' : 'Record Repayment',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
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
                        color: color ?? AppTheme.textGrey,
                        fontSize: 13,
                        fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
                if (detail.isNotEmpty)
                  Text(detail,
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 11)),
              ],
            ),
          ),
          Text(value,
              style: TextStyle(
                  color: color ?? AppTheme.textDark,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 16 : 14)),
        ],
      );
}
