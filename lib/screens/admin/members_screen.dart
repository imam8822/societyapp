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

// ═════════════════════════════════════════════
// Members List
// ═════════════════════════════════════════════
class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        error: (e, _) => ErrorRetry(
          message: apiError(e),
          onRetry: () => ref.invalidate(membersProvider),
        ),
        data: (members) {
          final filtered = _query.isEmpty
              ? members
              : members.where((m) =>
                  m.fullName.toLowerCase().contains(_query) ||
                  m.phone.contains(_query)).toList();

          return Column(
            children: [
              // ── Search bar ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
                  decoration: InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppTheme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),

              // ── Count ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(children: [
                  Text(
                    '${filtered.length} member${filtered.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
                  ),
                ]),
              ),

              // ── List ────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('No members found',
                            style: TextStyle(color: AppTheme.textGrey)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                        itemBuilder: (_, i) => _MemberTile(
                          member: filtered[i],
                          onEdited: () => ref.invalidate(membersProvider),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final UserSummary member;
  final VoidCallback onEdited;
  const _MemberTile({required this.member, required this.onEdited});

  @override
  Widget build(BuildContext context) {
    final hasPending = member.pendingAmount > 0;

    return InkWell(
      onTap: () async {
        final edited = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => MemberDetailScreen(member: member)),
        );
        if (edited == true) onEdited();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryLight,
            child: Text(
              member.fullName[0].toUpperCase(),
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + Phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      member.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (member.role == 'Admin') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Admin',
                          style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
                Text(
                  member.phone,
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Pending or clear
          if (hasPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '₹${member.pendingAmount.toStringAsFixed(0)} due',
                style: const TextStyle(
                  color: AppTheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2ECC71)),

          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textGrey),
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
    _emailCtrl.dispose(); _passCtrl.dispose();
    _preInvestCtrl.dispose(); _pendingCtrl.dispose();
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(apiError(e))));
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
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                ),
              ]),
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
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.textGrey, size: 20),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Joining Date *',
                            style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                        Text(
                          '${_joinedDate.day}/${_joinedDate.month}/${_joinedDate.year}',
                          style: const TextStyle(
                              fontSize: 15,
                              color: AppTheme.textDark,
                              fontWeight: FontWeight.w500),
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
                  isExpanded: true,
                  hint: const Text('Select who referred this member',
                      overflow: TextOverflow.ellipsis),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_add_outlined),
                  ),
                  items: _referralOptions
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              '${u.fullName} (${u.phone})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGrey,
                  fontSize: 12)),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
      );
}