class LoanApplication {
  final int id;
  final int applicantId;
  final String applicantName;
  final String applicantPhone;
  final int? guarantorId;
  final String? guarantorName;
  final String? guarantorPhone;
  final String? guarantorStatus;
  
  final int? guarantor2Id;
  final String? guarantor2Name;
  final String? guarantor2Phone;
  final String? guarantor2Status;
  
  final bool guarantorRequired;
  final double amount;
  final String status;
  final DateTime appliedDate;
  final DateTime? reviewedAt;
  final String? reviewedByAdmin;
  final String? rejectionReason;
  final int? tenureMonths;
  final DateTime? disbursedDate;
  final String? disbursementMode;
  final DateTime? repaymentDueDate;
  final DateTime? finalRepaymentDate;
  final double totalRepaid;
  final double outstandingAmount;
  final double applicantTotalSaved;
  final bool hasPendingRepayment;
  // Rush / emergency fields
  final String applicationType;   // 'Regular' | 'MonthEndRush'
  final bool isEmergency;
  final int? monthEndSlotMonth;
  final int? monthEndSlotYear;

  LoanApplication({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.applicantPhone,
    this.guarantorId,
    this.guarantorName,
    this.guarantorPhone,
    this.guarantorStatus,
    this.guarantor2Id,
    this.guarantor2Name,
    this.guarantor2Phone,
    this.guarantor2Status,
    required this.guarantorRequired,
    required this.amount,
    required this.status,
    required this.appliedDate,
    this.reviewedAt,
    this.reviewedByAdmin,
    this.rejectionReason,
    this.tenureMonths,
    this.disbursedDate,
    this.disbursementMode,
    this.repaymentDueDate,
    this.finalRepaymentDate,
    required this.totalRepaid,
    required this.outstandingAmount,
    required this.applicantTotalSaved,
    required this.hasPendingRepayment,
    this.applicationType = 'Regular',
    this.isEmergency = false,
    this.monthEndSlotMonth,
    this.monthEndSlotYear,
  });

  factory LoanApplication.fromJson(Map<String, dynamic> j) => LoanApplication(
        id: j['id'],
        applicantId: j['applicantId'],
        applicantName: j['applicantName'] ?? '',
        applicantPhone: j['applicantPhone'] ?? '',
        guarantorId: j['guarantorId'],
        guarantorName: j['guarantorName'],
        guarantorPhone: j['guarantorPhone'],
        guarantorStatus: j['guarantorStatus'],
        guarantor2Id: j['guarantor2Id'],
        guarantor2Name: j['guarantor2Name'],
        guarantor2Phone: j['guarantor2Phone'],
        guarantor2Status: j['guarantor2Status'],
        guarantorRequired: j['guarantorRequired'] ?? false,
        amount: (j['amount'] as num).toDouble(),
        status: j['status'] ?? 'Pending',
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
        disbursementMode: j['disbursementMode'],
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
        hasPendingRepayment: j['hasPendingRepayment'] ?? false,
        applicationType: j['applicationType'] ?? 'Regular',
        isEmergency: j['isEmergency'] ?? false,
        monthEndSlotMonth: j['monthEndSlotMonth'],
        monthEndSlotYear: j['monthEndSlotYear'],
      );

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isDisbursed => status == 'Disbursed';
  bool get isRepaid => status == 'Repaid';
  bool get isActive => isPending || isApproved || isDisbursed;
  bool get isRushApplication => applicationType == 'MonthEndRush';
}

class ApplyLoanRequest {
  final int loanOptionId;
  final int? guarantorId;
  final int? guarantor2Id;
  final bool isEmergency;

  ApplyLoanRequest({
    required this.loanOptionId,
    this.guarantorId,
    this.guarantor2Id,
    this.isEmergency = false,
  });

  Map<String, dynamic> toJson() => {
        'loanOptionId': loanOptionId,
        if (guarantorId != null) 'guarantorId': guarantorId,
        if (guarantor2Id != null) 'guarantor2Id': guarantor2Id,
        'isEmergency': isEmergency,
      };
}

class LoanOption {
  final int id;
  final String label;
  final double amount;
  final int minTenureRequired;
  final int maxRepaymentTenure;
  final double repaymentAmount;
  final bool isEligible;
  final bool guarantorRequired;
  final int requiredGuarantors;
  /// Null = no restriction. Non-null = capped slots per month (last-day rush window).
  final int? quota;
  final bool isActive;

  LoanOption({
    required this.id,
    required this.label,
    required this.amount,
    required this.minTenureRequired,
    required this.maxRepaymentTenure,
    required this.repaymentAmount,
    required this.isEligible,
    required this.guarantorRequired,
    required this.requiredGuarantors,
    this.quota,
    this.isActive = true,
  });

  factory LoanOption.fromJson(Map<String, dynamic> j) => LoanOption(
        id: j['id'],
        label: j['label'] ?? '',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        minTenureRequired: j['minTenureRequired'] ?? 6,
        maxRepaymentTenure: j['maxRepaymentTenure'] ?? 12,
        repaymentAmount: (j['repaymentAmount'] as num).toDouble(),
        isEligible: j['isEligible'] ?? false,
        guarantorRequired: j['guarantorRequired'] ?? false,
        requiredGuarantors: j['requiredGuarantors'] ?? 1,
        quota: j['quota'],
        isActive: j['isActive'] ?? true,
      );

  bool get hasQuota => quota != null;
}

class GuarantorOption {
  final int id;
  final String fullName;
  final String phone;
  final double availableGuaranteeLimit;

  GuarantorOption({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.availableGuaranteeLimit,
  });

  factory GuarantorOption.fromJson(Map<String, dynamic> j) => GuarantorOption(
        id: j['id'],
        fullName: j['fullName'],
        phone: j['phone'],
        availableGuaranteeLimit: (j['availableGuaranteeLimit'] as num?)?.toDouble() ?? 0,
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