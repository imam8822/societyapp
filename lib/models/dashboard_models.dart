import 'loan_models.dart';
import 'contribution_models.dart';

class UserDashboard {
  final int userId;
  final String fullName;
  final double monthlyContributionAmount;
  final int totalContributions;
  final double totalInvested;
  final double pendingAmount;
  final int unpaidMonthsCount;
  final bool currentMonthPaid;
  final bool isEligibleForLoan;
  final bool hasRepaidLoanThisMonth;
  final bool guarantorRequired;
  final bool hasPendingLeaveRequest;
  final String societyName;
  final String? logoBase64;
  final LoanApplication? activeLoan;
  final List<Contribution> recentContributions;

  UserDashboard({
    required this.userId,
    required this.fullName,
    required this.monthlyContributionAmount,
    required this.totalContributions,
    required this.totalInvested,
    required this.pendingAmount,
    required this.unpaidMonthsCount,
    required this.currentMonthPaid,
    required this.isEligibleForLoan,
    required this.hasRepaidLoanThisMonth,
    required this.guarantorRequired,
    required this.hasPendingLeaveRequest,
    required this.societyName,
    this.logoBase64,
    this.activeLoan,
    required this.recentContributions,
  });

  factory UserDashboard.fromJson(Map<String, dynamic> j) => UserDashboard(
        userId: j['userId'] ?? 0,
        fullName: j['fullName'] ?? '',
        monthlyContributionAmount: (j['monthlyContributionAmount'] as num?)?.toDouble() ?? 500,
        totalContributions: j['totalContributions'] ?? 0,
        totalInvested: (j['totalInvested'] as num?)?.toDouble() ?? 0,
        pendingAmount: (j['pendingAmount'] as num?)?.toDouble() ?? 0,
        unpaidMonthsCount: j['unpaidMonthsCount'] ?? 0,
        currentMonthPaid: j['currentMonthPaid'] ?? false,
        isEligibleForLoan: j['isEligibleForLoan'] ?? false,
        hasRepaidLoanThisMonth: j['hasRepaidLoanThisMonth'] ?? false,
        guarantorRequired: j['guarantorRequired'] ?? true,
        hasPendingLeaveRequest: j['hasPendingLeaveRequest'] ?? false,
        societyName: j['societyName'] ?? 'My Society',
        logoBase64: j['logoBase64'],
        activeLoan: j['activeLoan'] != null
            ? LoanApplication.fromJson(j['activeLoan']) : null,
        recentContributions: (j['recentContributions'] as List? ?? [])
            .map((e) => Contribution.fromJson(e)).toList(),
      );
}

class AdminDashboard {
  final String? logoBase64;
  final int totalMembers;
  final int activeMembers;
  final double totalCollected;    // renamed from totalPoolAmount
  final double totalDisbursed;
  final double balance;           // new
  final int pendingLoanApplications;
  final int loansAwaitingDisbursement;
  final int activeLoans;
  final double totalRepaid;
  final double outstandingAmount;
  final int currentMonthPaidCount;
  final int currentMonthUnpaidCount;
  final int pendingScreenshotReviews;
  final List<LoanApplication> pendingLoans;
  final List<LoanApplication> loansToDisburse;
  final double totalPenaltyCollected;
  final double totalLoanProfit;
  final double totalAdjustments;
  final double totalRefunds;
  final double totalExpenses;
  final List<dynamic> unpaidMembers;

  AdminDashboard({
    this.logoBase64,
    required this.totalMembers,
    required this.activeMembers,
    required this.totalCollected,
    required this.totalDisbursed,
    required this.balance,
    required this.pendingLoanApplications,
    required this.loansAwaitingDisbursement,
    required this.activeLoans,
    required this.totalRepaid,
    required this.outstandingAmount,
    required this.currentMonthPaidCount,
    required this.currentMonthUnpaidCount,
    required this.pendingScreenshotReviews,
    required this.pendingLoans,
    required this.loansToDisburse,
    required this.totalPenaltyCollected,
    required this.totalLoanProfit,
    required this.totalAdjustments,
    required this.totalRefunds,
    required this.totalExpenses,
    required this.unpaidMembers,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> j) => AdminDashboard(
        logoBase64: j['logoBase64'],
        totalMembers: j['totalMembers'] ?? 0,
        activeMembers: j['activeMembers'] ?? 0,
        totalCollected: (j['totalCollected'] as num?)?.toDouble() ?? 0,
        totalDisbursed: (j['totalDisbursed'] as num?)?.toDouble() ?? 0,
        balance: (j['balance'] as num?)?.toDouble() ?? 0,
        pendingLoanApplications: j['pendingLoanApplications'] ?? 0,
        loansAwaitingDisbursement: j['loansAwaitingDisbursement'] ?? 0,
        activeLoans: j['activeLoans'] ?? 0,
        totalRepaid: (j['totalRepaid'] as num?)?.toDouble() ?? 0,
        outstandingAmount: (j['outstandingAmount'] as num?)?.toDouble() ?? 0,
        currentMonthPaidCount: j['currentMonthPaidCount'] ?? 0,
        currentMonthUnpaidCount: j['currentMonthUnpaidCount'] ?? 0,
        pendingScreenshotReviews: j['pendingScreenshotReviews'] ?? 0,
        pendingLoans: (j['pendingLoans'] as List? ?? [])
            .map((e) => LoanApplication.fromJson(e)).toList(),
        loansToDisburse: (j['loansToDisburse'] as List? ?? [])
            .map((e) => LoanApplication.fromJson(e)).toList(),
        totalPenaltyCollected: (j['totalPenaltyCollected'] as num?)?.toDouble() ?? 0,
        totalLoanProfit: (j['totalLoanProfit'] as num?)?.toDouble() ?? 0,
        totalAdjustments: (j['totalAdjustments'] as num?)?.toDouble() ?? 0,
        totalRefunds: (j['totalRefunds'] as num?)?.toDouble() ?? 0,
        totalExpenses: (j['totalExpenses'] as num?)?.toDouble() ?? 0,
        unpaidMembers: j['unpaidMembers'] ?? [],
      );
}