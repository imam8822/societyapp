class TransactionDto {
  final int id;
  final DateTime createdAt;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? remarks;
  final int? userId;
  final String? userName;
  final String? userPhone;
  final int? referenceId;

  TransactionDto({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.remarks,
    this.userId,
    this.userName,
    this.userPhone,
    this.referenceId,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
        id: json['id'],
        createdAt: DateTime.parse(json['createdAt']).toLocal(),
        type: json['type'],
        amount: (json['amount'] as num).toDouble(),
        balanceAfter: (json['balanceAfter'] as num).toDouble(),
        remarks: json['remarks'],
        userId: json['userId'],
        userName: json['userName'],
        userPhone: json['userPhone'],
        referenceId: json['referenceId'],
      );
}

class TransactionStatsDto {
  final double totalIncomeThisMonth;
  final double totalOutflowThisMonth;
  final List<MonthlyStatDto> monthlyStats;

  TransactionStatsDto({
    required this.totalIncomeThisMonth,
    required this.totalOutflowThisMonth,
    required this.monthlyStats,
  });

  factory TransactionStatsDto.fromJson(Map<String, dynamic> json) {
    return TransactionStatsDto(
      totalIncomeThisMonth: (json['totalIncomeThisMonth'] as num).toDouble(),
      totalOutflowThisMonth: (json['totalOutflowThisMonth'] as num).toDouble(),
      monthlyStats: (json['monthlyStats'] as List)
          .map((e) => MonthlyStatDto.fromJson(e))
          .toList(),
    );
  }
}

class MonthlyStatDto {
  final String month;
  final double income;
  final double outflow;

  MonthlyStatDto({
    required this.month,
    required this.income,
    required this.outflow,
  });

  factory MonthlyStatDto.fromJson(Map<String, dynamic> json) => MonthlyStatDto(
        month: json['month'],
        income: (json['income'] as num).toDouble(),
        outflow: (json['outflow'] as num).toDouble(),
      );
}
