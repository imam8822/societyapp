import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
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
                    onTap: () => context.push('/admin/loans'),
                  ),
                if (dash.loansAwaitingDisbursement > 0)
                  _AlertBanner(
                    icon: Icons.payment_rounded,
                    label: '${dash.loansAwaitingDisbursement} approved loan(s) to disburse',
                    color: const Color(0xFF2563EB),
                    onTap: () => context.push('/admin/loans'),
                  ),
                if (dash.pendingScreenshotReviews > 0)
                  _AlertBanner(
                    icon: Icons.image_search_rounded,
                    label: '${dash.pendingScreenshotReviews} screenshot(s) need manual verification',
                    color: AppTheme.primary,
                    onTap: () => context.push('/admin/screenshots'),
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
                childAspectRatio: 1.1,
                children: [
                  StatCard(
                    label: 'Total Members',
                    value: '${dash.totalMembers}',
                    icon: Icons.people_outline_rounded,
                    onTap: () => context.push('/admin/members'),
                  ),
                  StatCard(
                    label: 'Active Loans',
                    value: '${dash.activeLoans}',
                    icon: Icons.account_balance_rounded,
                    iconColor: const Color(0xFF2563EB),
                  ),
                  StatCard(
                    label: 'Total Disbursed',
                    value: fmt.format(dash.totalDisbursed),
                    icon: Icons.currency_rupee_rounded,
                    iconColor: AppTheme.warning,
                  ),
                  StatCard(
                    label: 'Outstanding',
                    value: fmt.format(dash.outstandingAmount),
                    icon: Icons.pending_rounded,
                    iconColor: AppTheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Quick nav ─────────────────────────
              const SectionHeader(title: 'Manage'),
              const SizedBox(height: 10),
              ...[
                _NavTile(
                  icon: Icons.account_balance_rounded,
                  label: 'Loans',
                  subtitle: '${dash.pendingLoanApplications} pending',
                  badge: dash.pendingLoanApplications,
                  onTap: () => context.push('/admin/loans'),
                ),
                _NavTile(
                  icon: Icons.image_search_rounded,
                  label: 'Screenshot Reviews',
                  subtitle: '${dash.pendingScreenshotReviews} pending',
                  badge: dash.pendingScreenshotReviews,
                  onTap: () => context.push('/admin/screenshots'),
                ),
                _NavTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  subtitle: 'Monthly & yearly',
                  onTap: () => context.push('/admin/reports'),
                ),
              ],
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

// ── Alert banner ──────────────────────────────────────────────
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.25)),
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

// ── Nav tile ──────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppTheme.textDark)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 12)),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textGrey),
          ]),
        ),
      );
}