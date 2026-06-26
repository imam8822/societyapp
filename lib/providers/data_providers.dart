import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/core/api/api_services.dart';
import 'package:society_app/models/dashboard_models.dart';
import 'package:society_app/models/loan_models.dart';
import 'package:society_app/models/payment_models.dart';
import 'package:society_app/models/user_models.dart';
import 'package:society_app/models/app_notification.dart';
import 'package:society_app/models/contribution_models.dart';


// ─────────────────────────────────────────────
// User Dashboard
// ─────────────────────────────────────────────
final userDashboardProvider = FutureProvider<UserDashboard>((ref) {
  return DashboardApi.getUserDashboard();
});

// ─────────────────────────────────────────────
// Admin Dashboard
// ─────────────────────────────────────────────
final adminDashboardProvider =
    FutureProvider<AdminDashboard>((ref) {
  return DashboardApi.getAdminDashboard();
});

// ─────────────────────────────────────────────
// Members list
// ─────────────────────────────────────────────
final membersProvider =
    FutureProvider<List<UserSummary>>((ref) {
  return UserApi.getAllUsers();
});

// ─────────────────────────────────────────────
// Loans
// ─────────────────────────────────────────────
final myLoansProvider =
    FutureProvider<List<LoanApplication>>((ref) {
  return LoanApi.getMyLoans();
});

final allLoansProvider =
    FutureProvider<List<LoanApplication>>((ref) {
  return LoanApi.getAllLoans();
});

final pendingLoansProvider =
    FutureProvider<List<LoanApplication>>((ref) {
  return LoanApi.getAllLoans(status: 'Pending');
});

// ─────────────────────────────────────────────
// Payment / Screenshots
// ─────────────────────────────────────────────
final pendingScreenshotsProvider =
    FutureProvider<List<PendingScreenshot>>((ref) {
  return PaymentApi.getPendingReviews();
});

final pendingLoanRepaymentsProvider =
    FutureProvider<List<PendingLoanRepayment>>((ref) {
  return PaymentApi.getPendingLoanRepayments();
});

// ─────────────────────────────────────────────
// Eligible guarantors
// ─────────────────────────────────────────────
final eligibleGuarantorsProvider =
    FutureProvider<List<UserSummary>>((ref) {
  return UserApi.getEligibleGuarantors();
});

// ─────────────────────────────────────────────
// My Profile
// ─────────────────────────────────────────────
final myProfileProvider = FutureProvider<UserSummary>((ref) {
  return UserApi.getMyProfile();
});

// ─────────────────────────────────────────────
// My Contributions History
// ─────────────────────────────────────────────
final myContributionsProvider = FutureProvider<List<Contribution>>((ref) {
  return ContributionApi.getMyContributions();
});

// ─────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return NotificationApi.getMyNotifications();
});
