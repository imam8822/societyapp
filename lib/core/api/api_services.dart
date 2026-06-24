import 'api_client.dart';
import '../../models/dashboard_models.dart';
import '../../models/user_models.dart';
import '../../models/contribution_models.dart';
import '../../models/loan_models.dart';
import '../../models/payment_models.dart';
import '../../models/app_notification.dart';
import '../../models/transaction_models.dart';


// ─────────────────────────────────────────────
// Dashboard
// ─────────────────────────────────────────────
class DashboardApi {
  static Future<UserDashboard> getUserDashboard() async {
    final res = await ApiClient.instance.get('/dashboard/user');
    return UserDashboard.fromJson(res.data);
  }

  static Future<AdminDashboard> getAdminDashboard() async {
    final res = await ApiClient.instance.get('/dashboard/admin');
    return AdminDashboard.fromJson(res.data);
  }
}

// ─────────────────────────────────────────────
// Users
// ─────────────────────────────────────────────
class UserApi {
  static Future<List<UserSummary>> getAllUsers({bool? active}) async {
    final res = await ApiClient.instance.get('/users',
        queryParameters: active != null ? {'active': active} : null);
    return (res.data as List).map((e) => UserSummary.fromJson(e)).toList();
  }

  static Future<UserSummary> getUserById(int id) async {
    final res = await ApiClient.instance.get('/users/$id');
    return UserSummary.fromJson(res.data);
  }

  static Future<UserSummary> getMyProfile() async {
    final res = await ApiClient.instance.get('/users/me/profile');
    return UserSummary.fromJson(res.data);
  }

  static Future<UserSummary> createUser(CreateUserRequest req) async {
    final res = await ApiClient.instance.post('/users', data: req.toJson());
    return UserSummary.fromJson(res.data);
  }

  static Future<UserSummary> updateUser(int id, Map<String, dynamic> data) async {
    final res = await ApiClient.instance.put('/users/$id', data: data);
    return UserSummary.fromJson(res.data);
  }

  static Future<List<UserSummary>> getEligibleGuarantors() async {
    final res = await ApiClient.instance.get('/users/eligible-guarantors');
    return (res.data as List).map((e) => UserSummary.fromJson(e)).toList();
  }

  static Future<List<UserDropdownItem>> getAllForReferral() async {
    final res = await ApiClient.instance.get('/users/all-for-referral');
    return (res.data as List).map((e) => UserDropdownItem.fromJson(e)).toList();
  }
}

// ─────────────────────────────────────────────
// Contributions
// ─────────────────────────────────────────────
class ContributionApi {
  static Future<List<Contribution>> getMyContributions() async {
    final res = await ApiClient.instance.get('/contributions/my');
    return (res.data as List).map((e) => Contribution.fromJson(e)).toList();
  }

  static Future<List<Contribution>> getUserContributions(int userId) async {
    final res = await ApiClient.instance.get('/contributions/user/$userId');
    return (res.data as List).map((e) => Contribution.fromJson(e)).toList();
  }

  static Future<Contribution> addContribution(
      AddContributionRequest req) async {
    final res =
        await ApiClient.instance.post('/contributions/cash', data: req.toJson());
    return Contribution.fromJson(res.data);
  }

  static Future<Contribution> verifyContribution(
      int id, bool approve, String? remarks) async {
    final res =
        await ApiClient.instance.patch('/contributions/$id/verify', data: {
      'approve': approve,
      if (remarks != null) 'remarks': remarks,
    });
    return Contribution.fromJson(res.data);
  }

  static Future<MonthlyReport> getMonthlyReport(int month, int year) async {
    final res = await ApiClient.instance.get('/contributions/report/monthly',
        queryParameters: {'month': month, 'year': year});
    return MonthlyReport.fromJson(res.data);
  }

  static Future<YearlyReport> getYearlyReport(int year) async {
    final res = await ApiClient.instance.get('/contributions/report/yearly',
        queryParameters: {'year': year});
    return YearlyReport.fromJson(res.data);
  }
}

// ─────────────────────────────────────────────
// Loans
// ─────────────────────────────────────────────
class LoanApi {
  static Future<LoanFormData> getFormData() async {
    final res = await ApiClient.instance.get('/loans/form-data');
    return LoanFormData.fromJson(res.data);
  }

  static Future<List<LoanApplication>> getMyLoans() async {
    final res = await ApiClient.instance.get('/loans/my');
    return (res.data as List).map((e) => LoanApplication.fromJson(e)).toList();
  }

  static Future<List<LoanApplication>> getAllLoans({String? status}) async {
    final res = await ApiClient.instance.get('/loans',
        queryParameters: status != null ? {'status': status} : null);
    return (res.data as List).map((e) => LoanApplication.fromJson(e)).toList();
  }

  static Future<LoanApplication> getLoanById(int id) async {
    final res = await ApiClient.instance.get('/loans/$id');
    return LoanApplication.fromJson(res.data);
  }

  static Future<LoanApplication> applyLoan(ApplyLoanRequest req) async {
    final res = await ApiClient.instance.post('/loans/apply', data: req.toJson());
    return LoanApplication.fromJson(res.data);
  }

