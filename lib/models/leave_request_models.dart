class LeaveRequestDto {
  final int id;
  final int userId;
  final String userName;
  final double totalInvested;
  final String reason;
  final String status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedByAdminName;
  final double? refundAmount;
  final String? remarks;

  LeaveRequestDto({
    required this.id,
    required this.userId,
    required this.userName,
    required this.totalInvested,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.processedByAdminName,
    this.refundAmount,
    this.remarks,
  });

  factory LeaveRequestDto.fromJson(Map<String, dynamic> json) {
    return LeaveRequestDto(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'] ?? '',
      totalInvested: (json['totalInvested'] as num).toDouble(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      requestedAt: DateTime.parse(json['requestedAt']),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
      processedByAdminName: json['processedByAdminName'],
      refundAmount: json['refundAmount'] != null ? (json['refundAmount'] as num).toDouble() : null,
      remarks: json['remarks'],
    );
  }
}
