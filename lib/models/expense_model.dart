import 'package:intl/intl.dart';

import 'expense_reason_model.dart';

class ExpenseModel {
  final int id;
  final DateTime date;
  final double amount;
  final ExpenseReasonModel expenseReason;
  final String? notes;

  ExpenseModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.expenseReason,
    this.notes,
  });

  static final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      expenseReason: ExpenseReasonModel.fromJson(json['expenseReason']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'date': _formatter.format(date),
    'amount': amount,
    'expenseReasonId': expenseReason.id,
    'notes': notes,
  };

  Map<String, dynamic> toUpdateJson() => {
    'date': _formatter.format(date),
    'amount': amount,
    'expenseReasonId': expenseReason.id,
    'notes': notes,
  };

  ExpenseModel copyWith({
    DateTime? date,
    double? amount,
    ExpenseReasonModel? expenseReason,
    String? notes,
  }) {
    return ExpenseModel(
      id: id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      expenseReason: expenseReason ?? this.expenseReason,
      notes: notes ?? this.notes,
    );
  }
}
