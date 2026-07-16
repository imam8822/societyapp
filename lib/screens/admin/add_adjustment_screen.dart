import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_services.dart';
import '../../core/constants.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';

class AddAdjustmentScreen extends ConsumerStatefulWidget {
  const AddAdjustmentScreen({super.key});

  @override
  ConsumerState<AddAdjustmentScreen> createState() => _AddAdjustmentScreenState();
}

class _AddAdjustmentScreenState extends ConsumerState<AddAdjustmentScreen> {
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _loading = false;
  bool _isAddition = true; // true = Add to balance, false = Subtract from balance

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Amount must be greater than zero'), backgroundColor: context.colors.error),
      );
      return;
    }
    
    final finalAmount = _isAddition ? amount : -amount;
    final remarks = _remarksCtrl.text.trim();

    setState(() => _loading = true);
    try {
      await AdjustmentApi.recordAdjustment(finalAmount, remarks);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ledger adjustment recorded successfully'),
            backgroundColor: context.colors.primary,
          ),
        );
        ref.invalidate(adminDashboardProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiError(e)), backgroundColor: context.colors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(
        title: const Text('Adjust Ledger'),
        backgroundColor: context.colors.bgGrey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Adjustments allow you to manually fix discrepancies in the total balance. Use with caution.',
                        style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Toggle Add/Subtract
              Text('Adjustment Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textDark)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeSelectCard(
                      label: 'Add to Balance',
                      icon: Icons.add_circle_outline_rounded,
                      color: Colors.green,
                      selected: _isAddition,
                      onTap: () => setState(() => _isAddition = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeSelectCard(
                      label: 'Subtract from Balance',
                      icon: Icons.remove_circle_outline_rounded,
                      color: Colors.red,
                      selected: !_isAddition,
                      onTap: () => setState(() => _isAddition = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount
              Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textDark),
                  hintText: '0.00',
                  filled: true,
                  fillColor: context.colors.surfaceWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.divider)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                  if (double.tryParse(val) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Remarks
              Text('Remarks (Required)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textDark)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _remarksCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Why are you making this adjustment?',
                  filled: true,
                  fillColor: context.colors.surfaceWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.divider)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Remarks are required for adjustments';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: context.colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Adjustment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelectCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeSelectCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : context.colors.surfaceWhite,
          border: Border.all(color: selected ? color : context.colors.divider, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : context.colors.textGrey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? color : context.colors.textDark,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
