class UserSummary {
  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final bool isActive;
  final DateTime joinedDate;
  final String? address;
  final String? referredBy;
  final double monthlyContributionAmount;
  final double penaltyPerMissedMonth;
  final int totalContributions;
  final double totalSaved;
  final bool isEligibleForLoan;
  final bool guarantorRequired;
  final bool hasActiveLoan;
  final bool isGuaranteeingActiveLoan;

  UserSummary({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.isActive,
    required this.joinedDate,
    this.address,
    this.referredBy,
    required this.monthlyContributionAmount,
    required this.penaltyPerMissedMonth,
    required this.totalContributions,
    required this.totalSaved,
    required this.isEligibleForLoan,
    required this.guarantorRequired,
    required this.hasActiveLoan,
    required this.isGuaranteeingActiveLoan,
  });

  factory UserSummary.fromJson(Map<String, dynamic> j) => UserSummary(
        id: j['id'],
        fullName: j['fullName'],
        phone: j['phone'],
        email: j['email'],
        role: j['role'] is int ? (j['role'] == 0 ? 'Admin' : 'User') : j['role'].toString(),
        isActive: j['isActive'],
        joinedDate: DateTime.parse(j['joinedDate']),
        address: j['address'],
        referredBy: j['referredBy'],
        monthlyContributionAmount: (j['monthlyContributionAmount'] as num?)?.toDouble() ?? 500,
        penaltyPerMissedMonth: (j['penaltyPerMissedMonth'] as num?)?.toDouble() ?? 50,
        totalContributions: j['totalContributions'],
        totalSaved: (j['totalSaved'] as num).toDouble(),
        isEligibleForLoan: j['isEligibleForLoan'],
        guarantorRequired: j['guarantorRequired'],
        hasActiveLoan: j['hasActiveLoan'],
        isGuaranteeingActiveLoan: j['isGuaranteeingActiveLoan'],
      );
}

class CreateUserRequest {
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String role;
  final String? address;
  final String? referredBy;
  final double monthlyContributionAmount;
  final double penaltyPerMissedMonth;

  CreateUserRequest({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    this.role = 'User',
    this.address,
    this.referredBy,
    this.monthlyContributionAmount = 500,
    this.penaltyPerMissedMonth = 50,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'password': password,
        'role': role == 'Admin' ? 0 : 1,
        if (address != null) 'address': address,
        if (referredBy != null) 'referredBy': referredBy,
        'monthlyContributionAmount': monthlyContributionAmount,
        'penaltyPerMissedMonth': penaltyPerMissedMonth,
      };
}