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
  final String purpose;
  final String status;
  final DateTime appliedDate;
  final DateTime? reviewedAt;
  final String? reviewedByAdmin;
  final String? rejectionReason;
  final DateTime? disbursedDate;
  final DateTime? repaymentDueDate;
  final DateTime? repaidDate;
  final double? repaidAmount;
  final String? repaymentRemarks;
  final double applicantTotalSaved;
  final double guarantorTotalSaved;

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
    required this.purpose,
    required this.status,
    required this.appliedDate,
    this.reviewedAt,
    this.reviewedByAdmin,
    this.rejectionReason,
    this.disbursedDate,
    this.repaymentDueDate,
    this.repaidDate,
    this.repaidAmount,
    this.repaymentRemarks,
    required this.applicantTotalSaved,
    required this.guarantorTotalSaved,
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
        requestedAmount: (j['requestedAmount'] as num).toDouble(),
        purpose: j['purpose'],
        status: j['status'],
        appliedDate: DateTime.parse(j['appliedDate']),
        reviewedAt: j['reviewedAt'] != null
            ? DateTime.parse(j['reviewedAt'])
            : null,
        reviewedByAdmin: j['reviewedByAdmin'],
        rejectionReason: j['rejectionReason'],
        disbursedDate: j['disbursedDate'] != null
            ? DateTime.parse(j['disbursedDate'])
            : null,
        repaymentDueDate: j['repaymentDueDate'] != null
            ? DateTime.parse(j['repaymentDueDate'])
            : null,
        repaidDate:
            j['repaidDate'] != null ? DateTime.parse(j['repaidDate']) : null,
        repaidAmount: j['repaidAmount'] != null
            ? (j['repaidAmount'] as num).toDouble()
            : null,
        repaymentRemarks: j['repaymentRemarks'],
        applicantTotalSaved:
            (j['applicantTotalSaved'] as num?)?.toDouble() ?? 0,
        guarantorTotalSaved:
            (j['guarantorTotalSaved'] as num?)?.toDouble() ?? 0,
      );

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';
  bool get isDisbursed => status == 'Disbursed';
  bool get isRepaid => status == 'Repaid';
  bool get isActive => isPending || isApproved || isDisbursed;
}

class ApplyLoanRequest {
  final int? guarantorId;
  final double requestedAmount;
  final String purpose;

  ApplyLoanRequest({
    this.guarantorId,
    required this.requestedAmount,
    required this.purpose,
  });

  Map<String, dynamic> toJson() => {
        if (guarantorId != null) 'guarantorId': guarantorId,
        'requestedAmount': requestedAmount,
        'purpose': purpose,
      };
}
