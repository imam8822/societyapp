import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/core/api/api_services.dart';
import 'package:society_app/models/dashboard_models.dart';
import 'package:society_app/models/loan_models.dart';
import 'package:society_app/models/payment_models.dart';
import 'package:society_app/models/user_models.dart';


// ─────────────────────────────────────────────
// User Dashboard
// ─────────────────────────────────────────────
final userDashboardProvider = FutureProvider.autoDispose<UserDashboard>((ref) {
  return DashboardApi.getUserDashboard();
});

// ─────────────────────────────────────────────
// Admin Dashboard
// ─────────────────────────────────────────────
final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboard>((ref) {
  return DashboardApi.getAdminDashboard();
});

// ─────────────────────────────────────────────
// Members list
// ─────────────────────────────────────────────
final membersProvider =
    FutureProvider.autoDispose<List<UserSummary>>((ref) {
  return UserApi.getAllUsers();
});

// ─────────────────────────────────────────────
// Loans
// ─────────────────────────────────────────────
final myLoansProvider =
    FutureProvider.autoDispose<List<LoanApplication>>((ref) {
  return LoanApi.getMyLoans();
});

final allLoansProvider =
    FutureProvider.autoDispose<List<LoanApplication>>((ref) {
  return LoanApi.getAllLoans();
});

final pendingLoansProvider =
    FutureProvider.autoDispose<List<LoanApplication>>((ref) {
  return LoanApi.getAllLoans(status: 'Pending');
});

// ─────────────────────────────────────────────
// Payment / Screenshots
// ─────────────────────────────────────────────
final pendingScreenshotsProvider =
    FutureProvider.autoDispose<List<PendingScreenshot>>((ref) {
  return PaymentApi.getPendingReviews();
});

// ─────────────────────────────────────────────
// Settings
// ─────────────────────────────────────────────
final settingsProvider =
    FutureProvider.autoDispose<SocietySettings>((ref) {
  return SettingsApi.getSettings();
});

// ─────────────────────────────────────────────
// Eligible guarantors
// ─────────────────────────────────────────────
final eligibleGuarantorsProvider =
    FutureProvider.autoDispose<List<UserSummary>>((ref) {
  return UserApi.getEligibleGuarantors();
});
