import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/dashboard_models.dart';
import '../../models/contribution_models.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen> {
  int _currentIndex = 0;
  bool _showBalance = false;

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(userDashboardProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();    return Scaffold(
      backgroundColor: const Color(0xFF0C0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0E1A),
        foregroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E213F),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                dashAsync.valueOrNull?.fullName.isNotEmpty == true
                    ? dashAsync.valueOrNull!.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          _currentIndex == 0
              ? (dashAsync.valueOrNull?.societyName ?? '')
              : _currentIndex == 1
                  ? 'Contribution History'
                  : 'My Profile',
          style: const TextStyle(
            color: Colors.white,
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
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
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
      error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(userDashboardProvider)),
      data: (dash) => RefreshIndicator(
        color: const Color(0xFFC084FC),
        onRefresh: () async => ref.invalidate(userDashboardProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Greeting Header ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(color: Color(0xFF9094B6), fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dash.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 14),

            // ── HDFC Style Account Card ───────────
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C1E32), Color(0xFF111322)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF282C4A)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Invested Balance',
                          style: TextStyle(
                            color: Color(0xFF9094B6),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _currentIndex = 1),
                          child: const Text(
                            'Statement',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 350),
                          crossFadeState: _showBalance
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const Text(
                            '\u2022\u2022\u2022\u2022\u2022\u2022',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                          secondChild: Text(
                            fmt.format(dash.totalInvested),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _showBalance ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF9094B6),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _showBalance = !_showBalance;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF282C4A), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildAccountTabItem(
                          Icons.credit_card_outlined,
                          'Dues Status',
                          dash.currentMonthPaid ? 'Paid' : 'Pending',
                          dash.currentMonthPaid ? const Color(0xFF2ECC71) : const Color(0xFFEF4444),
                        ),
                        _buildAccountTabItem(
                          Icons.account_balance_outlined,
                          'Deposits',
                          fmt.format(dash.totalInvested),
                          Colors.white,
                        ),
                        _buildAccountTabItem(
                          Icons.monetization_on_outlined,
                          'Loans',
                          dash.activeLoan != null ? fmt.format(dash.activeLoan!.outstandingAmount) : '₹0',
                          Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Pay June Contribution 1-Click Banner ──
            if (!dash.currentMonthPaid) ...[
              AnimatedPressable(
                onTap: () => context.push('/pay'),
                scale: 0.97,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flash_on, color: Colors.yellow, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monthly contribution pending',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to pay ₹${dash.pendingAmount.toStringAsFixed(0)} via UPI',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],



            // ── Active Loan ───────────────────────
            if (dash.activeLoan != null) ...[
              const SectionHeader(title: 'Active Loan'),
              const SizedBox(height: 10),
              _LoanCard(loan: dash.activeLoan!),
              const SizedBox(height: 16),
            ],

            // ── Quick Actions Grid ────────────────
            const SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 10),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You have already repaid a loan this month. You cannot apply for a new loan until next month.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (dash.unpaidMonthsCount > 2) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You have ${dash.unpaidMonthsCount} unpaid monthly contributions. Clear your dues to apply.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      context.push('/loan/apply');
                    } else {
                      context.push('/loan/status');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Recent Transactions ───────────────
            SectionHeader(
              title: 'Recent Transactions',
              actionLabel: 'View All',
              onAction: () => setState(() => _currentIndex = 1),
            ),
            const SizedBox(height: 10),
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

  Widget _buildAccountTabItem(IconData icon, String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF9094B6), size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9094B6), fontSize: 10),
          ),
          const SizedBox(height: 2),
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
          color: const Color(0xFF181B2F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF282C4A)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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
      color: const Color(0xFF0C0E1A),
      child: contribAsync.when(
        loading: () => const ShimmerListLoader(count: 8),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(myContributionsProvider)),
        data: (list) => RefreshIndicator(
          color: const Color(0xFFC084FC),
          onRefresh: () async => ref.invalidate(myContributionsProvider),
          child: list.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No contributions yet',
                  subtitle: 'Your monthly payments will appear here')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      color: const Color(0xFF0C0E1A),
      child: profileAsync.when(
        loading: () => const ShimmerListLoader(count: 6),
        error: (e, _) => ErrorRetry(
            message: e.toString(),
            onRetry: () => ref.invalidate(myProfileProvider)),
        data: (profile) => RefreshIndicator(
          color: const Color(0xFFC084FC),
          onRefresh: () async => ref.invalidate(myProfileProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E213F),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E213F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Member since ${DateFormat('MMM yyyy').format(profile.joinedDate)}',
                        style: const TextStyle(
                          color: Color(0xFFC084FC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const SectionHeader(title: 'Financial Summary'),
              const SizedBox(height: 12),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DarkStatCard(
                          label: 'Total Invested',
                          value: fmt.format(profile.totalInvested),
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DarkStatCard(
                          label: 'Contributions',
                          value: '${profile.totalContributions} months',
                          icon: Icons.assignment_turned_in_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DarkStatCard(
                          label: 'Pending Dues',
                          value: fmt.format(profile.pendingAmount),
                          icon: Icons.error_outline_rounded,
                          iconColor: profile.pendingAmount > 0 ? Colors.red : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const SectionHeader(title: 'Personal Details'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF181B2F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF282C4A)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileRow(Icons.phone_outlined, 'Phone Number', profile.phone),
                      const Divider(color: Color(0xFF282C4A), height: 24),
                      _buildProfileRow(Icons.email_outlined, 'Email Address', profile.email.isNotEmpty ? profile.email : 'Not Provided'),
                      const Divider(color: Color(0xFF282C4A), height: 24),
                      _buildProfileRow(Icons.shield_outlined, 'Account Role', profile.role),
                      if (profile.referredByName != null && profile.referredByName!.isNotEmpty) ...[
                        const Divider(color: Color(0xFF282C4A), height: 24),
                        _buildProfileRow(Icons.person_add_alt_1_outlined, 'Referred By', profile.referredByName!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E213F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9094B6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF261D15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF452C16)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payment_rounded,
                  color: Color(0xFFF97316), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly contribution pending',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Tap to pay ${fmt.format(displayAmount)} via UPI',
                      style: const TextStyle(
                          color: Color(0xFF9094B6), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF9094B6)),
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
        color: const Color(0xFF181B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282C4A)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/loan/status'),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Outstanding',
                          style: TextStyle(
                              color: Color(0xFF9094B6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(fmt.format(loan.outstandingAmount),
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: Colors.white)),
                      const SizedBox(height: 16),
                      if (loan.repaymentDueDate != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: Color(0xFFF59E0B), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Due: ${DateFormat('d MMM yyyy').format(loan.repaymentDueDate!)}',
                                style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    loan.status,
                    style: const TextStyle(
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282C4A)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {}, // Future expansion
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.monthName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(c.mode,
                          style: const TextStyle(
                              color: Color(0xFF9094B6),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${c.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282C4A)),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(DateFormat('d MMM yyyy').format(c.paidDate),
                        style: const TextStyle(
                            color: Color(0xFF9094B6), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${c.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  StatusBadge(status: c.isVerified ? 'Verified' : 'Pending'),
                ],
              ),
            ],
          ),
          if (c.transactionReference != null || c.mode == 'Online') ...[
            const Divider(height: 20, color: Color(0xFF282C4A)),
            Row(
              children: [
                const Icon(Icons.tag_rounded,
                    size: 14, color: Color(0xFF9094B6)),
                const SizedBox(width: 4),
                Text(c.transactionReference ?? '-',
                    style: const TextStyle(
                        color: Color(0xFF9094B6), fontSize: 12)),
                const Spacer(),
                Text(c.mode,
                    style: const TextStyle(
                        color: Color(0xFF9094B6), fontSize: 12)),
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
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181B2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF282C4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFFC084FC)).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFFC084FC),
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9094B6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}