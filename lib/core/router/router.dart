import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/providers/auth_provider.dart';
import 'package:society_app/screens/admin/admin_dashboard_screen.dart';
import 'package:society_app/screens/admin/admin_screens.dart';
import 'package:society_app/screens/admin/members_screen.dart';
import 'package:society_app/screens/auth/login_screen.dart';
import 'package:society_app/screens/user/pay_screen.dart';
import 'package:society_app/screens/user/user_dashboard_screen.dart';
import 'package:society_app/screens/user/user_screens.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = auth.isLoggedIn;
      final onLogin = state.matchedLocation == '/login';

      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) {
        return auth.role == 'Admin' ? '/admin' : '/home';
      }
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ── User ──────────────────────────────
      GoRoute(path: '/home', builder: (_, __) => const UserDashboardScreen()),
      GoRoute(path: '/pay', builder: (_, __) => const PayScreen()),
      GoRoute(
          path: '/contributions',
          builder: (_, __) => const ContributionHistoryScreen()),
      GoRoute(path: '/loan/apply', builder: (_, __) => const LoanApplyScreen()),
      GoRoute(
          path: '/loan/status', builder: (_, __) => const LoanStatusScreen()),

      // ── Admin ─────────────────────────────
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/members', builder: (_, __) => const MembersScreen()),
      GoRoute(
          path: '/admin/members/add',
          builder: (_, __) => const AddMemberScreen()),
      GoRoute(
          path: '/admin/loans',
          builder: (_, __) => const LoanReviewScreen()),
      GoRoute(
          path: '/admin/screenshots',
          builder: (_, __) => const ScreenshotReviewScreen()),
      GoRoute(
          path: '/admin/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
          path: '/admin/settings',
          builder: (_, __) => const SettingsScreen()),
    ],
  );
});
