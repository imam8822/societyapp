import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api/api_services.dart';
import '../../core/app_utils.dart';
import '../../core/constants.dart';
import '../../models/contribution_models.dart';
import '../../widgets/shared_widgets.dart';

class ContributionsReportScreen extends StatefulWidget {
  const ContributionsReportScreen({super.key});

  @override
  State<ContributionsReportScreen> createState() => _ContributionsReportScreenState();
}

class _ContributionsReportScreenState extends State<ContributionsReportScreen> {
  MonthlyReport? _report;
  bool _loading = false;
  
  late int _selectedMonth;
  late int _selectedYear;
  String _searchQuery = '';
  int _page = 1;
  final int _limit = 50;

  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      final r = await ContributionApi.getMonthlyReport(
        _selectedMonth,
        _selectedYear,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        page: _page,
        limit: _limit,
      );
      setState(() => _report = r);
    } catch (e) {
      AppUtils.showError(context, 'Failed to load report: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyContribution(Contribution c, bool approve) async {
    setState(() => _loading = true);
    try {
      await ContributionApi.verifyContribution(c.id, approve, null);
      AppUtils.showSuccess(context, approve ? 'Contribution approved' : 'Contribution rejected');
      _loadReport();
    } catch (e) {
      AppUtils.showError(context, 'Verification failed: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _bulkVerify() async {
    if (_report == null) return;
    final unverifiedIds = _report!.contributions
        .where((c) => !c.isVerified)
        .map((c) => c.id)
        .toList();

    if (unverifiedIds.isEmpty) {
      AppUtils.showError(context, 'No unverified contributions to verify');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Verify'),
        content: Text('Are you sure you want to verify all ${unverifiedIds.length} pending contributions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Verify All')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await ContributionApi.bulkVerifyContributions(unverifiedIds, true, null);
      AppUtils.showSuccess(context, 'Bulk verification successful');
      _loadReport();
    } catch (e) {
      AppUtils.showError(context, 'Bulk verification failed: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _exportToCsv() async {
    if (_report == null || _report!.contributions.isEmpty) {
      AppUtils.showError(context, 'No data to export');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Name,Month/Year,Amount,Mode,Date,Status');
    
    for (final c in _report!.contributions) {
      final statusStr = c.isVerified ? 'Verified' : 'Pending';
      final paidDateStr = DateFormat('d MMM yyyy').format(c.paidDate);
      final escapedName = '"${c.userName.replaceAll('"', '""')}"';
      buffer.writeln('$escapedName,${c.monthName},${c.amount},${c.mode},$paidDateStr,$statusStr');
    }

    if (_report!.unpaidMembers.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Unpaid Members');
      buffer.writeln('Name,Phone');
      for (final m in _report!.unpaidMembers) {
        final escapedName = '"${m.fullName.replaceAll('"', '""')}"';
        buffer.writeln('$escapedName,${m.phone}');
      }
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/contributions_${_selectedMonth}_${_selectedYear}.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Contributions Report - ${_selectedMonth}/${_selectedYear}',
      );
    } catch (e) {
      AppUtils.showError(context, 'Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _report?.contributions.where((c) => !c.isVerified).length ?? 0;

    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(
        title: const Text('Contributions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters & Selectors
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: context.colors.surfaceWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.colors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        dropdownColor: context.colors.surfaceWhite,
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: TextStyle(color: context.colors.textDark),
                        items: List.generate(12, (index) {
                          final m = index + 1;
                          final label = DateFormat('MMMM').format(DateTime(2026, m));
                          return DropdownMenuItem(value: m, child: Text(label));
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedMonth = val;
                              _page = 1;
                            });
                            _loadReport();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        dropdownColor: context.colors.surfaceWhite,
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: TextStyle(color: context.colors.textDark),
                        items: List.generate(5, (index) {
                          final y = DateTime.now().year - 2 + index;
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedYear = val;
                              _page = 1;
                            });
                            _loadReport();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Statistics Header Cards
          if (_report != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Collected',
                      _currencyFmt.format(_report!.totalCollected),
                      Colors.green,
                      context,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Paid',
                      '${_report!.paidCount} / ${_report!.totalMembers}',
                      Colors.blue,
                      context,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Unpaid',
                      '${_report!.unpaidCount}',
                      Colors.orange,
                      context,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Search Box & Bulk Verify
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _page = 1;
                      });
                      _loadReport();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: context.colors.surfaceWhite,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.colors.divider),
                      ),
                    ),
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _bulkVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Bulk Verify'),
                  ),
                ]
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Report list
          Expanded(
            child: _loading && _report == null
                ? Center(child: CircularProgressIndicator(color: context.colors.primary))
                : RefreshIndicator(
                    onRefresh: _loadReport,
                    color: context.colors.primary,
                    child: _report == null || _report!.contributions.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'No Contributions Found',
                                subtitle: 'No records match for selected month',
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _report!.contributions.length,
                            itemBuilder: (context, index) {
                              final c = _report!.contributions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: context.colors.surfaceWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: context.colors.divider),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    c.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textDark,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Paid via ${c.mode} on ${DateFormat('d MMM yyyy').format(c.paidDate)}',
                                        style: TextStyle(color: context.colors.textGrey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _currencyFmt.format(c.amount),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: context.colors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (c.isVerified)
                                        const Text(
                                          'Verified',
                                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                        )
                                      else
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _verifyContribution(c, true),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Verify',
                                                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, BuildContext context) {
    return Card(
      color: context.colors.surfaceWhite,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.colors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: context.colors.textGrey, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
