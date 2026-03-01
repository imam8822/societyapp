import 'loan_models.dart';
import 'contribution_models.dart';

class UserDashboard {
  final int userId;
  final String fullName;
  final int totalContributions;
  final double totalInvested;
  final bool currentMonthPaid;
  final bool isEligibleForLoan;
  final bool guarantorRequired;
  final LoanApplication? activeLoan;
  final List<Contribution> recentContributions;

  UserDashboard({
    required this.userId,
    required this.fullName,
    required this.totalContributions,
    required this.totalInvested,
    required this.currentMonthPaid,
    required this.isEligibleForLoan,
    required this.guarantorRequired,
    this.activeLoan,
    required this.recentContributions,
  });

  factory UserDashboard.fromJson(Map<String, dynamic> j) => UserDashboard(
        userId: j['userId'],
        fullName: j['fullName'],
        totalContributions: j['totalContributions'],
        totalInvested: (j['totalInvested'] as num).toDouble(),
        currentMonthPaid: j['currentMonthPaid'],
        isEligibleForLoan: j['isEligibleForLoan'],
        guarantorRequired: j['guarantorRequired'],
        activeLoan: j['activeLoan'] != null
            ? LoanApplication.fromJson(j['activeLoan'])
            : null,
        recentContributions: (j['recentContributions'] as List)
            .map((e) => Contribution.fromJson(e))
            .toList(),
      );
}

class AdminDashboard {
  final int totalMembers;
  final int activeMembers;
  final double totalPoolAmount;
  final int pendingLoanApplications;
  final int loansAwaitingDisbursement;
  final int activeLoans;
  final double totalDisbursed;
  final double totalRepaid;
  final double outstandingAmount;
  final int currentMonthPaidCount;
  final int currentMonthUnpaidCount;
  final int pendingScreenshotReviews;
  final List<LoanApplication> pendingLoans;
  final List<LoanApplication> loansToDisburse;

  AdminDashboard({
    required this.totalMembers,
    required this.activeMembers,
    required this.totalPoolAmount,
    required this.pendingLoanApplications,
    required this.loansAwaitingDisbursement,
    required this.activeLoans,
    required this.totalDisbursed,
    required this.totalRepaid,
    required this.outstandingAmount,
    required this.currentMonthPaidCount,
    required this.currentMonthUnpaidCount,
    required this.pendingScreenshotReviews,
    required this.pendingLoans,
    required this.loansToDisburse,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> j) => AdminDashboard(
        totalMembers: j['totalMembers'],
        activeMembers: j['activeMembers'],
        totalPoolAmount: (j['totalPoolAmount'] as num).toDouble(),
        pendingLoanApplications: j['pendingLoanApplications'],
        loansAwaitingDisbursement: j['loansAwaitingDisbursement'],
        activeLoans: j['activeLoans'],
        totalDisbursed: (j['totalDisbursed'] as num).toDouble(),
        totalRepaid: (j['totalRepaid'] as num).toDouble(),
        outstandingAmount: (j['outstandingAmount'] as num).toDouble(),
        currentMonthPaidCount: j['currentMonthPaidCount'],
        currentMonthUnpaidCount: j['currentMonthUnpaidCount'],
        pendingScreenshotReviews: j['pendingScreenshotReviews'],
        pendingLoans: (j['pendingLoans'] as List)
            .map((e) => LoanApplication.fromJson(e))
            .toList(),
        loansToDisburse: (j['loansToDisburse'] as List)
            .map((e) => LoanApplication.fromJson(e))
            .toList(),
      );
}
