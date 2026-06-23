class Contribution {
  final int id;
  final int userId;
  final String userName;
  final double amount;
  final int month;
  final int year;
  final String mode;
  final String? screenshotUrl;
  final String? transactionReference;
  final String? remarks;
  final bool isVerified;
  final DateTime paidDate;
  final String? verifiedByAdmin;
  final DateTime? verifiedAt;

  Contribution({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.month,
    required this.year,
    required this.mode,
    this.screenshotUrl,
    this.transactionReference,
    this.remarks,
    required this.isVerified,
    required this.paidDate,
    this.verifiedByAdmin,
    this.verifiedAt,
  });

  factory Contribution.fromJson(Map<String, dynamic> j) => Contribution(
        id: j['id'],
        userId: j['userId'],
        userName: j['userName'],
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        month: j['month'],
        year: j['year'],
        mode: j['mode'],
        screenshotUrl: j['screenshotUrl'],
        transactionReference: j['transactionReference'],
        remarks: j['remarks'],
        isVerified: j['isVerified'],
        paidDate: DateTime.parse(j['paidDate']),
        verifiedByAdmin: j['verifiedByAdmin'],
        verifiedAt: j['verifiedAt'] != null
            ? DateTime.parse(j['verifiedAt'])
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

class AddContributionRequest {
  final int userId;
  final int month;
  final int year;
  final double? amountOverride;
  final double penaltyAmount;
  final String? transactionReference;
  final String? remarks;
  final DateTime? paidDate;

  AddContributionRequest({
    required this.userId,
    required this.month,
    required this.year,
    this.amountOverride,
    this.penaltyAmount = 0,
    this.transactionReference,
    this.remarks,
    this.paidDate,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'month': month,
        'year': year,
        if (amountOverride != null) 'amountOverride': amountOverride,
        'penaltyAmount': penaltyAmount,
        if (transactionReference != null)
          'transactionReference': transactionReference,
        if (remarks != null) 'remarks': remarks,
        if (paidDate != null) 'paidDate': paidDate!.toIso8601String(),
      };
}

class MonthlyReport {
  final int month;
  final int year;
  final int totalMembers;
  final int paidCount;
  final int unpaidCount;
  final double totalCollected;
  final List<Contribution> contributions;

  MonthlyReport({
    required this.month,
    required this.year,
    required this.totalMembers,
    required this.paidCount,
    required this.unpaidCount,
    required this.totalCollected,
    required this.contributions,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> j) => MonthlyReport(
        month: j['month'],
        year: j['year'],
        totalMembers: j['totalMembers'],
        paidCount: j['paidCount'],
        unpaidCount: j['unpaidCount'],
        totalCollected: (j['totalCollected'] as num?)?.toDouble() ?? 0,
        contributions: (j['contributions'] as List)
            .map((e) => Contribution.fromJson(e))
            .toList(),
      );
}

class YearlyReport {
  final int year;
  final double totalCollected;
  final int totalMembers;
  final List<MemberYearlyRow> memberRows;

  YearlyReport({
    required this.year,
    required this.totalCollected,
    required this.totalMembers,
    required this.memberRows,
  });

  factory YearlyReport.fromJson(Map<String, dynamic> j) => YearlyReport(
        year: j['year'],
        totalCollected: (j['totalCollected'] as num?)?.toDouble() ?? 0,
        totalMembers: j['totalMembers'],
        memberRows: (j['memberRows'] as List)
            .map((e) => MemberYearlyRow.fromJson(e))
            .toList(),
      );
}

class MemberYearlyRow {
  final int userId;
  final String fullName;
  final String phone;
  final double totalSaved;
  final int monthsPaid;
  final Map<int, bool> monthlyStatus;

  MemberYearlyRow({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.totalSaved,
    required this.monthsPaid,
    required this.monthlyStatus,
  });

  factory MemberYearlyRow.fromJson(Map<String, dynamic> j) => MemberYearlyRow(
        userId: j['userId'],
        fullName: j['fullName'],
        phone: j['phone'],
        totalSaved: (j['totalSaved'] as num?)?.toDouble() ?? 0,
        monthsPaid: j['monthsPaid'],
        monthlyStatus: (j['monthlyStatus'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), v as bool)),
      );
}