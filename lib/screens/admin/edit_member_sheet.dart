import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_services.dart';
import '../../core/constants.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_utils.dart';
import '../../providers/data_providers.dart';
import '../../models/user_models.dart';

class EditMemberSheet extends ConsumerStatefulWidget {
  final UserSummary member;
  final VoidCallback onSaved;
  const EditMemberSheet({super.key, required this.member, required this.onSaved});

  @override
  ConsumerState<EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends ConsumerState<EditMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  final _passCtrl = TextEditingController();
  
  bool _loading = false;
  bool _obscure = true;
  
  List<UserDropdownItem> _referralOptions = [];
  int? _selectedReferredById;
  late String _selectedRole;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.fullName);
    _phoneCtrl = TextEditingController(text: widget.member.phone);
    _emailCtrl = TextEditingController(
      text: widget.member.email.contains('@society.app') ? '' : widget.member.email,
    );
    _selectedReferredById = widget.member.referredById;
    _selectedRole = widget.member.role;
    _isActive = widget.member.isActive;
    _loadReferralOptions();
  }

  Future<void> _loadReferralOptions() async {
    try {
      final opts = await UserApi.getAllForReferral();
      if (mounted) {
        setState(() {
          _referralOptions = opts;
        });
      }
    } catch (e) {
      debugPrint('Error loading referrals: $e');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  int _roleStringToInt(String role) {
    switch (role) {
      case 'Admin': return 0;
      case 'User': return 1;
      case 'SuperAdmin': return 2;
      case 'Auditor': return 3;
      default: return 1;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{
        'fullName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _roleStringToInt(_selectedRole),
        'isActive': _isActive,
        'referredById': _selectedReferredById,
      };
      
      if (_passCtrl.text.isNotEmpty) {
        data['newPassword'] = _passCtrl.text;
      }

      await UserApi.updateUser(widget.member.id, data);
      ref.invalidate(adminDashboardProvider);
      widget.onSaved();
      if (mounted) {
        AppUtils.showSuccess(context, 'Member updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showError(context, e.toString());
      }
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
                // Handle bar
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
                  children: [
                    CircleAvatar(
                      backgroundColor: context.colors.primaryLight,
                      child: Text(
                        widget.member.fullName.isNotEmpty
                            ? widget.member.fullName[0].toUpperCase()
                            : 'M',
                        style: TextStyle(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Member',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: context.colors.textDark),
                          ),
                          Text(
                            widget.member.fullName,
                            style: TextStyle(
                                color: context.colors.textGrey,
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
                Divider(height: 24, color: context.colors.divider),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                  validator: (v) => v!.trim().isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone_outlined, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                  validator: (v) => v!.length < 10 ? 'Enter valid mobile' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (optional)',
                    prefixIcon: Icon(Icons.email_outlined, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.shield_outlined, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                  dropdownColor: context.colors.surfaceWhite,
                  items: const [
                    DropdownMenuItem(value: 'User', child: Text('User')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'SuperAdmin', child: Text('SuperAdmin')),
                    DropdownMenuItem(value: 'Auditor', child: Text('Auditor')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRole = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int?>(
                  value: _selectedReferredById,
                  decoration: InputDecoration(
                    labelText: 'Referred By',
                    prefixIcon: Icon(Icons.handshake_outlined, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                  dropdownColor: context.colors.surfaceWhite,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('- None -'),
                    ),
                    if (_selectedReferredById != null &&
                        !_referralOptions.any((e) => e.id == _selectedReferredById))
                      DropdownMenuItem<int?>(
                        value: _selectedReferredById,
                        child: Text(widget.member.referredByName ?? 'Selected Referral'),
                      ),
                    ..._referralOptions.map((e) => DropdownMenuItem<int?>(
                          value: e.id,
                          child: Text('${e.fullName} (${e.phone})'),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedReferredById = val);
                  },
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'New Password (leave blank to keep)',
                    prefixIcon: Icon(Icons.lock_outlined, color: context.colors.textGrey),
                    labelStyle: TextStyle(color: context.colors.textGrey),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: context.colors.textGrey),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  style: TextStyle(color: context.colors.textDark),
                  validator: (v) => v!.isNotEmpty && v.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes'),
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
