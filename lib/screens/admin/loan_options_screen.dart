import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_services.dart';
import '../../core/app_utils.dart';
import '../../core/constants.dart';
import '../../models/loan_models.dart';
import '../../widgets/shared_widgets.dart';

class LoanOptionsScreen extends StatefulWidget {
  const LoanOptionsScreen({super.key});

  @override
  State<LoanOptionsScreen> createState() => _LoanOptionsScreenState();
}

class _LoanOptionsScreenState extends State<LoanOptionsScreen> {
  List<LoanOption> _options = [];
  bool _loading = false;
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() => _loading = true);
    try {
      final opts = await LoanApi.getAdminLoanOptions();
      setState(() => _options = opts);
    } catch (e) {
      AppUtils.showError(context, 'Failed to load options: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showOptionForm([LoanOption? option]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoanOptionFormSheet(
        option: option,
        onSaved: () {
          _loadOptions();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(
        title: const Text('Loan Options'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOptionForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Option'),
        backgroundColor: context.colors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading && _options.isEmpty
          ? Center(child: const AppSpinner())
          : RefreshIndicator(
              onRefresh: _loadOptions,
              color: context.colors.primary,
              child: _options.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        EmptyState(
                          icon: Icons.settings_applications_outlined,
                          title: 'No Loan Options',
                          subtitle: 'Create a loan option to get started',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final opt = _options[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colors.divider),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Row(
                              children: [
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: context.colors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: opt.isActive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    opt.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: opt.isActive ? Colors.green : Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(
                                  'Repay: ${_currencyFmt.format(opt.repaymentAmount)} • Tenure: ${opt.maxRepaymentTenure}m • Guarantors: ${opt.requiredGuarantors}',
                                  style: TextStyle(
                                    color: context.colors.textDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Min Saving Req: ${opt.minTenureRequired}m • Quota: ${opt.quota == null ? "Unlimited" : "${opt.quota}/mo"}',
                                  style: TextStyle(
                                    color: context.colors.textGrey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.edit_outlined, color: context.colors.primary, size: 20),
                              onPressed: () => _showOptionForm(opt),
                              tooltip: 'Edit Option',
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.colors.textGrey, fontSize: 13)),
          Text(value, style: TextStyle(color: context.colors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _LoanOptionFormSheet extends StatefulWidget {
  final LoanOption? option;
  final VoidCallback onSaved;

  const _LoanOptionFormSheet({this.option, required this.onSaved});

  @override
  State<_LoanOptionFormSheet> createState() => _LoanOptionFormSheetState();
}

class _LoanOptionFormSheetState extends State<_LoanOptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _minTenureCtrl;
  late final TextEditingController _maxTenureCtrl;
  late final TextEditingController _repayAmountCtrl;
  late final TextEditingController _quotaCtrl;
  late int _requiredGuarantors;
  late bool _isActive;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.option?.label ?? '');
    _amountCtrl = TextEditingController(text: widget.option?.amount.toStringAsFixed(0) ?? '');
    _minTenureCtrl = TextEditingController(text: widget.option?.minTenureRequired.toString() ?? '6');
    _maxTenureCtrl = TextEditingController(text: widget.option?.maxRepaymentTenure.toString() ?? '12');
    _repayAmountCtrl = TextEditingController(text: widget.option?.repaymentAmount.toStringAsFixed(0) ?? '');
    _quotaCtrl = TextEditingController(text: widget.option?.quota?.toString() ?? '');
    _requiredGuarantors = widget.option?.requiredGuarantors ?? 1;
    _isActive = widget.option?.isActive ?? true;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    _minTenureCtrl.dispose();
    _maxTenureCtrl.dispose();
    _repayAmountCtrl.dispose();
    _quotaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final payload = <String, dynamic>{
      'label': _labelCtrl.text.trim(),
      'amount': double.parse(_amountCtrl.text.trim()),
      'minTenureRequired': int.parse(_minTenureCtrl.text.trim()),
      'maxRepaymentTenure': int.parse(_maxTenureCtrl.text.trim()),
      'repaymentAmount': double.parse(_repayAmountCtrl.text.trim()),
      'requiredGuarantors': _requiredGuarantors,
      'quota': _quotaCtrl.text.trim().isEmpty ? null : int.parse(_quotaCtrl.text.trim()),
      'isActive': _isActive,
    };

    try {
      if (widget.option != null) {
        await LoanApi.updateLoanOption(widget.option!.id, payload);
        if (mounted) AppUtils.showSuccess(context, 'Loan option updated successfully');
      } else {
        await LoanApi.createLoanOption(payload);
        if (mounted) AppUtils.showSuccess(context, 'Loan option created successfully');
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) AppUtils.showError(context, 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.option == null ? 'Create Loan Option' : 'Edit Loan Option',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: context.colors.textDark,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(height: 24, color: context.colors.divider),
                TextFormField(
                  controller: _labelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g. Regular Loan Tier 1',
                    prefixIcon: Icon(Icons.label_outline, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                  validator: (v) => v!.trim().isEmpty ? 'Enter label' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Loan Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                  validator: (v) => v!.trim().isEmpty ? 'Enter amount' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _repayAmountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Repayment Amount (₹)',
                    prefixIcon: Icon(Icons.payments_outlined, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                  validator: (v) => v!.trim().isEmpty ? 'Enter repayment amount' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minTenureCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Min Tenure (Months)',
                          labelStyle: TextStyle(color: context.colors.textGrey),
                        ),
                        style: TextStyle(color: context.colors.textDark),
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _maxTenureCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Max Tenure (Months)',
                          labelStyle: TextStyle(color: context.colors.textGrey),
                        ),
                        style: TextStyle(color: context.colors.textDark),
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _requiredGuarantors,
                        decoration: InputDecoration(
                          labelText: 'Required Guarantors',
                          labelStyle: TextStyle(color: context.colors.textGrey),
                        ),
                        style: TextStyle(color: context.colors.textDark),
                        dropdownColor: context.colors.surfaceWhite,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('0')),
                          DropdownMenuItem(value: 1, child: Text('1')),
                          DropdownMenuItem(value: 2, child: Text('2')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _requiredGuarantors = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _quotaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Quota (Optional)',
                          hintText: 'Unlimited',
                          labelStyle: TextStyle(color: context.colors.textGrey),
                        ),
                        style: TextStyle(color: context.colors.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: Text(
                    'Status: ${_isActive ? "Active" : "Inactive"}',
                    style: TextStyle(color: context.colors.textDark, fontSize: 15),
                  ),
                  value: _isActive,
                  activeColor: context.colors.primary,
                  onChanged: (val) {
                    setState(() => _isActive = val);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: const AppSpinner(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(widget.option == null ? 'Create' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
