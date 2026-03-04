class MyActionsType {
  final String apiValue;
  final String responseKey;

  const MyActionsType._(this.apiValue, this.responseKey);

  static const invoice = MyActionsType._('invoice', 'invoice');
  static const rfq = MyActionsType._('rfq', 'rfq');
  static const hr = MyActionsType._('hr', 'hr');
  // API type is "ptsh" but response key is "petty_cash".
  static const ptsh = MyActionsType._('ptsh', 'petty_cash');
  static const signatures = MyActionsType._('signatures', 'signatures');
  static const timesheet = MyActionsType._('timesheet', 'timesheet');
  static const reports = MyActionsType._('reports', 'reports');
}

class MyActionItem {
  final int id;
  final String name;
  final String? reference;
  final String? date;
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
    this.reference,
    this.date,
    this.project,
    this.vendor,
    this.amountTotal,
    this.requestType,
  });

  factory MyActionItem.fromJson(Map<String, dynamic> json) {
    String parseStatus(dynamic rawStatus) {
      if (rawStatus is String) return rawStatus;
      if (rawStatus is Map && rawStatus.isNotEmpty) {
        final first = rawStatus.values.first;
        return first?.toString() ?? '';
      }
      return rawStatus?.toString() ?? '';
    }

    final dynamic amountRaw =
        json['amount_total'] ?? json['amount'] ?? json['total'];
    return MyActionItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['project'] ?? json['request_type'])
              ?.toString() ??
          '',
      reference:
          (json['reference'] ?? json['ref'] ?? json['number'])?.toString(),
      date: (json['date'] ??
              json['last_updated_on'] ??
              json['updated_at'] ??
              json['create_date'])
          ?.toString(),
      project: json['project']?.toString(),
      vendor: json['vendor']?.toString(),
      amountTotal: amountRaw is num
          ? amountRaw.toDouble()
          : double.tryParse(amountRaw?.toString() ?? ''),
      requestType: json['request_type']?.toString(),
      status: parseStatus(json['status']),
      employeeName: json['employee_name']?.toString() ?? '',
      employeeImage: json['employee_image']?.toString() ?? '',
    );
  }
}
