import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/shared_widgets.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(userDashboardProvider);
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: const Text('My Society'),
        actions: [
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
            onRetry: () => ref.invalidate(userDashboardProvider)),
        data: (dash) => RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async => ref.invalidate(userDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Greeting ──────────────────────────
              Text('Hello, ${dash.fullName.split(' ').first} 👋',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Text(DateFormat('MMMM yyyy').format(now),
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textGrey)),
              const SizedBox(height: 20),

              // ── Total Invested card ────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF2ECC71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Invested',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(fmt.format(dash.totalInvested),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _pill('${dash.totalContributions} months paid'),
                        const SizedBox(width: 8),
                        _pill(dash.currentMonthPaid
                            ? '✓ This month paid'
                            : '! This month pending'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Pay This Month banner ──────────────
              if (!dash.currentMonthPaid)
                _PayNowBanner(
                  pendingAmount: dash.pendingAmount,
                  monthlyRate: dash.monthlyContributionAmount,
                ),

              if (!dash.currentMonthPaid) const SizedBox(height: 16),

              // ── Pending amount warning ─────────────
              if (dash.pendingAmount > 0 && dash.unpaidMonthsCount > 1) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppTheme.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${dash.unpaidMonthsCount} months pending — ${fmt.format(dash.pendingAmount)} due',
                          style: const TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w500,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Active Loan ────────────────────────
              if (dash.activeLoan != null) ...[
                const SectionHeader(title: 'Active Loan'),
                const SizedBox(height: 10),
                _LoanCard(loan: dash.activeLoan!),
                const SizedBox(height: 16),
              ],

              // ── Quick Actions ──────────────────────
              const SectionHeader(title: 'Quick Actions'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.history_rounded,
                      label: 'History',
                      onTap: () => context.push('/contributions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.account_balance_rounded,
                      label: dash.activeLoan == null
                          ? 'Apply Loan'
                          : 'Loan Status',
                      onTap: () {
                        if (dash.activeLoan == null) {
                          if (dash.hasRepaidLoanThisMonth) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You have already repaid a loan this month. You cannot apply for a new loan until next month.'),
                                backgroundColor: AppTheme.error,
                              ),
                            );
                            return;
                          }
                          if (dash.unpaidMonthsCount > 2) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('You have ${dash.unpaidMonthsCount} unpaid monthly contributions. Clear your dues to apply.'),
                                backgroundColor: AppTheme.error,
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
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Transactions ───────────────
              SectionHeader(
                title: 'Recent Transactions',
                actionLabel: 'View All',
                onAction: () => context.push('/contributions'),
              ),
              const SizedBox(height: 10),
              if (dash.recentContributions.isEmpty)
                const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No contributions yet')
              else
                ...dash.recentContributions
                    .map((c) => _ContributionTile(c: c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      );
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
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF97316).withOpacity(0.1),
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
                          color: AppTheme.textDark,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Tap to pay ${fmt.format(displayAmount)} via UPI',
                      style: const TextStyle(
                          color: AppTheme.textGrey, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textGrey),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
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
                    const Text('Current Balance', style: TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(fmt.format(loan.outstandingAmount),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 16),
                    if (loan.repaymentDueDate != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, color: AppTheme.warning, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Due: ${DateFormat('d MMM yyyy').format(loan.repaymentDueDate!)}',
                              style: const TextStyle(
                                  color: AppTheme.warning,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  loan.status,
                  style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primary, size: 28),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
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
                      ? AppTheme.accent.withOpacity(0.15)
                      : AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  c.isVerified
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  color: c.isVerified
                      ? AppTheme.accent
                      : AppTheme.warning,
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
                            color: AppTheme.textDark)),
                    const SizedBox(height: 2),
                    Text(c.mode,
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
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
                          color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.isVerified ? AppTheme.accent.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      c.isVerified ? 'Verified' : 'Pending',
                      style: TextStyle(
                          color: c.isVerified ? AppTheme.accent : AppTheme.warning,
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
    );
  }
}