import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.microtask(() {});

    try {
      final success = await ref
          .read(authProvider.notifier)
          .login(_phoneCtrl.text.trim(), _passCtrl.text);

      if (!mounted) return;

      if (success) {
        final role = ref.read(authProvider).role;
        context.go(role == 'Admin' ? '/admin' : '/home');
      } else {
        // Read the actual error from provider
        final providerError = ref.read(authProvider).error;
        setState(() {
          _error = providerError ?? 'Login failed. Please try again.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // Logo
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.currency_rupee,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 28),
                    const Text('Welcome back',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 6),
                    const Text('Sign in to your society account',
                        style: TextStyle(
                            fontSize: 15, color: AppTheme.textGrey)),

                    const SizedBox(height: 40),

                    // Phone
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      enabled: !_loading,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => v == null || v.length < 10
                          ? 'Enter a valid mobile number'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      enabled: !_loading,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: _loading
                              ? null
                              : () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your password'
                          : null,
                      onFieldSubmitted: (_) => _loading ? null : _login(),
                    ),

                    const SizedBox(height: 12),

                    // Server URL shown for debugging
                    Text(
                      'Server: ${AppConstants.baseUrl}',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textGrey),
                    ),

                    const SizedBox(height: 8),

                    // Error
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppTheme.error, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Login button
                    ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Sign In'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Full-screen overlay while navigating
          if (_loading)
            Container(
              color: Colors.white.withOpacity(0.75),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}