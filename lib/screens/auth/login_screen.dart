import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  // Entry animation controller
  late AnimationController _entryCtrl;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  static const _itemCount = 5; // logo, title, subtitle, fields, button
  static const _stagger = 80; // ms between each item

  String? _societyName;
  String? _logoBase64;

  @override
  void initState() {
    super.initState();
    _fetchPublicSettings();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400 + (_itemCount - 1) * _stagger),
    );

    _fadeAnims = List.generate(_itemCount, (i) {
      final start = (i * _stagger) / _entryCtrl.duration!.inMilliseconds;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_itemCount, (i) {
      final start = (i * _stagger) / _entryCtrl.duration!.inMilliseconds;
      final end = (start + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _entryCtrl.forward();
  }

  Future<void> _fetchPublicSettings() async {
    try {
      final res = await ApiClient.instance.get('/settings/public');
      if (mounted && res.data != null) {
        setState(() {
          _societyName = res.data['societyName'];
          _logoBase64 = res.data['logoBase64'];
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch public settings: $e');
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _fadeAnims[index],
      child: SlideTransition(position: _slideAnims[index], child: child),
    );
  }

  String? _validatePhone(String v) {
    if (v.trim().length < 10) return 'Enter a valid mobile number';
    return null;
  }

  String? _validatePass(String v) {
    if (v.isEmpty) return 'Enter your password';
    return null;
  }

  Future<void> _login() async {
    final phoneError = _validatePhone(_phoneCtrl.text);
    final passError = _validatePass(_passCtrl.text);

    if (phoneError != null || passError != null) {
      setState(() => _error = phoneError ?? passError);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = await ref
          .read(authProvider.notifier)
          .login(_phoneCtrl.text.trim(), _passCtrl.text);

      if (!mounted) return;

      if (success) {
        final role = ref.read(authProvider).role;
        context.go((role == 'Admin' || role == 'SuperAdmin' || role == 'Auditor') ? '/admin' : '/home');
        return;
      }

      final providerError = ref.read(authProvider).error;
      setState(() {
        _error = providerError ?? 'Invalid mobile or password.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // ── Logo
                  _animated(
                    0,
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Title
                  _animated(
                    1,
                    Text(
                      _societyName ?? 'Welcome back',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textDark,
                          letterSpacing: -0.5),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── Subtitle
                  _animated(
                    2,
                    Text(
                      'Sign in to your society account',
                      style:
                          TextStyle(fontSize: 15, color: context.colors.textGrey),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Fields
                  _animated(
                    3,
                    Column(
                      children: [
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Error Banner (animated appearance)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.2),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _error != null
                        ? Container(
                            key: const ValueKey('error'),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      context.colors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline,
                                    color: context.colors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                        color: context.colors.error, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-error')),
                  ),

                  const SizedBox(height: 24),

                  // ── Sign In Button (animated press)
                  _animated(
                    4,
                    AnimatedPressable(
                      onTap: _loading ? null : _login,
                      scale: 0.97,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _loading
                                ? null
                                : LinearGradient(
                                    colors: [
                                      context.colors.primary,
                                      const Color(0xFF5B21B6)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: _loading ? context.colors.surfaceWhite : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _loading
                                ? []
                                : [
                                    BoxShadow(
                                      color: context.colors.primary
                                          .withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: _loading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: context.colors.primary,
                                        strokeWidth: 2),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
