import 'api_client.dart';
import '../../models/dashboard_models.dart';
import '../../models/user_models.dart';
import '../../models/contribution_models.dart';
import '../../models/loan_models.dart';
import '../../models/payment_models.dart';


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
        await ApiClient.instance.post('/contributions', data: req.toJson());
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
      int id, bool approve, String? rejectionReason, DateTime? repaymentDueDate) async {
    final res = await ApiClient.instance.patch('/loans/$id/review', data: {
      'approve': approve,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (repaymentDueDate != null)
        'repaymentDueDate': repaymentDueDate.toIso8601String(),
    });
    return LoanApplication.fromJson(res.data);
  }

  static Future<LoanApplication> disburseLoan(
      int id, DateTime repaymentDueDate) async {
    final res = await ApiClient.instance.patch('/loans/$id/disburse', data: {
      'repaymentDueDate': repaymentDueDate.toIso8601String(),
    });
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
  static Future<PaymentToken> generateToken(int month, int year) async {
    final res = await ApiClient.instance
        .post('/payment/token/generate', data: {'month': month, 'year': year});
    return PaymentToken.fromJson(res.data);
  }

  static Future<PaymentToken?> getActiveToken(int month, int year) async {
    try {
      final res = await ApiClient.instance.get('/payment/token/active',
          queryParameters: {'month': month, 'year': year});
      return PaymentToken.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  static Future<ScreenshotResult> uploadScreenshot(
      int tokenId, String base64Image) async {
    final res = await ApiClient.instance.post(
        '/payment/token/$tokenId/upload-screenshot',
        data: {'screenshotBase64': base64Image});
    return ScreenshotResult.fromJson(res.data);
  }

  static Future<List<PendingScreenshot>> getPendingReviews() async {
    final res = await ApiClient.instance.get('/payment/pending-reviews');
    return (res.data as List)
        .map((e) => PendingScreenshot.fromJson(e))
        .toList();
  }

  static Future<void> adminVerify(
      int tokenId, bool approve, String? remarks) async {
    await ApiClient.instance
        .patch('/payment/token/$tokenId/admin-verify', data: {
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