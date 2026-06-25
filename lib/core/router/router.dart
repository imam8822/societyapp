import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:society_app/providers/auth_provider.dart';
import 'package:society_app/screens/admin/admin_dashboard_screen.dart';
import 'package:society_app/screens/admin/admin_screens.dart';
import 'package:society_app/screens/admin/members_screen.dart';
import 'package:society_app/screens/admin/screenshot_review_screen.dart';
import 'package:society_app/screens/admin/collect_cash_screen.dart';
import 'package:society_app/screens/auth/login_screen.dart';
import 'package:society_app/screens/user/pay_screen.dart';
import 'package:society_app/screens/user/loan_repay_screen.dart';
import 'package:society_app/screens/user/user_dashboard_screen.dart';
import 'package:society_app/screens/user/user_screens.dart';
import 'package:society_app/screens/notifications_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = notifier.isLoggedIn;
      final role = notifier.role;
      final onLogin = state.matchedLocation == '/login';

      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) {
        return role == 'Admin' ? '/admin' : '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const UserDashboardScreen()),
      GoRoute(path: '/pay', builder: (_, __) => const PayScreen()),
      GoRoute(
          path: '/contributions',
          builder: (_, __) => const ContributionHistoryScreen()),
      GoRoute(
          path: '/loan/apply', builder: (_, __) => const LoanApplyScreen()),
      GoRoute(
          path: '/loan/status', builder: (_, __) => const LoanStatusScreen()),
      GoRoute(
          path: '/loan/repay/:id',
          builder: (_, state) => LoanRepayScreen(
              loanId: int.parse(state.pathParameters['id']!))),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
          path: '/admin/members', builder: (_, __) => const MembersScreen()),
      GoRoute(
          path: '/admin/collect-cash',
          builder: (_, __) => const CollectCashScreen()),
      GoRoute(
          path: '/admin/members/add',
          builder: (_, __) => const AddMemberScreen()),
      GoRoute(
          path: '/admin/loans', builder: (_, __) => const LoanReviewScreen()),
      GoRoute(
          path: '/admin/screenshots',
          builder: (_, __) => const ScreenshotReviewScreen()),
      GoRoute(
          path: '/admin/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(
          path: '/admin/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    // Seed initial values
    final auth = ref.read(authProvider);
    _isLoggedIn = auth.isLoggedIn;
    _role = auth.role;

    // Only notify router when isLoggedIn actually changes
    // Ignores isLoading/error changes — prevents form reset
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.isLoggedIn != next.isLoggedIn) {
        _isLoggedIn = next.isLoggedIn;
        _role = next.role;
        notifyListeners();
      }
    });
  }

  bool _isLoggedIn = false;
  String? _role;

  bool get isLoggedIn => _isLoggedIn;
  String? get role => _role;
}