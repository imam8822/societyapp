import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';
import 'admin_screens.dart';
import 'screenshot_review_screen.dart';
import 'statistics_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        key: ValueKey(_currentIndex),
        builder: (context) {
          switch (_currentIndex) {
            case 0:
              return _buildDashboardTab(context);
            case 1:
              return const LoanReviewScreen();
            case 2:
              return const ScreenshotReviewScreen();
            case 3:
            default:
              return const StatisticsScreen();
          }
        },
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFF111428),
          indicatorColor: const Color(0xFF2A2E50),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Color(0xFF9094B6), fontSize: 11, fontWeight: FontWeight.w500),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFC084FC));
            }
            return const IconThemeData(color: Color(0xFF9094B6));
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance),
              label: 'Loans',
            ),
            NavigationDestination(
              icon: Icon(Icons.image_search_outlined),
              selectedIcon: Icon(Icons.image_search),
              label: 'Reviews',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats & Ledger',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    final dashAsync = ref.watch(adminDashboardProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
              final unreadCount = notifs.where((n) => !n.isRead).length;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/admin/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const ShimmerListLoader(count: 5),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(adminDashboardProvider)),
        data: (dash) => RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async => ref.invalidate(adminDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Pool Card ─────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF2ECC71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month payment status
                      Row(children: [
                        const Icon(Icons.people_outline_rounded,
                            color: Colors.white70, size: 15),
                        const SizedBox(width: 6),
                        Text(
                          '${dash.currentMonthPaidCount} of ${dash.activeMembers} paid this month',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ]),

                      const SizedBox(height: 20),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 20),

                      // Two financial stats side by side
                      Row(children: [
                        Expanded(
                          child: _FinanceStat(
                            label: 'Total Collected',
                            value: fmt.format(dash.totalCollected),
                            icon: Icons.arrow_downward_rounded,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: _FinanceStat(
                            label: 'Balance',
                            value: fmt.format(dash.balance),
                            icon: Icons.account_balance_wallet_outlined,
                            valueColor: Colors.greenAccent.shade200,
                            alignRight: true,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Alert badges ──────────────────────
              if (dash.pendingLoanApplications > 0 ||
                  dash.loansAwaitingDisbursement > 0 ||
                  dash.pendingScreenshotReviews > 0) ...[
                const SectionHeader(title: 'Action Required'),
                const SizedBox(height: 10),
                if (dash.pendingLoanApplications > 0)
                  _AlertBanner(
                    icon: Icons.pending_actions_rounded,
                    label: '${dash.pendingLoanApplications} loan application(s) awaiting review',
                    color: AppTheme.warning,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                if (dash.loansAwaitingDisbursement > 0)
                  _AlertBanner(
                    icon: Icons.payment_rounded,
                    label: '${dash.loansAwaitingDisbursement} approved loan(s) to disburse',
                    color: const Color(0xFF2563EB),
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                if (dash.pendingScreenshotReviews > 0)
                  _AlertBanner(
                    icon: Icons.image_search_rounded,
                    label: '${dash.pendingScreenshotReviews} screenshot(s) need manual verification',
                    color: AppTheme.primary,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                const SizedBox(height: 16),
              ],

              // ── Stats grid ────────────────────────
              const SectionHeader(title: 'Overview'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 0),
                    child: StatCard(
                      label: 'Total Members',
                      value: '${dash.totalMembers}',
                      icon: Icons.people_alt_rounded,
                      onTap: () => context.push('/admin/members'),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: StatCard(
                      label: 'Active Loans',
                      value: '${dash.activeLoans}',
                      icon: Icons.account_balance_rounded,
                      iconColor: const Color(0xFF2563EB),
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: StatCard(
                      label: 'Total Disbursed',
                      value: fmt.format(dash.totalDisbursed),
                      icon: Icons.currency_rupee_rounded,
                      iconColor: AppTheme.warning,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: StatCard(
                      label: 'Outstanding',
                      value: fmt.format(dash.outstandingAmount),
                      icon: Icons.pending_rounded,
                      iconColor: AppTheme.error,
                      onTap: () => setState(() => _currentIndex = 3),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}

// ── Finance stat inside gradient card ────────────────────────
class _FinanceStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? valueColor;
  final bool alignRight;

  const _FinanceStat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          left: alignRight ? 20 : 0,
          right: alignRight ? 0 : 20,
        ),
        child: Column(
          crossAxisAlignment:
              alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: alignRight
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!alignRight) ...[
                  Icon(icon, color: Colors.white54, size: 13),
                  const SizedBox(width: 4),
                ],
                Text(label,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 12)),
                if (alignRight) ...[
                  const SizedBox(width: 4),
                  Icon(icon, color: Colors.white54, size: 13),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

// ── Alert banner ───────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AnimatedPressable(
        onTap: onTap,
        scale: 0.97,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13))),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ]),
        ),
      );
}
