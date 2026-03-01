// ─────────────────────────────────────────────
// Payment Models
// ─────────────────────────────────────────────
class PaymentToken {
  final int id;
  final String token;
  final int month;
  final int year;
  final double amount;
  final double penaltyAmount;
  final double totalAmount;
  final String? coveredMonths;
  final DateTime expiresAt;
  final bool isUsed;
  final String ocrStatus;
  final String? screenshotUrl;
  final String upiDeepLink;

  PaymentToken({
    required this.id,
    required this.token,
    required this.month,
    required this.year,
    required this.amount,
    required this.penaltyAmount,
    required this.totalAmount,
    this.coveredMonths,
    required this.expiresAt,
    required this.isUsed,
    required this.ocrStatus,
    this.screenshotUrl,
    required this.upiDeepLink,
  });

  factory PaymentToken.fromJson(Map<String, dynamic> j) => PaymentToken(
        id: j['id'],
        token: j['token'],
        month: j['month'],
        year: j['year'],
        amount: (j['amount'] as num).toDouble(),
        penaltyAmount: (j['penaltyAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? (j['amount'] as num).toDouble(),
        coveredMonths: j['coveredMonths'],
        expiresAt: DateTime.parse(j['expiresAt']),
        isUsed: j['isUsed'],
        ocrStatus: j['ocrStatus'],
        screenshotUrl: j['screenshotUrl'],
        upiDeepLink: j['upiDeepLink'],
      );

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class ScreenshotResult {
  final int tokenId;
  final String ocrStatus;
  final bool autoVerified;
  final String message;

  ScreenshotResult({
    required this.tokenId,
    required this.ocrStatus,
    required this.autoVerified,
    required this.message,
  });

  factory ScreenshotResult.fromJson(Map<String, dynamic> j) => ScreenshotResult(
        tokenId: j['tokenId'],
        ocrStatus: j['ocrStatus'],
        autoVerified: j['autoVerified'],
        message: j['message'],
      );
}

class PendingScreenshot {
  final int tokenId;
  final int userId;
  final String userName;
  final String userPhone;
  final String token;
  final int month;
  final int year;
  final double amount;
  final String? screenshotUrl;
  final String ocrStatus;
  final String? ocrExtractedText;
  final DateTime? screenshotUploadedAt;

  PendingScreenshot({
    required this.tokenId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.token,
    required this.month,
    required this.year,
    required this.amount,
    this.screenshotUrl,
    required this.ocrStatus,
    this.ocrExtractedText,
    this.screenshotUploadedAt,
  });

  factory PendingScreenshot.fromJson(Map<String, dynamic> j) =>
      PendingScreenshot(
        tokenId: j['tokenId'],
        userId: j['userId'],
        userName: j['userName'],
        userPhone: j['userPhone'],
        token: j['token'],
        month: j['month'],
        year: j['year'],
        amount: (j['amount'] as num).toDouble(),
        screenshotUrl: j['screenshotUrl'],
        ocrStatus: j['ocrStatus'],
        ocrExtractedText: j['ocrExtractedText'],
        screenshotUploadedAt: j['screenshotUploadedAt'] != null
            ? DateTime.parse(j['screenshotUploadedAt'])
            : null,
      );

  String get monthName {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month]} $year';
  }
}

// ─────────────────────────────────────────────
// Settings Models
// ─────────────────────────────────────────────
class SocietySettings {
  final String societyName;
  final String upiId;
  final String upiDisplayName;
  final double monthlyContributionAmount;

  SocietySettings({
    required this.societyName,
    required this.upiId,
    required this.upiDisplayName,
    required this.monthlyContributionAmount,
  });

  factory SocietySettings.fromJson(Map<String, dynamic> j) => SocietySettings(
        societyName: j['societyName'],
        upiId: j['upiId'],
        upiDisplayName: j['upiDisplayName'],
        monthlyContributionAmount:
            (j['monthlyContributionAmount'] as num).toDouble(),
      );
}