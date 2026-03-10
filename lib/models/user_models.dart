class UserSummary {
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final bool isActive;
  final DateTime joinedDate;
  final String? address;
  final int? referredById;
  final String? referredByName;
  final double preExistingInvestment;
  final double totalContributed;
  final double totalInvested;       // preExisting + contributed
  final int totalContributions;
  final double pendingAmount;       // live: missed months × rate + penalties
  final int unpaidMonthsCount;
  final bool hasActiveLoan;
  final double activeLoanAmount;
  final double loanAmountToRepay;
  final DateTime? nextInstallmentDueDate;
  final double nextInstallmentAmount;
  final bool isEligibleForLoan;
  final bool guarantorRequired;
  final bool isGuaranteeingActiveLoan;

  UserSummary({
    required this.id, required this.fullName, required this.phone,
    required this.email, required this.role, required this.isActive,
    required this.joinedDate, this.address, this.referredById, this.referredByName,
    required this.preExistingInvestment,
    required this.totalContributed, required this.totalInvested,
    required this.totalContributions, required this.pendingAmount,
    required this.unpaidMonthsCount, required this.hasActiveLoan,
    required this.activeLoanAmount, required this.loanAmountToRepay,
    this.nextInstallmentDueDate, required this.nextInstallmentAmount,
    required this.isEligibleForLoan, required this.guarantorRequired,
    required this.isGuaranteeingActiveLoan,
  });

  factory UserSummary.fromJson(Map<String, dynamic> j) => UserSummary(
    id: j['id'],
    fullName: j['fullName'],
    phone: j['phone'],
    email: j['email'] ?? '',
    role: j['role'] is int ? (j['role'] == 0 ? 'Admin' : 'User') : '${j['role']}',
    isActive: j['isActive'] ?? true,
    joinedDate: DateTime.parse(j['joinedDate']),
    address: j['address'],
    referredById: j['referredById'],
    referredByName: j['referredByName'],
    preExistingInvestment: (j['preExistingInvestment'] as num?)?.toDouble() ?? 0,
    totalContributed: (j['totalContributed'] as num?)?.toDouble() ?? 0,
    totalInvested: (j['totalInvested'] as num?)?.toDouble() ?? 0,
    totalContributions: j['totalContributions'] ?? 0,
    pendingAmount: (j['pendingAmount'] as num?)?.toDouble() ?? 0,
    unpaidMonthsCount: j['unpaidMonthsCount'] ?? 0,
    hasActiveLoan: j['hasActiveLoan'] ?? false,
    activeLoanAmount: (j['activeLoanAmount'] as num?)?.toDouble() ?? 0,
    loanAmountToRepay: (j['loanAmountToRepay'] as num?)?.toDouble() ?? 0,
    nextInstallmentDueDate: j['nextInstallmentDueDate'] != null
        ? DateTime.parse(j['nextInstallmentDueDate']) : null,
    nextInstallmentAmount: (j['nextInstallmentAmount'] as num?)?.toDouble() ?? 0,
    isEligibleForLoan: j['isEligibleForLoan'] ?? false,
    guarantorRequired: j['guarantorRequired'] ?? true,
    isGuaranteeingActiveLoan: j['isGuaranteeingActiveLoan'] ?? false,
  );
}

class CreateUserRequest {
  final String fullName, phone, password;
  final double preExistingInvestment;
  final DateTime joinedDate;
  final String? email;
  final double pendingAmount;
  final int? referredById;

  CreateUserRequest({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.preExistingInvestment,
    required this.joinedDate,
    this.email,
    this.pendingAmount = 0,
    this.referredById,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'password': password,
    'preExistingInvestment': preExistingInvestment,
    'joinedDate': joinedDate.toIso8601String(),
    if (email != null) 'email': email,
    'pendingAmount': pendingAmount,
    if (referredById != null) 'referredById': referredById,
    'role': 1, // User by default
  };
}

class UserDropdownItem {
  final int id;
  final String fullName, phone;
  UserDropdownItem({required this.id, required this.fullName, required this.phone});
  factory UserDropdownItem.fromJson(Map<String, dynamic> j) =>
      UserDropdownItem(id: j['id'], fullName: j['fullName'], phone: j['phone']);
}