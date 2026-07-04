import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';
import 'admin_screens.dart';
import 'screenshot_review_screen.dart';
import 'statistics_screen.dart';
import '../../widgets/network_error_widget.dart';

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
          backgroundColor: context.colors.bgGrey,
          indicatorColor: context.colors.primary.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.all(
            TextStyle(color: context.colors.textGrey, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: context.colors.primary);
            }
            return IconThemeData(color: context.colors.textGrey);
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
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: dashAsync.valueOrNull?.logoBase64 != null
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: MemoryImage(
                        base64Decode(dashAsync.valueOrNull!.logoBase64!.contains(',')
                            ? dashAsync.valueOrNull!.logoBase64!.split(',')[1]
                            : dashAsync.valueOrNull!.logoBase64!),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            : null,
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
            icon: const Icon(Icons.person_outline),
            tooltip: 'Switch to Member View',
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/admin/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => const ShimmerListLoader(count: 5),
        error: (e, _) => NetworkErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(adminDashboardProvider)),
        data: (dash) => RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () async => ref.invalidate(adminDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Stats grid (React Style) ────────────────────────
              const SectionHeader(title: 'Overview'),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.25,
                children: [
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 0),
                    child: _ReactStatCard(
                      title: 'Current Balance',
                      value: fmt.format(dash.balance),
                      subtitle: 'Total Collected: ${fmt.format(dash.totalCollected)}',
                      icon: Icons.account_balance_wallet_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => context.push('/admin/ledger'),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 40),
                    child: _ReactStatCard(
                      title: 'Members',
                      value: '${dash.activeMembers}',
                      subtitle: 'Total Registered: ${dash.totalMembers}',
                      icon: Icons.people_alt_rounded,
                      bgColor: const Color(0xFF181B2F),
                      iconColor: const Color(0xFF10B981),
                      onTap: () => context.push('/admin/members'),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: _ReactStatCard(
                      title: 'Monthly Collections',
                      value: '${dash.currentMonthPaidCount} Paid',
                      subtitle: '${dash.currentMonthUnpaidCount} Unpaid',
                      icon: Icons.trending_up_rounded,
                      bgColor: const Color(0xFF181B2F),
                      iconColor: const Color(0xFFF59E0B),
                      onTap: () {
                        // Navigate to Unpaid Members list
                        _showUnpaidMembers(context, dash.unpaidMembers);
                      },
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _ReactStatCard(
                      title: 'Active Loans (${dash.activeLoans})',
                      value: fmt.format(dash.outstandingAmount),
                      subtitle: 'Outstanding Repayment',
                      icon: Icons.credit_card_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: _ReactStatCard(
                      title: 'Penalty Collected',
                      value: fmt.format(dash.totalPenaltyCollected),
                      subtitle: 'Total Late Fees',
                      icon: Icons.show_chart_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _ReactStatCard(
                      title: 'Profit from Loans',
                      value: fmt.format(dash.totalLoanProfit),
                      subtitle: 'Additional Revenue',
                      icon: Icons.emoji_events_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ],
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
                    color: context.colors.warning,
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
                    color: context.colors.primary,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              if (ref.read(authProvider).role != 'Auditor') ...[
                // ── Quick Actions ──────────────────────
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.payments_rounded,
                        label: 'Collect Cash',
                        color: const Color(0xFF2ECC71),
                        onTap: () async {
                          final result = await context.push<bool>('/admin/collect-cash');
                          if (result == true) ref.invalidate(adminDashboardProvider);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.person_add_rounded,
                        label: 'Add Member',
                        color: context.colors.primary,
                        onTap: () => context.push('/admin/members/add'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.receipt_long_rounded,
                        label: 'Expenses',
                        color: Colors.orange,
                        onTap: () => context.push('/admin/expenses'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.book_rounded,
                        label: 'Full Ledger',
                        color: Colors.purple,
                        onTap: () => context.push('/admin/ledger'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.exit_to_app_rounded,
                        label: 'Leave Requests',
                        color: Colors.redAccent,
                        onTap: () => context.push('/admin/leave-requests'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Adjust Ledger',
                        color: Colors.blueAccent,
                        onTap: () => context.push('/admin/adjust-ledger'),
                      ),
                    ),
                  ],
                ),
              ],

            ],
          ),
        ),
      ),
    );
  }

  void _showUnpaidMembers(BuildContext context, List<dynamic> unpaidMembers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Unpaid Members',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.colors.textDark)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${unpaidMembers.length} member${unpaidMembers.length == 1 ? '' : 's'} have not paid this month',
                  style: TextStyle(color: context.colors.textGrey, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: unpaidMembers.isEmpty
                    ? Center(child: Text('Everyone has paid!', style: TextStyle(color: context.colors.textGrey)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: unpaidMembers.length,
                        separatorBuilder: (_, __) => Divider(height: 1, indent: 56, color: context.colors.divider),
                        itemBuilder: (_, i) {
                          final m = unpaidMembers[i];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: context.colors.error.withValues(alpha: 0.1),
                              child: Text(
                                m.fullName[0].toUpperCase(),
                                style: TextStyle(color: context.colors.error, fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ),
                            title: Text(m.fullName,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textDark)),
                            subtitle: Text(m.phone, style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.push('/admin/collect-cash');
                              },
                              child: const Text('Collect'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── React-style Stat Card ──────────────────────────────────────────
class _ReactStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? bgColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;

  const _ReactStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.bgColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = gradient != null || (bgColor != null && bgColor != context.colors.surfaceWhite);
    final textColor = isDark ? Colors.white : context.colors.textDark;
    final subTextColor = isDark ? Colors.white70 : context.colors.textGrey;
    final iconFgColor = isDark ? (iconColor ?? Colors.white) : (iconColor ?? context.colors.primary);

    return AnimatedPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: gradient == null ? (bgColor ?? context.colors.surfaceWhite) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          border: gradient == null ? Border.all(color: context.colors.divider) : null,
          boxShadow: gradient != null ? [
            BoxShadow(
              color: gradient!.colors.last.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconFgColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : textColor
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: subTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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

// ── Quick action card ──────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AnimatedPressable(
        onTap: onTap,
        scale: 0.96,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.divider),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      color: context.colors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
      );
}

