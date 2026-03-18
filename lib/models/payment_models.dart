class PaymentToken {
  final int id;
  final String token;
  final int month;
  final int year;
  final double amount;
  final double penaltyAmount;
  final double totalAmount;
  final DateTime expiresAt;
  final bool isUsed;
  final String upiDeepLink;

  PaymentToken({
    required this.id,
    required this.token,
    required this.month,
    required this.year,
    required this.amount,
    required this.penaltyAmount,
    required this.totalAmount,
    required this.expiresAt,
    required this.isUsed,
    required this.upiDeepLink,
  });

  factory PaymentToken.fromJson(Map<String, dynamic> j) => PaymentToken(
        id: j['id'],
        token: j['token'],
        month: j['month'],
        year: j['year'],
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        penaltyAmount: (j['penaltyAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        expiresAt: DateTime.parse(j['expiresAt']),
        isUsed: j['isUsed'] ?? false,
        upiDeepLink: j['upiDeepLink'] ?? '',
      );

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
  String get expiresInText {
    final h = timeRemaining.inHours;
    final m = timeRemaining.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class ScreenshotResult {
  final int tokenId;
  final int contributionId;
  final String ocrStatus;
  final bool autoVerified;
  final String message;
  final String? aiSummary;

  ScreenshotResult({
    required this.tokenId,
    required this.contributionId,
    required this.ocrStatus,
    required this.autoVerified,
    required this.message,
    this.aiSummary,
  });

  factory ScreenshotResult.fromJson(Map<String, dynamic> j) => ScreenshotResult(
        tokenId: j['tokenId'] ?? 0,
        contributionId: j['contributionId'] ?? 0,
        ocrStatus: j['ocrStatus'] ?? '',
        autoVerified: j['autoVerified'] ?? false,
        message: j['message'] ?? '',
        aiSummary: j['aiSummary'],
      );
}

class PendingScreenshot {
  final int contributionId;
  final int userId;
  final String userName;
  final String userPhone;
  final String? token;
  final int month;
  final int year;
  final double amount;
  final double penaltyAmount;
  final double totalAmount;
  final String? screenshotUrl;
  final String ocrStatus;
  final String? ocrExtractedText;
  final String aiVerificationStatus;
  final String? aiSummary;
  final double? aiExtractedAmount;
  final DateTime? screenshotUploadedAt;

  PendingScreenshot({
    required this.contributionId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    this.token,
    required this.month,
    required this.year,
    required this.amount,
    required this.penaltyAmount,
    required this.totalAmount,
    this.screenshotUrl,
    required this.ocrStatus,
    this.ocrExtractedText,
    required this.aiVerificationStatus,
    this.aiSummary,
    this.aiExtractedAmount,
    this.screenshotUploadedAt,
  });

  factory PendingScreenshot.fromJson(Map<String, dynamic> j) => PendingScreenshot(
        contributionId: j['contributionId'],
        userId: j['userId'],
        userName: j['userName'] ?? '',
        userPhone: j['userPhone'] ?? '',
        token: j['token'],
        month: j['month'],
        year: j['year'],
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        penaltyAmount: (j['penaltyAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        screenshotUrl: j['screenshotUrl'],
        ocrStatus: j['ocrStatus'] ?? '',
        ocrExtractedText: j['ocrExtractedText'],
        aiVerificationStatus: j['aiVerificationStatus'] ?? '',
        aiSummary: j['aiSummary'],
        aiExtractedAmount: (j['aiExtractedAmount'] as num?)?.toDouble(),
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
  final double penaltyPerMissedMonth;
  final String? logoBase64;
  final DateTime? updatedAt;
  final String? updatedByName;

  SocietySettings({
    required this.societyName,
    required this.upiId,
    required this.upiDisplayName,
    required this.monthlyContributionAmount,
    required this.penaltyPerMissedMonth,
    this.logoBase64,
    this.updatedAt,
    this.updatedByName,
  });

  factory SocietySettings.fromJson(Map<String, dynamic> j) => SocietySettings(
        societyName: j['societyName'] ?? '',
        upiId: j['upiId'] ?? '',
        upiDisplayName: j['upiDisplayName'] ?? '',
        monthlyContributionAmount:
            (j['monthlyContributionAmount'] as num?)?.toDouble() ?? 500,
        penaltyPerMissedMonth:
            (j['penaltyPerMissedMonth'] as num?)?.toDouble() ?? 50,
        logoBase64: j['logoBase64'],
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'])
            : null,
        updatedByName: j['updatedByName'],
      );
}