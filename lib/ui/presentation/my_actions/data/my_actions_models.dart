class MyActionsType {
  final String apiValue;
  final String responseKey;

  const MyActionsType._(this.apiValue, this.responseKey);

  static const invoice = MyActionsType._('invoice', 'invoice');
  static const rfq = MyActionsType._('rfq', 'rfq');
  static const hr = MyActionsType._('hr', 'hr');
  // API type is "ptsh" but response key is "petty_cash".
  static const ptsh = MyActionsType._('ptsh', 'petty_cash');
}

class MyActionItem {
  final int id;
  final String name;
  final String? project;
  final String? vendor;
  final double? amountTotal;
  final String? requestType;
  final String status;
  final String employeeName;
  final String employeeImage;

  const MyActionItem({
    required this.id,
    required this.name,
    required this.status,
    required this.employeeName,
    required this.employeeImage,
    this.project,
    this.vendor,
    this.amountTotal,
    this.requestType,
  });

  factory MyActionItem.fromJson(Map<String, dynamic> json) {
    return MyActionItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      project: json['project']?.toString(),
      vendor: json['vendor']?.toString(),
      amountTotal: (json['amount_total'] as num?)?.toDouble(),
      requestType: json['request_type']?.toString(),
      status: json['status']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      employeeImage: json['employee_image']?.toString() ?? '',
    );
  }
}
