import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/user_models.dart';
import 'edit_member_sheet.dart';

class MemberDetailScreen extends StatefulWidget {
  final UserSummary member;
  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late UserSummary _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  void _openEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditMemberSheet(
        member: _member,
        onSaved: () {
          Navigator.pop(context, true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit Member',
                onPressed: _openEdit,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF2ECC71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white24,
                        child: Text(
                          _member.fullName[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _member.fullName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_member.phone,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        if (_member.role == 'Admin') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text('Admin',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [

                // ── Top 3 stat boxes ─────────────────────
                Row(children: [
                  _StatBox(
                      label: 'Total Invested',
                      value: fmt.format(_member.totalInvested),
                      color: AppTheme.primary),
                  const SizedBox(width: 10),
                  _StatBox(
                      label: 'Months Paid',
                      value: '${_member.totalContributions}',
                      color: const Color(0xFF2ECC71)),
                  const SizedBox(width: 10),
                  _StatBox(
                    label: 'Pending',
                    value: fmt.format(_member.pendingAmount),
                    color: _member.pendingAmount > 0
                        ? AppTheme.error
                        : const Color(0xFF2ECC71),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── Personal ─────────────────────────────
                _Section(title: 'Personal Details', rows: [
                  _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Mobile',
                      value: _member.phone),
                  if (_member.email.isNotEmpty &&
                      !_member.email.contains('@society.app'))
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: _member.email),
                  _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Joined',
                      value: dateFmt.format(_member.joinedDate)),
                  if (_member.referredByName != null)
                    _InfoRow(
                        icon: Icons.person_add_outlined,
                        label: 'Referred By',
                        value: _member.referredByName!),
                  _InfoRow(
                    icon: _member.isActive
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    label: 'Status',
                    value: _member.isActive ? 'Active' : 'Inactive',
                    valueColor: _member.isActive
                        ? const Color(0xFF2ECC71)
                        : AppTheme.error,
                  ),
                ]),
                const SizedBox(height: 14),

                // ── Investment ───────────────────────────
                _Section(title: 'Investment Details', rows: [
                  _InfoRow(
                      icon: Icons.savings_outlined,
                      label: 'Pre-existing',
                      value: fmt.format(_member.preExistingInvestment)),
                  _InfoRow(
                      icon: Icons.add_card_outlined,
                      label: 'Paid via App',
                      value: fmt.format(_member.totalContributed)),
                  _InfoRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Total Invested',
                      value: fmt.format(_member.totalInvested),
                      bold: true),
                  if (_member.pendingAmount > 0)
                    _InfoRow(
                        icon: Icons.warning_amber_outlined,
                        label: 'Pending',
                        value: fmt.format(_member.pendingAmount),
                        valueColor: AppTheme.error,
                        bold: true),
                ]),
                const SizedBox(height: 14),

                // ── Loan ─────────────────────────────────
                _Section(title: 'Loan Status', rows: [
                  _InfoRow(
                    icon: Icons.verified_outlined,
                    label: 'Loan Eligible',
                    value: _member.isEligibleForLoan ? 'Yes' : 'Not yet',
                    valueColor: _member.isEligibleForLoan
                        ? const Color(0xFF2ECC71)
                        : AppTheme.textGrey,
                  ),
                  if (_member.hasActiveLoan) ...[
                    _InfoRow(
                        icon: Icons.monetization_on_outlined,
                        label: 'Active Loan',
                        value: fmt.format(_member.activeLoanAmount),
                        valueColor: AppTheme.primary),
                    _InfoRow(
                        icon: Icons.pending_outlined,
                        label: 'To Repay',
                        value: fmt.format(_member.loanAmountToRepay),
                        valueColor: AppTheme.error),
                    if (_member.nextInstallmentDueDate != null)
                      _InfoRow(
                          icon: Icons.event_outlined,
                          label: 'Next Installment',
                          value:
                              '${fmt.format(_member.nextInstallmentAmount)} · '
                              '${dateFmt.format(_member.nextInstallmentDueDate!)}'),
                  ] else
                    const _InfoRow(
                        icon: Icons.check_circle_outline,
                        label: 'Active Loan',
                        value: 'None'),
                ]),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ───────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textGrey),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGrey,
                  letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...rows,
        ]),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  final bool bold;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor,
      this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Icon(icon, size: 18, color: AppTheme.textGrey),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textGrey, fontSize: 13)),
          const Spacer(),
          Expanded(  // ← was Flexible, now Expanded to force right alignment
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? AppTheme.textDark,
              ),
            ),
          ),
        ]),
      );
}