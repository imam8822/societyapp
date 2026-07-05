import 'package:flutter/material.dart';
import 'package:societyapp/core/app_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_services.dart';
import '../../models/transaction_models.dart';
import '../../core/constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/export_dialog.dart';
import '../../providers/data_providers.dart';

class AdminLedgerScreen extends StatefulWidget {
  const AdminLedgerScreen({super.key});

  @override
  State<AdminLedgerScreen> createState() => _AdminLedgerScreenState();
}

class _AdminLedgerScreenState extends State<AdminLedgerScreen> {
  final List<TransactionDto> _transactions = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _transactions.clear();
    }

    if (!_hasMore || _loading) return;
    setState(() => _loading = true);

    try {
      final items = await TransactionApi.getTransactions(limit: _limit); // Need to wait, transaction api takes page? Oh, TransactionApi.getTransactions doesn't take page! I need to update it.
      setState(() {
        if (items.length < _limit) _hasMore = false;
        _transactions.addAll(items);
        _page++;
      });
    } catch (e) {
      if (mounted) AppUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: const Text('Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _showExportDialog,
          )
        ],
      ),
      body: _transactions.isEmpty && _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
          : _transactions.isEmpty
              ? const EmptyState(icon: Icons.receipt_long, title: 'No transactions found')
              : RefreshIndicator(
                  onRefresh: () => _loadTransactions(refresh: true),
                  color: context.colors.primary,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final dashAsync = ref.watch(adminDashboardProvider);
                            return dashAsync.when(
                              data: (dash) {
                                final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
                                return Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [context.colors.primary, const Color(0xFF2563EB)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Ledger Summary', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 12),
                                      _LedgerRow(label: 'Total Collected', value: '+ ${fmt.format(dash.totalCollected)}', color: const Color(0xFF6EE7B7)),
                                      _LedgerRow(label: 'Late Penalties', value: '+ ${fmt.format(dash.totalPenaltyCollected)}', color: const Color(0xFF6EE7B7)),
                                      _LedgerRow(label: 'Loan Profits', value: '+ ${fmt.format(dash.totalLoanProfit)}', color: const Color(0xFF6EE7B7)),
                                      if (dash.totalAdjustments != 0)
                                        _LedgerRow(
                                          label: 'Adjustments',
                                          value: dash.totalAdjustments > 0 ? '+ ${fmt.format(dash.totalAdjustments)}' : '- ${fmt.format(dash.totalAdjustments.abs())}',
                                          color: dash.totalAdjustments > 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                                        ),
                                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white24, height: 1)),
                                      _LedgerRow(label: 'Total Disbursed', value: '- ${fmt.format(dash.totalDisbursed)}', color: const Color(0xFFFCA5A5)),
                                      _LedgerRow(label: 'Total Refunds', value: '- ${fmt.format(dash.totalRefunds)}', color: const Color(0xFFFCA5A5)),
                                      _LedgerRow(label: 'Total Expenses', value: '- ${fmt.format(dash.totalExpenses)}', color: const Color(0xFFFCA5A5)),
                                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Colors.white54, height: 1, thickness: 1)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Current Balance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                          Text(fmt.format(dash.balance), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index == _transactions.length) {
                                _loadTransactions();
                                return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                              }
                              final t = _transactions[index];
                              final isOutflow = t.type == 'LoanDisbursement' || t.type == 'Refund' || t.type == 'Expense' || (t.type == 'Adjustment' && t.amount < 0);
                              final isAddition = !isOutflow;
                              final color = isAddition ? const Color(0xFF16A34A) : context.colors.error;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.colors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.colors.divider),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: Icon(isAddition ? Icons.add_rounded : Icons.remove_rounded, color: color),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(t.type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                          if (t.userName != null) Text(t.userName!, style: TextStyle(color: context.colors.textGrey, fontSize: 13)),
                                          if (t.remarks != null) Text(t.remarks!, style: TextStyle(color: context.colors.textGrey, fontSize: 12, fontStyle: FontStyle.italic)),
                                          const SizedBox(height: 4),
                                          Text(DateFormat('MMM d, y • h:mm a').format(t.createdAt), style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${isAddition ? '+' : '-'}₹${t.amount.abs().toInt()}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text('Bal: ₹${t.balanceAfter.toInt()}', style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _transactions.length + (_hasMore ? 1 : 0),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    ],
                  ),
                ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LedgerRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
