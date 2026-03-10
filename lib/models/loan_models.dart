class LoanInstallment {
  final int id;
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidDate;
  final String? remarks;
  final bool isOverdue;

  LoanInstallment({
    required this.id,
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
    this.paidDate,
    this.remarks,
    required this.isOverdue,
  });

  factory LoanInstallment.fromJson(Map<String, dynamic> j) => LoanInstallment(
        id: j['id'],
        installmentNumber: j['installmentNumber'],
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        dueDate: DateTime.parse(j['dueDate']),
        isPaid: j['isPaid'],
        paidDate: j['paidDate'] != null ? DateTime.parse(j['paidDate']) : null,
        remarks: j['remarks'],
        isOverdue: j['isOverdue'] ?? false,
      );
}

class LoanApplication {
  final int id;
  final int applicantId;
  final String applicantName;
  final String applicantPhone;
  final int? guarantorId;
  final String? guarantorName;
  final String? guarantorPhone;
  final bool guarantorRequired;
  final double requestedAmount;
  final double? approvedAmount;
  final String status;
  final DateTime appliedDate;
  final DateTime? reviewedAt;
  final String? reviewedByAdmin;
  final String? rejectionReason;
  final int? tenureMonths;
  final double? monthlyInstallmentAmount;
  final DateTime? disbursedDate;
  final DateTime? repaymentStartDate;
  final DateTime? finalRepaymentDueDate;
  final double totalRepaid;
  final double outstandingAmount;
  final DateTime? fullyRepaidDate;
  final double applicantTotalSaved;
  final List<LoanInstallment> installments;

  LoanApplication({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.applicantPhone,
    this.guarantorId,
    this.guarantorName,
    this.guarantorPhone,
    required this.guarantorRequired,
    required this.requestedAmount,
    this.approvedAmount,
    required this.status,
    required this.appliedDate,
    this.reviewedAt,
    this.reviewedByAdmin,
    this.rejectionReason,
    this.tenureMonths,
    this.monthlyInstallmentAmount,
    this.disbursedDate,
    this.repaymentStartDate,
    this.finalRepaymentDueDate,
    required this.totalRepaid,
    required this.outstandingAmount,
    this.fullyRepaidDate,
    required this.applicantTotalSaved,
    required this.installments,
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
        requestedAmount: (j['requestedAmount'] as num?)?.toDouble() ?? 0,
        approvedAmount: (j['approvedAmount'] as num?)?.toDouble(),
        status: j['status'],
        appliedDate: DateTime.parse(j['appliedDate']),
        reviewedAt: j['reviewedAt'] != null ? DateTime.parse(j['reviewedAt']) : null,
        reviewedByAdmin: j['reviewedByAdmin'],
        rejectionReason: j['rejectionReason'],
        tenureMonths: j['tenureMonths'],
        monthlyInstallmentAmount: (j['monthlyInstallmentAmount'] as num?)?.toDouble(),
        disbursedDate: j['disbursedDate'] != null ? DateTime.parse(j['disbursedDate']) : null,
        repaymentStartDate: j['repaymentStartDate'] != null ? DateTime.parse(j['repaymentStartDate']) : null,
        finalRepaymentDueDate: j['finalRepaymentDueDate'] != null ? DateTime.parse(j['finalRepaymentDueDate']) : null,
        totalRepaid: (j['totalRepaid'] as num?)?.toDouble() ?? 0,
        outstandingAmount: (j['outstandingAmount'] as num?)?.toDouble() ?? 0,
        fullyRepaidDate: j['fullyRepaidDate'] != null ? DateTime.parse(j['fullyRepaidDate']) : null,
        applicantTotalSaved: (j['applicantTotalSaved'] as num?)?.toDouble() ?? 0,
        installments: (j['installments'] as List? ?? [])
            .map((e) => LoanInstallment.fromJson(e))
            .toList(),
      );

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isDisbursed => status == 'Disbursed';
  bool get isRepaid => status == 'Repaid';
  bool get isActive => isPending || isApproved || isDisbursed;

  LoanInstallment? get nextInstallment => installments
      .where((i) => !i.isPaid)
      .toList()
      .isEmpty ? null : (installments.where((i) => !i.isPaid).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate)))
      .first;
}

class ApplyLoanRequest {
  final int? guarantorId;
  final double requestedAmount;
  final int tenureMonths;

  ApplyLoanRequest({
    this.guarantorId,
    required this.requestedAmount,
    required this.tenureMonths,
  });

  Map<String, dynamic> toJson() => {
        if (guarantorId != null) 'guarantorId': guarantorId,
        'requestedAmount': requestedAmount,
        'tenureMonths': tenureMonths,
      };
}

class LoanOption {
  final int id;
  final String label;
  final double amount;
  final int minTenureRequired;    // months contributed needed to be eligible
  final int maxRepaymentTenure;   // max months allowed to repay
  final double repaymentAmount;   // fixed monthly installment amount
  final bool isEligible;          // whether current user meets minTenureRequired

  LoanOption({required this.id, required this.label, required this.amount,
      required this.minTenureRequired, required this.maxRepaymentTenure,
      required this.repaymentAmount, required this.isEligible});

  factory LoanOption.fromJson(Map<String, dynamic> j) => LoanOption(
    id: j['id'],
    label: j['label'] ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    minTenureRequired: j['minTenureRequired'] ?? 6,
    maxRepaymentTenure: j['maxRepaymentTenure'] ?? 12,
    repaymentAmount: (j['repaymentAmount'] as num?)?.toDouble() ?? 0,
    isEligible: j['isEligible'] ?? false,
  );
}

class GuarantorOption {
  final int id;
  final String fullName, phone;
  GuarantorOption({required this.id, required this.fullName, required this.phone});
  factory GuarantorOption.fromJson(Map<String, dynamic> j) => GuarantorOption(
    id: j['id'], fullName: j['fullName'], phone: j['phone'],
  );
}

class LoanFormData {
  final List<LoanOption> loanOptions;
  final List<GuarantorOption> availableGuarantors;
  final double userTotalInvested;
  final int userPaidMonths;

  LoanFormData({required this.loanOptions, required this.availableGuarantors,
      required this.userTotalInvested, required this.userPaidMonths});

  factory LoanFormData.fromJson(Map<String, dynamic> j) => LoanFormData(
    loanOptions: (j['loanOptions'] as List? ?? [])
        .map((e) => LoanOption.fromJson(e)).toList(),
    availableGuarantors: (j['availableGuarantors'] as List? ?? [])
        .map((e) => GuarantorOption.fromJson(e)).toList(),
    userTotalInvested: (j['userTotalInvested'] as num?)?.toDouble() ?? 0,
    userPaidMonths: j['userPaidMonths'] ?? 0,
  );
}