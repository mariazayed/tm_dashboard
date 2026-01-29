import 'package:intl/intl.dart';

import '../enums/capital_reason_enum.dart';

class CapitalModel {
  final DateTime dateTime;
  final double amount;
  final CapitalReasonEnum reason;
  String? notes;

  CapitalModel({
    required this.dateTime,
    required this.reason,
    required this.amount,
    this.notes,
  });

  factory CapitalModel.fromJson(Map<String, dynamic> json) {
    return CapitalModel(
      dateTime: DateTime.parse(json['dateTime']),
      amount: (json['amount'] as num).toDouble(),
      reason: CapitalReasonEnum.fromValue(json['reason']),
      notes: json['notes'] ?? "",
    );
  }

  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');


  Map<String, dynamic> toJson() => {
    'dateTime': formatter.format(dateTime),
    'amount': amount,
    'reason': reason.value,
    'notes': notes
  };
}
