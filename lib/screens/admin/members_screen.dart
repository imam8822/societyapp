import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_services.dart';
import '../../core/api/api_client.dart';
import '../../core/constants.dart';
import '../../models/user_models.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';

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
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(membersProvider)),
        data: (members) => members.isEmpty
            ? const EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No members yet',
                subtitle: 'Add your first society member')
            : ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _MemberCard(member: members[i]),
              ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserSummary member;
  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              member.fullName[0].toUpperCase(),
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textDark)),
                Text(member.phone,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 13)),
                if (member.referredBy != null)
                  Text('Ref: ${member.referredBy}',
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${member.totalSaved.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
              Text('${member.totalContributions} months',
                  style: const TextStyle(
                      color: AppTheme.textGrey, fontSize: 12)),
              if (!member.isActive)
                const StatusBadge(status: 'Rejected'),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Add Member Screen
// ═════════════════════════════════════════════
class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key});

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '500');
  final _penaltyCtrl = TextEditingController(text: '50');
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _refCtrl.dispose();
    _amountCtrl.dispose();
    _penaltyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await UserApi.createUser(CreateUserRequest(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        referredBy: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        monthlyContributionAmount: double.tryParse(_amountCtrl.text) ?? 500,
        penaltyPerMissedMonth: double.tryParse(_penaltyCtrl.text) ?? 50,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member added successfully!')));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      setState(() => _loading = false);
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
            child: Column(
              children: [
                _field(
                  ctrl: _nameCtrl,
                  label: 'Full Name',
                  icon: Icons.person_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  ctrl: _phoneCtrl,
                  label: 'Mobile Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      v == null || v.length < 10 ? 'Enter valid mobile' : null,
                ),
                const SizedBox(height: 14),
                _field(
                  ctrl: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6
                          ? 'Min 6 characters'
                          : null,
                ),
                const SizedBox(height: 14),
                _field(
                  ctrl: _refCtrl,
                  label: 'Referred By (optional)',
                  icon: Icons.person_add_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Amount (₹)',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Enter valid amount'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _penaltyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Penalty/Month (₹)',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: const Text('Add Member'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
            labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
      );
}