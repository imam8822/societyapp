import 'package:flutter/material.dart';
import 'package:societyapp/core/app_utils.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_services.dart';
import '../../models/expense_models.dart';
import '../../core/constants.dart';
import '../../widgets/shared_widgets.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  final List<ExpenseDto> _expenses = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _expenses.clear();
    }

    if (!_hasMore || _loading) return;

    setState(() => _loading = true);

    try {
      final items = await ExpenseApi.getAllExpenses(page: _page, limit: _limit);
      setState(() {
        if (items.length < _limit) _hasMore = false;
        _expenses.addAll(items);
        _page++;
      });
    } catch (e) {
      if (mounted) {
        AppUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showExpenseSheet([ExpenseDto? expense]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ExpenseSheet(
        expense: expense,
        onSaved: () => _loadExpenses(refresh: true),
      ),
    );
  }

  Future<void> _deleteExpense(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ExpenseApi.deleteExpense(id);
      _loadExpenses(refresh: true);
    } catch (e) {
      if (mounted) {
        AppUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(
        title: const Text('Society Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showExpenseSheet(),
          ),
        ],
      ),
      body: _expenses.isEmpty && _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
          : _expenses.isEmpty
              ? const EmptyState(icon: Icons.receipt_long, title: 'No expenses found')
              : RefreshIndicator(
                  onRefresh: () => _loadExpenses(refresh: true),
                  color: context.colors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _expenses.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == _expenses.length) {
                        _loadExpenses();
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                      }
                      final e = _expenses[index];
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(e.amount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                              ],
                            ),
                            if (e.description != null && e.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(e.description!, style: TextStyle(color: context.colors.textGrey, fontSize: 13)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('d MMM yyyy').format(e.dateIncurred), style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
                                Text('Added by: ${e.addedByName}', style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showExpenseSheet(e),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteExpense(e.id),
                                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ExpenseSheet extends StatefulWidget {
  final ExpenseDto? expense;
  final VoidCallback onSaved;

  const _ExpenseSheet({this.expense, required this.onSaved});

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleCtrl.text = widget.expense!.title;
      _descCtrl.text = widget.expense!.description ?? '';
      _amountCtrl.text = widget.expense!.amount.toString();
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty || _amountCtrl.text.isEmpty) return;

    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'amount': double.parse(_amountCtrl.text),
      };

      if (widget.expense == null) {
        await ExpenseApi.createExpense(data);
      } else {
        await ExpenseApi.updateExpense(widget.expense!.id, data);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: context.colors.bgGrey,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.expense == null ? 'Add Expense' : 'Edit Expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textDark)),
          const SizedBox(height: 16),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description (Optional)')),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const CircularProgressIndicator() : const Text('Save Expense'),
          ),
        ],
      ),
    );
  }
}
