import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_services.dart';
import '../../models/transaction_models.dart';
import '../../widgets/shared_widgets.dart';
import '../../core/constants.dart';
import '../../widgets/export_dialog.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loading = true;
  TransactionStatsDto? _stats;
  List<TransactionDto>? _transactions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await TransactionApi.getStats();
      final trans = await TransactionApi.getTransactions(limit: 50);

      if (mounted) {
        setState(() {
          _stats = stats;
          _transactions = trans;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const ExportStatementDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textDark),
        title: Text(
          'Transactions & Stats',
          style: TextStyle(
            color: context.colors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export Statement',
            onPressed: _showExportDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(child: const AppSpinner())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: context.colors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: context.colors.textGrey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: context.colors.primary,
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Monthly Additions',
                                amount: _stats!.totalIncomeThisMonth,
                                isPositive: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Monthly Outflows',
                                amount: _stats!.totalOutflowThisMonth,
                                isPositive: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Chart
                        Text(
                          '6-Month Trend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 250,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: _buildChart(),
                        ),
                        const SizedBox(height: 32),

                        // Ledger
                        Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_transactions == null || _transactions!.isEmpty)
                          const EmptyState(
                            icon: Icons.receipt_long,
                            title: 'No transactions yet',
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _transactions!.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final t = _transactions![index];
                              return _TransactionTile(transaction: t, formatAmount: _formatAmount);
                            },
                          )
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildChart() {
    final stats = _stats!.monthlyStats;
    if (stats.isEmpty) return const Center(child: Text('No data'));

    double maxVal = 0;
    for (var s in stats) {
      if (s.income > maxVal) maxVal = s.income;
      if (s.outflow > maxVal) maxVal = s.outflow;
    }
    // Add 20% padding to top
    maxVal = maxVal * 1.2;
    if (maxVal == 0) maxVal = 10000;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal,
        barTouchData: const BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= stats.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    stats[value.toInt()].month,
                    style: TextStyle(
                      color: context.colors.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: stats.asMap().entries.map((e) {
          final i = e.key;
          final s = e.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: s.income,
                color: const Color(0xFF16A34A),
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: s.outflow,
                color: context.colors.error,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final bool isPositive;

  const _StatCard({required this.title, required this.amount, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                      : context.colors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPositive ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isPositive ? const Color(0xFF16A34A) : context.colors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            NumberFormat.currency(
              locale: 'en_IN',
              symbol: '₹',
              decimalDigits: 0,
            ).format(amount),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.colors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionDto transaction;
  final String Function(double) formatAmount;

  const _TransactionTile({required this.transaction, required this.formatAmount});

  @override
  Widget build(BuildContext context) {
    final bool isAddition = transaction.amount >= 0;
    final color = isAddition ? const Color(0xFF16A34A) : context.colors.error;
    
    return Container(
      color: context.colors.surfaceWhite,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAddition ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatType(transaction.type),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textDark,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                if (transaction.userName != null)
                  Text(
                    transaction.userName!,
                    style: TextStyle(
                      color: context.colors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                if (transaction.remarks != null)
                  Text(
                    transaction.remarks!,
                    style: TextStyle(
                      color: context.colors.textGrey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, y • h:mm a').format(transaction.createdAt),
                  style: TextStyle(
                    color: context.colors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isAddition ? '+' : '-'}${formatAmount(transaction.amount.abs())}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bal: ${formatAmount(transaction.balanceAfter)}',
                style: TextStyle(
                  color: context.colors.textGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'InitialInvestment': return 'Pre-existing Investment';
      case 'Contribution': return 'Contribution';
      case 'LoanDisbursement': return 'Loan Disbursement';
      case 'LoanRepayment': return 'Loan Repayment';
      case 'Penalty': return 'Penalty';
      default: return type;
    }
  }
}
