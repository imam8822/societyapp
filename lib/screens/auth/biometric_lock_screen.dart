import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/local_auth_service.dart';
import '../../providers/auth_provider.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptBiometric();
    });
  }

  Future<void> _promptBiometric() async {
    final canCheck = await LocalAuthService.canCheckBiometrics();
    if (!canCheck) {
      // If biometrics are not available but we're on this screen, 
      // fallback to passing through
      ref.read(authProvider.notifier).unlockBiometric();
      return;
    }

    final success = await LocalAuthService.authenticate();
    if (success) {
      ref.read(authProvider.notifier).unlockBiometric();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 100, color: Colors.blueGrey),
            const SizedBox(height: 24),
            const Text(
              'App Locked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please authenticate to access your account.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _promptBiometric,
              child: const Text('Unlock with Biometrics'),
            ),
            TextButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