  static Future<LoanApplication> reviewLoan(
      int id, bool approve, String? remarks) async {
    final res = await ApiClient.instance.patch('/loans/$id/review', data: {
      'approved': approve,
      if (remarks != null) 'remarks': remarks,
    });
    return LoanApplication.fromJson(res.data);
  }

  static Future<LoanApplication> disburseLoan(int id, String mode) async {
    // Due date auto-calculated on backend: 15th of month that is TenureMonths from today
    final res = await ApiClient.instance.patch('/loans/$id/disburse?mode=$mode', data: {});
    return LoanApplication.fromJson(res.data);
  }

  static Future<LoanApplication> recordRepayment(
      int id, double amount, String? remarks) async {
    final res = await ApiClient.instance.patch('/loans/$id/repay', data: {
      'repaidAmount': amount,
      if (remarks != null) 'remarks': remarks,
    });
    return LoanApplication.fromJson(res.data);
  }
}

// ─────────────────────────────────────────────
// Payment / UPI
// ─────────────────────────────────────────────
class PaymentApi {
  /// Get existing valid token or create a new one — no params needed.
  static Future<PaymentToken> getOrCreateToken() async {
    final res = await ApiClient.instance.get('/payment/token');
    return PaymentToken.fromJson(res.data);
  }

  /// Upload screenshot — backend finds active token automatically.
  static Future<ScreenshotResult> uploadScreenshot(String base64Image) async {
    final res = await ApiClient.instance.post(
        '/payment/upload-screenshot',
        data: {'screenshotBase64': base64Image});
    return ScreenshotResult.fromJson(res.data);
  }

  static Future<List<PendingScreenshot>> getPendingReviews() async {
    final res = await ApiClient.instance.get('/payment/pending-reviews');
    return (res.data as List)
        .map((e) => PendingScreenshot.fromJson(e))
        .toList();
  }

  /// Admin: approve or reject a contribution by contributionId (not tokenId).
  static Future<void> adminVerify(
      int contributionId, bool approve, String? remarks) async {
    await ApiClient.instance
        .patch('/payment/contributions/$contributionId/verify', data: {
      'approve': approve,
      if (remarks != null) 'remarks': remarks,
    });
  }

  // ── Loan Repayment ──────────────────────────────────

  /// Get or create a payment token for loan repayment.
  static Future<PaymentToken> getOrCreateLoanToken(int loanId) async {
    final res = await ApiClient.instance.get('/payment/loan-token/$loanId');
    return PaymentToken.fromJson(res.data);
  }

  /// Upload screenshot for loan repayment verification.
  static Future<ScreenshotResult> uploadLoanScreenshot(
      int loanId, String base64Image) async {
    final res = await ApiClient.instance.post(
        '/payment/loan-screenshot/$loanId',
        data: {'screenshotBase64': base64Image});
    return ScreenshotResult.fromJson(res.data);
  }

  static Future<List<PendingLoanRepayment>> getPendingLoanRepayments() async {
    final res = await ApiClient.instance.get('/payment/pending-loan-repayments');
    return (res.data as List)
        .map((e) => PendingLoanRepayment.fromJson(e))
        .toList();
  }

  static Future<void> adminVerifyLoanRepayment(
      int loanRepaymentId, bool approve, String? remarks) async {
    await ApiClient.instance
        .patch('/payment/loan-repayments/$loanRepaymentId/verify', data: {
      'approve': approve,
      if (remarks != null) 'remarks': remarks,
    });
  }
}

// ─────────────────────────────────────────────
// Settings
// ─────────────────────────────────────────────
class SettingsApi {
  static Future<SocietySettings> getSettings() async {
    final res = await ApiClient.instance.get('/settings');
    return SocietySettings.fromJson(res.data);
  }

  static Future<SocietySettings> updateSettings(
      Map<String, dynamic> data) async {
    final res = await ApiClient.instance.put('/settings', data: data);
    return SocietySettings.fromJson(res.data);
  }
}

// ─────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────
class NotificationApi {
  static Future<List<AppNotification>> getMyNotifications() async {
    final res = await ApiClient.instance.get('/Notifications');
    return (res.data as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  static Future<void> markAsRead(int id) async {
    await ApiClient.instance.put('/Notifications/$id/read');
  }

  static Future<void> saveFcmToken(String token) async {
    await ApiClient.instance.post('/Notifications/fcm-token', data: {'token': token});
  }
}

// ─────────────────────────────────────────────
// Transactions (Ledger & Stats)
// ─────────────────────────────────────────────
class TransactionApi {
  static Future<List<TransactionDto>> getTransactions({int limit = 100}) async {
    final res = await ApiClient.instance.get('/transaction', queryParameters: {'limit': limit});
    return (res.data as List).map((e) => TransactionDto.fromJson(e)).toList();
  }

  static Future<TransactionStatsDto> getStats() async {
    final res = await ApiClient.instance.get('/transaction/stats');
    return TransactionStatsDto.fromJson(res.data);
  }

  static Future<void> exportStatement({
    DateTime? startDate,
    DateTime? endDate,
    required String format,
    required String savePath,
  }) async {
    final Map<String, dynamic> params = {'format': format};
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();

    await ApiClient.instance.download(
      '/transaction/export',
      savePath,
      queryParameters: params,
    );
  }
}