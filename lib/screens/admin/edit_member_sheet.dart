import 'package:flutter/material.dart';
import '../../core/api/api_services.dart';
import '../../core/constants.dart';
import '../../models/user_models.dart';

class EditMemberSheet extends StatefulWidget {
  final UserSummary member;
  final VoidCallback onSaved;
  const EditMemberSheet({super.key, required this.member, required this.onSaved});

  @override
  State<EditMemberSheet> createState() => _EditMemberSheetState();
}

class _EditMemberSheetState extends State<EditMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.member.phone);
    _emailCtrl = TextEditingController(
      text: widget.member.email.contains('@society.app') ? '' : widget.member.email,
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{};
      if (_phoneCtrl.text.trim() != widget.member.phone)
        data['phone'] = _phoneCtrl.text.trim();
      if (_emailCtrl.text.trim().isNotEmpty &&
          _emailCtrl.text.trim() != widget.member.email)
        data['email'] = _emailCtrl.text.trim();
      if (_passCtrl.text.isNotEmpty)
        data['newPassword'] = _passCtrl.text;

      if (data.isEmpty) { Navigator.pop(context); return; }

      await UserApi.updateUser(widget.member.id, data);
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member updated successfully')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle bar
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryLight,
                child: Text(widget.member.fullName[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.member.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
                const Text('Edit contact & password',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              ]),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const Divider(height: 24, color: AppTheme.divider),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textGrey),
                labelStyle: TextStyle(color: AppTheme.textGrey),
              ),
              style: const TextStyle(color: AppTheme.textDark),
              validator: (v) => v!.length < 10 ? 'Enter valid mobile' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textGrey),
                labelStyle: TextStyle(color: AppTheme.textGrey),
              ),
              style: const TextStyle(color: AppTheme.textDark),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'New Password (leave blank to keep)',
                prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.textGrey),
                labelStyle: const TextStyle(color: AppTheme.textGrey),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.textGrey),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              style: const TextStyle(color: AppTheme.textDark),
              validator: (v) => v!.isNotEmpty && v.length < 6 ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}