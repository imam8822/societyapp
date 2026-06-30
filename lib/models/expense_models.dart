class ExpenseDto {
  final int id;
  final String title;
  final String? description;
  final double amount;
  final DateTime dateIncurred;
  final String addedByName;

  ExpenseDto({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.dateIncurred,
    required this.addedByName,
  });

  factory ExpenseDto.fromJson(Map<String, dynamic> json) {
    return ExpenseDto(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      dateIncurred: DateTime.parse(json['dateIncurred']),
      addedByName: json['addedByName'],
    );
  }
}
