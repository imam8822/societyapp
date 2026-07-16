// Enums for standardizing string constants across the application

enum LoanStatus {
  pending('Pending'),
  approved('Approved'),
  disbursed('Disbursed'),
  repaid('Repaid'),
  rejected('Rejected');

  final String value;
  const LoanStatus(this.value);
}

enum LeaveRequestStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String value;
  const LeaveRequestStatus(this.value);
}

enum TransactionType {
  contribution('Contribution'),
  loanDisbursement('LoanDisbursement'),
  loanRepayment('LoanRepayment'),
  refund('Refund'),
  expense('Expense'),
  adjustment('Adjustment'),
  systemSyncCorrection('SystemSyncCorrection');

  final String value;
  const TransactionType(this.value);
}

enum VerificationStatus {
  pending('Pending'),
  verified('Verified'),
  rejected('Rejected');

  final String value;
  const VerificationStatus(this.value);
}
