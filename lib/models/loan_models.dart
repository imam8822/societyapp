class LoanApplication {
  final int id;
  final int applicantId;
  final String applicantName;
  final String applicantPhone;
  final int? guarantorId;
  final String? guarantorName;
  final String? guarantorPhone;
  final bool guarantorRequired;
  final double amount;
  final String status;
  final DateTime appliedDate;
  final DateTime? reviewedAt;
  final String? reviewedByAdmin;
  final String? rejectionReason;
  final int? tenureMonths;
  final DateTime? disbursedDate;
  final DateTime? repaymentDueDate;
  final DateTime? finalRepaymentDate;
  final double totalRepaid;
  final double outstandingAmount;
  final double applicantTotalSaved;

  LoanApplication({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.applicantPhone,
    this.guarantorId,
    this.guarantorName,
    this.guarantorPhone,
    required this.guarantorRequired,
    required this.amount,
    required this.status,
    required this.appliedDate,
    this.reviewedAt,
    this.reviewedByAdmin,
    this.rejectionReason,
    this.tenureMonths,
    this.disbursedDate,
    this.repaymentDueDate,
    this.finalRepaymentDate,
    required this.totalRepaid,
    required this.outstandingAmount,
    required this.applicantTotalSaved,
  });

  factory LoanApplication.fromJson(Map<String, dynamic> j) => LoanApplication(
        id: j['id'],
        applicantId: j['applicantId'],
        applicantName: j['applicantName'],
        applicantPhone: j['applicantPhone'],
        guarantorId: j['guarantorId'],
        guarantorName: j['guarantorName'],
        guarantorPhone: j['guarantorPhone'],
        guarantorRequired: j['guarantorRequired'] ?? true,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        status: j['status'],
        appliedDate: DateTime.parse(j['appliedDate']),
        reviewedAt: j['reviewedAt'] != null
            ? DateTime.parse(j['reviewedAt'])
            : null,
        reviewedByAdmin: j['reviewedByAdmin'],
        rejectionReason: j['rejectionReason'],
        tenureMonths: j['tenureMonths'],
        disbursedDate: j['disbursedDate'] != null
            ? DateTime.parse(j['disbursedDate'])
            : null,
        repaymentDueDate: j['repaymentDueDate'] != null
            ? DateTime.parse(j['repaymentDueDate'])
            : null,
        finalRepaymentDate: j['finalRepaymentDate'] != null
            ? DateTime.parse(j['finalRepaymentDate'])
            : null,
        totalRepaid: (j['totalRepaid'] as num?)?.toDouble() ?? 0,
        outstandingAmount: (j['outstandingAmount'] as num?)?.toDouble() ?? 0,
        applicantTotalSaved:
            (j['applicantTotalSaved'] as num?)?.toDouble() ?? 0,
      );

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isDisbursed => status == 'Disbursed';
  bool get isRepaid => status == 'Repaid';
  bool get isActive => isPending || isApproved || isDisbursed;
}

class ApplyLoanRequest {
  final int loanOptionId;
  final int? guarantorId;

  ApplyLoanRequest({
    required this.loanOptionId,
    this.guarantorId,
  });

  Map<String, dynamic> toJson() => {
        'loanOptionId': loanOptionId,
        if (guarantorId != null) 'guarantorId': guarantorId,
      };
}

class LoanOption {
  final int id;
  final String label;
  final double amount;
  final int minTenureRequired;   // months user must have contributed to be eligible
  final int maxRepaymentTenure;  // deadline — repay on or before 15th of this month from disbursal
  final double repaymentAmount;  // fixed TOTAL single repayment amount (not monthly)
  final bool isEligible;         // user has >= minTenureRequired months paid
  final bool guarantorRequired;  // loan amount > user's total invested

  LoanOption({
    required this.id,
    required this.label,
    required this.amount,
    required this.minTenureRequired,
    required this.maxRepaymentTenure,
    required this.repaymentAmount,
    required this.isEligible,
    required this.guarantorRequired,
  });

  factory LoanOption.fromJson(Map<String, dynamic> j) => LoanOption(
        id: j['id'],
        label: j['label'] ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        minTenureRequired: j['minTenureRequired'] ?? 6,
        maxRepaymentTenure: j['maxRepaymentTenure'] ?? 12,
        repaymentAmount: (j['repaymentAmount'] as num?)?.toDouble() ?? 0,
        isEligible: j['isEligible'] ?? false,
        guarantorRequired: j['guarantorRequired'] ?? false,
      );
}

class GuarantorOption {
  final int id;
  final String fullName;
  final String phone;

  GuarantorOption({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory GuarantorOption.fromJson(Map<String, dynamic> j) => GuarantorOption(
        id: j['id'],
        fullName: j['fullName'],
        phone: j['phone'],
      );
}

class LoanFormData {
  final List<LoanOption> loanOptions;
  final List<GuarantorOption> availableGuarantors;
  final double userTotalInvested;
  final int userPaidMonths;

  LoanFormData({
    required this.loanOptions,
    required this.availableGuarantors,
    required this.userTotalInvested,
    required this.userPaidMonths,
  });

  factory LoanFormData.fromJson(Map<String, dynamic> j) => LoanFormData(
        loanOptions: (j['loanOptions'] as List? ?? [])
            .map((e) => LoanOption.fromJson(e))
            .toList(),
        availableGuarantors: (j['availableGuarantors'] as List? ?? [])
            .map((e) => GuarantorOption.fromJson(e))
            .toList(),
        userTotalInvested:
            (j['userTotalInvested'] as num?)?.toDouble() ?? 0,
        userPaidMonths: j['userPaidMonths'] ?? 0,
      );
}