import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_services.dart';
import '../../models/transaction_models.dart';
import '../../core/constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/export_dialog.dart';

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == _transactions.length) {
                        _loadTransactions();
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                      }
                      final t = _transactions[index];
                      final isAddition = t.amount >= 0;
                      final color = isAddition ? const Color(0xFF16A34A) : context.colors.error;

                      return Container(
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
                              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
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
                  ),
                ),
    );
  }
}
