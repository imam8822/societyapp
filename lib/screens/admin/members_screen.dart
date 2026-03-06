import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_services.dart';
import '../../core/api/api_client.dart';
import '../../core/constants.dart';
import '../../models/user_models.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';
import 'member_detail_screen.dart';
import 'edit_member_sheet.dart';

// ═════════════════════════════════════════════
// Members List
// ═════════════════════════════════════════════
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Members')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/members/add');
          ref.invalidate(membersProvider);
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Member'),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(message: e.toString(), onRetry: () => ref.invalidate(membersProvider)),
        data: (members) => members.isEmpty
            ? const EmptyState(icon: Icons.people_outline_rounded, title: 'No members yet')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _MemberCard(
                  member: members[i],
                  onEdited: () => ref.invalidate(membersProvider),
                ),
              ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserSummary member;
  final VoidCallback onEdited;
  const _MemberCard({required this.member, required this.onEdited});

  @override
  Widget build(BuildContext context) {
    final hasPending = member.pendingAmount > 0;
    return GestureDetector(
      onTap: () async {
        final edited = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (_) => MemberDetailScreen(member: member)));
        if (edited == true) onEdited();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryLight,
            child: Text(member.fullName[0].toUpperCase(),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(member.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark)),
                ),
                if (member.role == 'Admin') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Admin', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
              Text(member.phone, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              if (member.referredByName != null)
                Text('Ref: ${member.referredByName}',
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('₹${member.totalInvested.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
            Text('${member.totalContributions} months',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            if (hasPending)
              Text('₹${member.pendingAmount.toStringAsFixed(0)} due',
                  style: const TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(width: 4),
          // Edit icon
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textGrey),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => EditMemberSheet(member: member, onSaved: onEdited),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Add Member Screen
// ═════════════════════════════════════════════
class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});
  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _preInvestCtrl = TextEditingController(text: '0');
  final _pendingCtrl = TextEditingController(text: '0');
  DateTime _joinedDate = DateTime.now();
  bool _loading = false;
  bool _obscure = true;
  UserDropdownItem? _selectedReferral;
  List<UserDropdownItem> _referralOptions = [];

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  Future<void> _loadReferrals() async {
    try {
      final list = await UserApi.getAllForReferral();
      setState(() => _referralOptions = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _preInvestCtrl.dispose(); _pendingCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Joining Date',
    );
    if (picked != null) setState(() => _joinedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await UserApi.createUser(CreateUserRequest(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text,
        preExistingInvestment: double.tryParse(_preInvestCtrl.text) ?? 0,
        joinedDate: _joinedDate,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        pendingAmount: double.tryParse(_pendingCtrl.text) ?? 0,
        referredById: _selectedReferral?.id,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member added successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(title: const Text('Add New Member')),
      body: LoadingOverlay(
        isLoading: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(children: [
              _card('Basic Info', [
                _field(_nameCtrl, 'Full Name', Icons.person_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 14),
                _field(_phoneCtrl, 'Mobile Number', Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.length < 10 ? 'Enter valid mobile' : null),
                const SizedBox(height: 14),
                _field(_emailCtrl, 'Email (optional)', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
              ]),
              const SizedBox(height: 14),
              const SizedBox(height: 14),
              _card('Joining Date & Pending', [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, color: AppTheme.textGrey, size: 20),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Joining Date *', style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                        Text(
                          '${_joinedDate.day}/${_joinedDate.month}/${_joinedDate.year}',
                          style: const TextStyle(fontSize: 15, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                        ),
                      ]),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.textGrey),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                _field(_pendingCtrl, 'Pending Amount (₹)', Icons.warning_amber_outlined,
                    keyboardType: TextInputType.number),
              ]),
              const SizedBox(height: 14),
              _card('Pre-existing Investment', [
                const Text(
                  'If this member was paying contributions before joining the app, enter the total amount already invested.',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _preInvestCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Already Invested (₹)',
                    hintText: 'e.g. 10500',
                    prefixIcon: Icon(Icons.savings_outlined),
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              _card('Referral (Optional)', [
                DropdownButtonFormField<UserDropdownItem>(
                  value: _selectedReferral,
                  hint: const Text('Select who referred this member'),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_add_outlined),
                  ),
                  items: _referralOptions.map((u) => DropdownMenuItem(
                    value: u,
                    child: Text('${u.fullName} (${u.phone})'),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedReferral = v),
                ),
              ]),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: const Text('Add Member'),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textGrey, fontSize: 12)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
      );
}