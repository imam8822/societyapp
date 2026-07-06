import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/dashboard_models.dart';
import '../../models/contribution_models.dart';
import '../../widgets/network_error_widget.dart';
import '../../core/api/api_services.dart';
import '../../core/api/api_client.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(userDashboardProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(
        backgroundColor: context.colors.bgGrey,
        foregroundColor: context.colors.textDark,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.divider,
              shape: BoxShape.circle,
              image: dashAsync.valueOrNull?.logoBase64 != null
                  ? DecorationImage(
                      image: MemoryImage(
                        base64Decode(dashAsync.valueOrNull!.logoBase64!.contains(',')
                            ? dashAsync.valueOrNull!.logoBase64!.split(',')[1]
                            : dashAsync.valueOrNull!.logoBase64!),
                      ),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: dashAsync.valueOrNull?.logoBase64 == null ? Center(
              child: Text(
                dashAsync.valueOrNull?.fullName.isNotEmpty == true
                    ? dashAsync.valueOrNull!.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: context.colors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ) : null,
          ),
        ),
        title: Text(
          _currentIndex == 0
              ? (dashAsync.valueOrNull?.societyName ?? '')
              : _currentIndex == 1
                  ? 'Contribution History'
                  : 'My Profile',
          style: TextStyle(
            color: context.colors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notifs = ref.watch(notificationsProvider).valueOrNull ?? [];
              final unreadCount = notifs.where((n) => !n.isRead).length;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: context.colors.textDark),
                    onPressed: () {
                      context.push('/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: context.colors.textDark,
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
          Consumer(
            builder: (context, ref, child) {
              final role = ref.watch(authProvider).role;
              if (role == 'Admin' || role == 'SuperAdmin' || role == 'Auditor') {
                return IconButton(
                  icon: Icon(Icons.admin_panel_settings_outlined, color: context.colors.textDark),
                  tooltip: 'Switch to Admin View',
                  onPressed: () => context.go('/admin'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: Icon(Icons.power_settings_new, color: context.colors.textDark),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Builder(
        key: ValueKey(_currentIndex),
        builder: (context) {
          switch (_currentIndex) {
            case 0:
              return _buildDashboard(dashAsync, fmt, now);
            case 1:
              return _buildHistory();
            case 2:
            default:
              return _buildProfile();
          }
        },
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: context.colors.surfaceWhite,
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
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(AsyncValue<UserDashboard> dashAsync, NumberFormat fmt, DateTime now) {
    return dashAsync.when(
      loading: () => const ShimmerListLoader(count: 6),
      error: (e, _) => NetworkErrorWidget(
          error: e,
          onRetry: () => ref.invalidate(userDashboardProvider)),
      data: (dash) => RefreshIndicator(
        color: context.colors.primary,
        onRefresh: () async => ref.invalidate(userDashboardProvider),
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // ── Greeting Header ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(color: context.colors.textGrey, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      dash.fullName,
                      style: TextStyle(
                        color: context.colors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13271F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF2ECC71), size: 14),
                      SizedBox(width: 4),
                      Text('Secure', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),

            // ── HDFC Style Account Card ───────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primary,
                    context.colors.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invested Balance',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _currentIndex = 1),
                          child: const Text(
                            'Statement',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          fmt.format(dash.totalInvested),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        _buildAccountTabItem(
                          Icons.credit_card_outlined,
                          'Dues Status',
                          dash.currentMonthPaid ? 'Paid' : 'Pending',
                          dash.currentMonthPaid ? const Color(0xFF2ECC71) : const Color(0xFFFFB3B3),
                          Colors.white,
                        ),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                        _buildAccountTabItem(
                          Icons.account_balance_outlined,
                          'Deposits',
                          fmt.format(dash.totalInvested),
                          Colors.white,
                          Colors.white,
                        ),
                        Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
                        _buildAccountTabItem(
                          Icons.currency_rupee_rounded,
                          'Loans',
                          dash.activeLoan != null ? fmt.format(dash.activeLoan!.outstandingAmount) : '₹0',
                          Colors.white,
                          Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14),

            // ── Pay June Contribution 1-Click Banner ──
            if (!dash.currentMonthPaid)
              Builder(builder: (context) {
                final hasPendingReview = dash.recentContributions.any((c) => !c.isVerified);
                return Column(
                  children: [
                    AnimatedPressable(
                      onTap: hasPendingReview ? null : () => context.push('/pay'),
                      scale: hasPendingReview ? 1.0 : 0.97,
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            if (!hasPendingReview)
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.colors.textDark.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(hasPendingReview ? Icons.hourglass_empty_rounded : Icons.flash_on, color: Colors.yellow, size: 24),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hasPendingReview ? 'Payment under review' : 'Monthly contribution pending',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    hasPendingReview ? 'Admin is verifying your screenshot' : 'Tap to pay ₹${dash.pendingAmount.toStringAsFixed(0)} via UPI',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!hasPendingReview)
                              Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                );
              }),



            // ── Active Loan ───────────────────────
            if (dash.activeLoan != null) ...[
              const SectionHeader(title: 'Active Loan'),
              SizedBox(height: 10),
              _LoanCard(loan: dash.activeLoan!),
              SizedBox(height: 16),
            ],

            // ── Quick Actions Grid ────────────────
            const SectionHeader(title: 'Quick Actions'),
            SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickActionTile(
                  icon: Icons.history_rounded,
                  label: 'Statement',
                  color: const Color(0xFFF59E0B),
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _buildQuickActionTile(
                  icon: Icons.account_balance_rounded,
                  label: dash.activeLoan == null ? 'Apply Loan' : 'Loan Status',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    if (dash.activeLoan == null) {
                      if (dash.hasRepaidLoanThisMonth) {
                        AppUtils.showError(context, 'You have already repaid a loan this month. You cannot apply for a new loan until next month.');
                        return;
                      }
                      if (dash.unpaidMonthsCount > 2) {
                        AppUtils.showError(context, 'You have ${dash.unpaidMonthsCount} unpaid monthly contributions. Clear your dues to apply.');
                        return;
                      }
                      context.push('/loan/apply');
                    } else {
                      context.push('/loan/status');
                    }
                  },
                ),
                _buildQuickActionTile(
                  icon: Icons.people_outline_rounded,
                  label: 'Guarantor Req',
                  color: const Color(0xFF3B82F6),
                  onTap: () => context.push('/loan/guarantor-requests'),
                ),
              ],
            ),
            SizedBox(height: 24),

            // ── Recent Transactions ───────────────
            SectionHeader(
              title: 'Recent Transactions',
              actionLabel: 'View All',
              onAction: () => setState(() => _currentIndex = 1),
            ),
            SizedBox(height: 10),
            if (dash.recentContributions.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No contributions yet',
              )
            else
              ...dash.recentContributions
                  .asMap()
                  .entries
                  .map((e) => FadeSlideIn(
                        delay: Duration(milliseconds: 60 * e.key),
                        child: _ContributionTile(c: e.value),
                      )),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTabItem(IconData icon, String label, String value, Color valueColor, [Color? textColor]) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: textColor ?? context.colors.textGrey, size: 18),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: textColor ?? context.colors.textGrey, fontSize: 10),
          ),
          SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedPressable(
      onTap: onTap,
      scale: 0.94,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.divider),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: context.colors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    final contribAsync = ref.watch(myContributionsProvider);
    return Container(
      color: context.colors.bgGrey,
      child: contribAsync.when(
        loading: () => const ShimmerListLoader(count: 8),
        error: (e, _) => NetworkErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(myContributionsProvider)),
        data: (list) => RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () async => ref.invalidate(myContributionsProvider),
          child: list.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No contributions yet',
                  subtitle: 'Your monthly payments will appear here')
              : ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8),
                  itemBuilder: (_, i) => FadeSlideIn(
                        delay: Duration(milliseconds: 50 * i),
                        child: _ContributionHistoryCard(c: list[i]),
                      ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final profileAsync = ref.watch(myProfileProvider);
    final dashAsync = ref.watch(userDashboardProvider);
    final hasPendingLeaveRequest = dashAsync.valueOrNull?.hasPendingLeaveRequest ?? false;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      color: context.colors.bgGrey,
      child: profileAsync.when(
        loading: () => const ShimmerListLoader(count: 6),
        error: (e, _) => NetworkErrorWidget(
            error: e,
            onRetry: () => ref.invalidate(myProfileProvider)),
        data: (profile) => RefreshIndicator(
          color: context.colors.primary,
          onRefresh: () async {
            ref.invalidate(myProfileProvider);
            ref.invalidate(userDashboardProvider);
          },
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: context.colors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: context.colors.textDark,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      profile.fullName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.divider,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Member since ${DateFormat('MMM yyyy').format(profile.joinedDate)}',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              const SectionHeader(title: 'Financial Summary'),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DarkStatCard(
                      label: 'Total Invested',
                      value: fmt.format(profile.totalInvested),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _DarkStatCard(
                      label: 'Contributions',
                      value: '${profile.totalContributions} months',
                      icon: Icons.assignment_turned_in_outlined,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              const SectionHeader(title: 'Personal Details'),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileRow(Icons.phone_outlined, 'Phone Number', profile.phone),
                      Divider(color: context.colors.divider, height: 24),
                      _buildProfileRow(Icons.email_outlined, 'Email Address', profile.email.isNotEmpty ? profile.email : 'Not Provided'),
                      Divider(color: context.colors.divider, height: 24),
                      _buildProfileRow(Icons.shield_outlined, 'Account Role', profile.role),
                      if (profile.referredByName != null && profile.referredByName!.isNotEmpty) ...[
                        Divider(color: context.colors.divider, height: 24),
                        _buildProfileRow(Icons.person_add_alt_1_outlined, 'Referred By', profile.referredByName!),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              const SectionHeader(title: 'App Theme'),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final currentTheme = ref.watch(themeProvider);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ThemeOption(
                            label: 'System',
                            icon: Icons.brightness_auto,
                            isSelected: currentTheme == ThemeMode.system,
                            onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                          ),
                          _ThemeOption(
                            label: 'Light',
                            icon: Icons.light_mode,
                            isSelected: currentTheme == ThemeMode.light,
                            onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                          ),
                          _ThemeOption(
                            label: 'Dark',
                            icon: Icons.dark_mode,
                            isSelected: currentTheme == ThemeMode.dark,
                            onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                          ),
                        ],
                      );
                    }
                  ),
                ),
              ),
              SizedBox(height: 24),
              const SectionHeader(title: 'Account Actions'),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.divider),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: hasPendingLeaveRequest ? null : () => _showLeaveSocietyDialog(context),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: hasPendingLeaveRequest ? Colors.grey.withValues(alpha: 0.15) : const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(hasPendingLeaveRequest ? Icons.hourglass_empty_rounded : Icons.exit_to_app_rounded, color: hasPendingLeaveRequest ? Colors.grey : Color(0xFFEF4444), size: 20),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasPendingLeaveRequest ? 'Leave Request Pending' : 'Leave Society',
                                  style: TextStyle(
                                    color: hasPendingLeaveRequest ? Colors.grey : Color(0xFFEF4444),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  hasPendingLeaveRequest ? 'Awaiting admin approval' : 'Apply to resign and withdraw funds',
                                  style: TextStyle(
                                    color: context.colors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!hasPendingLeaveRequest) Icon(Icons.chevron_right_rounded, color: context.colors.textGrey),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.colors.divider,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.colors.textGrey, size: 20),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.colors.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: context.colors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLeaveSocietyDialog(BuildContext context) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: context.colors.surfaceWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Leave Society', style: TextStyle(color: context.colors.textDark)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to leave the society? Your total invested amount will be refunded upon admin approval.',
                  style: TextStyle(color: context.colors.textGrey, fontSize: 14),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: TextStyle(color: context.colors.textDark),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Please enter a reason for leaving...',
                    hintStyle: TextStyle(color: context.colors.textDark.withValues(alpha: 0.38)),
                    filled: true,
                    fillColor: context.colors.bgGrey,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: context.colors.textGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: context.colors.textDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSubmitting ? null : () async {
                  if (reasonController.text.trim().isEmpty) {
                    AppUtils.showError(context, 'Please enter a reason.');
                    return;
                  }
                  setState(() => isSubmitting = true);
                  try {
                    await UserApi.submitLeaveRequest(reasonController.text.trim());
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ref.invalidate(userDashboardProvider);
                      AppUtils.showSuccess(context, 'Leave request submitted successfully. Waiting for admin approval.');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppUtils.showError(context, apiError(e));
                    }
                  } finally {
                    if (context.mounted) {
                      setState(() => isSubmitting = false);
                    }
                  }
                },
                child: isSubmitting
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textDark))
                    : Text('Submit Request'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PayNowBanner extends StatelessWidget {
  final double pendingAmount;
  final double monthlyRate;
  const _PayNowBanner(
      {required this.pendingAmount, required this.monthlyRate});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    // Show pending amount if more than one month due, else show monthly rate
    final displayAmount = pendingAmount > 0 ? pendingAmount : monthlyRate;

    return GestureDetector(
      onTap: () => context.push('/pay'),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF261D15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF452C16)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.payment_rounded,
                  color: Color(0xFFF97316), size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly contribution pending',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.colors.textDark,
                          fontSize: 14)),
                  SizedBox(height: 2),
                  Text('Tap to pay ${fmt.format(displayAmount)} via UPI',
                      style: TextStyle(
                          color: context.colors.textGrey, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.colors.textGrey),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.colors.primary : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? context.colors.primary : context.colors.textGrey,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? context.colors.primary : context.colors.textGrey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final dynamic loan;
  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/loan/status'),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Outstanding',
                          style: TextStyle(
                              color: context.colors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      SizedBox(height: 4),
                      Text(fmt.format(loan.outstandingAmount),
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: context.colors.textDark)),
                      SizedBox(height: 16),
                      if (loan.repaymentDueDate != null) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: Color(0xFFF59E0B), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Due: ${DateFormat('d MMM yyyy').format(loan.repaymentDueDate!)}',
                                style: TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loan.status,
                    style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
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

class _ContributionTile extends StatelessWidget {
  final dynamic c;
  const _ContributionTile({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Future expansion
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.isVerified
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    c.isVerified
                        ? Icons.check_circle_rounded
                        : Icons.schedule_rounded,
                    color: c.isVerified
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.monthName,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: context.colors.textDark)),
                      SizedBox(height: 2),
                      Text(c.mode,
                          style: TextStyle(
                              color: context.colors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${c.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: context.colors.textDark)),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.isVerified
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        c.isVerified ? 'Verified' : 'Pending',
                        style: TextStyle(
                            color: c.isVerified
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContributionHistoryCard extends StatelessWidget {
  final Contribution c;
  const _ContributionHistoryCard({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.monthName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: context.colors.textDark)),
                    SizedBox(height: 2),
                    Text(DateFormat('d MMM yyyy').format(c.paidDate),
                        style: TextStyle(
                            color: context.colors.textGrey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${c.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: context.colors.textDark)),
                  SizedBox(height: 4),
                  StatusBadge(status: c.isVerified ? 'Verified' : 'Pending'),
                ],
              ),
            ],
          ),
          if (c.transactionReference != null || c.mode == 'Online') ...[
            Divider(height: 20, color: context.colors.divider),
            Row(
              children: [
                Icon(Icons.tag_rounded,
                    size: 14, color: context.colors.textGrey),
                SizedBox(width: 4),
                Text(c.transactionReference ?? '-',
                    style: TextStyle(
                        color: context.colors.textGrey, fontSize: 12)),
                const Spacer(),
                Text(c.mode,
                    style: TextStyle(
                        color: context.colors.textGrey, fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DarkStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _DarkStatCard({
    required this.label,
    required this.value,
    required this.icon,
  }) : iconColor = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? context.colors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? context.colors.primary,
              size: 20,
            ),
          ),
          SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textDark,
              ),
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: context.colors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

