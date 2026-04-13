String _readRequestDate(Map<String, dynamic> json) {
  final dynamic value = json['request_date'] ??
      json['date'] ??
      json['create_date'] ??
      json['created_at'] ??
      json['approval_date'];
  return value?.toString() ?? '';
}

int _readIntFromKeys(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

List<dynamic> _readListFromKeys(
    Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is List) return value;
  }
  return const [];
}

/// Model for a single delayed HR approval item
class DelayedHrItem {
  final int id;
  final String name;
  final String requestType;
  final String validatorName;
  final String validatorEmpId;
  final String validatorImage;
  final String requestDate;
  final int daysDelayed;

  DelayedHrItem({
    required this.id,
    required this.name,
    required this.requestType,
    required this.validatorName,
    required this.validatorEmpId,
    required this.validatorImage,
    required this.requestDate,
    this.daysDelayed = 0,
  });

  factory DelayedHrItem.fromJson(Map<String, dynamic> json) {
    return DelayedHrItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      requestType: json['request_type'] ?? '',
      validatorName:
          (json['reviewer_name'] ?? json['validator_name'] ?? '').toString(),
      validatorEmpId:
          (json['reviewer_emp_id'] ?? json['validator_emp_id'] ?? '')
              .toString(),
      validatorImage:
          (json['reviewer_image'] ?? json['validator_image'] ?? '').toString(),
      requestDate: _readRequestDate(json),
      daysDelayed: json['delay_days'] ?? json['days_delayed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'request_type': requestType,
      'validator_name': validatorName,
      'validator_emp_id': validatorEmpId,
      'validator_image': validatorImage,
      'request_date': requestDate,
      'days_delayed': daysDelayed,
    };
  }
}

/// Model for a single delayed RFQ item
class DelayedRfqItem {
  final int id;
  final String name;
  final String project;
  final String reviewerName;
  final String reviewerEmpId;
  final String reviewerImage;
  final String requestDate;
  final int daysDelayed;

  DelayedRfqItem({
    required this.id,
    required this.name,
    required this.project,
    required this.reviewerName,
    required this.reviewerEmpId,
    required this.reviewerImage,
    required this.requestDate,
    this.daysDelayed = 0,
  });

  factory DelayedRfqItem.fromJson(Map<String, dynamic> json) {
    return DelayedRfqItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      project: json['project'] ?? '',
      reviewerName: json['reviewer_name'] ?? '',
      reviewerEmpId: json['reviewer_emp_id']?.toString() ?? '',
      reviewerImage: json['reviewer_image'] ?? '',
      requestDate: _readRequestDate(json),
      daysDelayed: json['delay_days'] ?? json['days_delayed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'project': project,
      'reviewer_name': reviewerName,
      'reviewer_emp_id': reviewerEmpId,
      'reviewer_image': reviewerImage,
      'request_date': requestDate,
      'days_delayed': daysDelayed,
    };
  }
}

/// Model for a single delayed Invoice item
class DelayedInvoiceItem {
  final int id;
  final String name;
  final String project;
  final String reviewerName;
  final String reviewerEmpId;
  final String reviewerImage;
  final String requestDate;
  final int daysDelayed;

  DelayedInvoiceItem({
    required this.id,
    required this.name,
    required this.project,
    required this.reviewerName,
    required this.reviewerEmpId,
    required this.reviewerImage,
    required this.requestDate,
    this.daysDelayed = 0,
  });

  factory DelayedInvoiceItem.fromJson(Map<String, dynamic> json) {
    return DelayedInvoiceItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      project: json['project'] ?? '',
      reviewerName: json['reviewer_name'] ?? '',
      reviewerEmpId: json['reviewer_emp_id']?.toString() ?? '',
      reviewerImage: json['reviewer_image'] ?? '',
      requestDate: _readRequestDate(json),
      daysDelayed: json['delay_days'] ?? json['days_delayed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'project': project,
      'reviewer_name': reviewerName,
      'reviewer_emp_id': reviewerEmpId,
      'reviewer_image': reviewerImage,
      'request_date': requestDate,
      'days_delayed': daysDelayed,
    };
  }
}

/// Model for a single delayed Petty Cash item
class DelayedPettyCashItem {
  final int id;
  final String name;
  final String project;
  final String reviewerName;
  final String reviewerEmpId;
  final String reviewerImage;
  final String requestDate;
  final int daysDelayed;

  DelayedPettyCashItem({
    required this.id,
    required this.name,
    required this.project,
    required this.reviewerName,
    required this.reviewerEmpId,
    required this.reviewerImage,
    required this.requestDate,
    this.daysDelayed = 0,
  });

  factory DelayedPettyCashItem.fromJson(Map<String, dynamic> json) {
    return DelayedPettyCashItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      project: json['project'] ?? '',
      reviewerName: json['reviewer_name'] ?? '',
      reviewerEmpId: json['reviewer_emp_id']?.toString() ?? '',
      reviewerImage: json['reviewer_image'] ?? '',
      requestDate: _readRequestDate(json),
      daysDelayed: json['delay_days'] ?? json['days_delayed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'project': project,
      'reviewer_name': reviewerName,
      'reviewer_emp_id': reviewerEmpId,
      'reviewer_image': reviewerImage,
      'request_date': requestDate,
      'days_delayed': daysDelayed,
    };
  }
}

/// Main response model for delayed approvals API
class DelayedApprovalsResponse {
  final String status;
  final String message;
  final List<DelayedHrItem> hrItems;
  final List<DelayedRfqItem> rfqItems;
  final List<DelayedInvoiceItem> invoiceItems;
  final List<DelayedPettyCashItem> pettyCashItems;

  DelayedApprovalsResponse({
    required this.status,
    required this.message,
    required this.hrItems,
    required this.rfqItems,
    required this.invoiceItems,
    required this.pettyCashItems,
  });

  factory DelayedApprovalsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] ?? {};
    final data = result['data'] ?? {};
    final mapData = data is Map<String, dynamic> ? data : <String, dynamic>{};

    return DelayedApprovalsResponse(
      status: result['status'] ?? '',
      message: result['message'] ?? '',
      hrItems: _readListFromKeys(mapData, ['hr', 'human_resources'])
          .map((item) => DelayedHrItem.fromJson(item))
          .toList(),
      rfqItems: _readListFromKeys(mapData, ['rfq', 'rfqs'])
          .map((item) => DelayedRfqItem.fromJson(item))
          .toList(),
      invoiceItems: _readListFromKeys(mapData, ['invoice', 'invoices'])
          .map((item) => DelayedInvoiceItem.fromJson(item))
          .toList(),
      pettyCashItems: _readListFromKeys(mapData, ['petty_cash', 'pettycash'])
          .map((item) => DelayedPettyCashItem.fromJson(item))
          .toList(),
    );
  }

  int get totalCount =>
      hrItems.length +
      rfqItems.length +
      invoiceItems.length +
      pettyCashItems.length;

  bool get isEmpty =>
      hrItems.isEmpty &&
      rfqItems.isEmpty &&
      invoiceItems.isEmpty &&
      pettyCashItems.isEmpty;

  /// Returns all delayed items as normalized card maps ready for display.
  List<Map<String, dynamic>> toCardItems() {
    final List<Map<String, dynamic>> items = [];

    for (final item in hrItems) {
      items.add({
        'type': 'HR',
        'id': item.id,
        'reqNo': item.name,
        'requestType': item.requestType,
        'employeeName': item.validatorName,
        'empCode': item.validatorEmpId,
        'requestDate': item.requestDate,
        'employeeImageUrl': item.validatorImage,
        'daysDelayed': item.daysDelayed,
      });
    }
    for (final item in rfqItems) {
      items.add({
        'type': 'RFQ',
        'id': item.id,
        'reqNo': item.name,
        'requestType': item.project,
        'employeeName': item.reviewerName,
        'empCode': item.reviewerEmpId,
        'requestDate': item.requestDate,
        'employeeImageUrl': item.reviewerImage,
        'daysDelayed': item.daysDelayed,
      });
    }
    for (final item in invoiceItems) {
      items.add({
        'type': 'INVOICE',
        'id': item.id,
        'reqNo': item.name,
        'requestType': item.project,
        'employeeName': item.reviewerName,
        'empCode': item.reviewerEmpId,
        'requestDate': item.requestDate,
        'employeeImageUrl': item.reviewerImage,
        'daysDelayed': item.daysDelayed,
      });
    }
    for (final item in pettyCashItems) {
      items.add({
        'type': 'PETTY CASH',
        'id': item.id,
        'reqNo': item.name,
        'requestType': item.project,
        'employeeName': item.reviewerName,
        'empCode': item.reviewerEmpId,
        'requestDate': item.requestDate,
        'employeeImageUrl': item.reviewerImage,
        'daysDelayed': item.daysDelayed,
      });
    }

    return items;
  }
}

/// Counters-only response from /api/my_delayed_approvals/counters
class DelayedCountersResponse {
  final int hrCount;
  final int rfqCount;
  final int invoiceCount;
  final int pettyCashCount;

  DelayedCountersResponse({
    required this.hrCount,
    required this.rfqCount,
    required this.invoiceCount,
    required this.pettyCashCount,
  });

  int get totalCount => hrCount + rfqCount + invoiceCount + pettyCashCount;

  factory DelayedCountersResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] ?? {};
    final data = result['data'] ?? {};
    final mapData = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final countersMap = mapData['counters'] is Map<String, dynamic>
        ? mapData['counters'] as Map<String, dynamic>
        : mapData;
    return DelayedCountersResponse(
      hrCount: _readIntFromKeys(countersMap, [
        'hr',
        'human_resources',
        'hr_count',
      ]),
      rfqCount: _readIntFromKeys(countersMap, [
        'rfq',
        'rfqs',
        'rfq_count',
      ]),
      invoiceCount: _readIntFromKeys(countersMap, [
        'invoice',
        'invoices',
        'invoice_count',
        'invoices_count',
      ]),
      pettyCashCount: _readIntFromKeys(countersMap, [
        'petty_cash',
        'pettycash',
        'petty_cash_count',
        'pettycash_count',
      ]),
    );
  }
}

/// Details response from /api/my_delayed_approvals/details?type=...
/// Returns a normalized list of cards for the requested category.
class DelayedDetailsResponse {
  final String type;
  final List<DelayedHrItem> hrItems;
  final List<DelayedRfqItem> rfqItems;
  final List<DelayedInvoiceItem> invoiceItems;
  final List<DelayedPettyCashItem> pettyCashItems;

  DelayedDetailsResponse({
    required this.type,
    this.hrItems = const [],
    this.rfqItems = const [],
    this.invoiceItems = const [],
    this.pettyCashItems = const [],
  });

  factory DelayedDetailsResponse.fromJson(
      Map<String, dynamic> json, String type) {
    final result = json['result'] ?? {};
    final data = result['data'] ?? {};

    // Backend may return the list under the type key, or directly as a list
    List<dynamic> rawList = [];
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      final mapData = data.cast<String, dynamic>();
      if (type.toLowerCase() == 'invoice') {
        rawList = _readListFromKeys(mapData, ['invoice', 'invoices']);
      } else if (type.toLowerCase() == 'hr') {
        rawList = _readListFromKeys(mapData, ['hr', 'human_resources']);
      } else if (type.toLowerCase() == 'rfq') {
        rawList = _readListFromKeys(mapData, ['rfq', 'rfqs']);
      } else if (type.toLowerCase() == 'petty_cash') {
        rawList = _readListFromKeys(mapData, ['petty_cash', 'pettycash']);
      } else {
        rawList = (mapData[type] as List<dynamic>?) ?? [];
      }
    }

    switch (type.toLowerCase()) {
      case 'hr':
        return DelayedDetailsResponse(
          type: type,
          hrItems: rawList
              .map((e) => DelayedHrItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'rfq':
        return DelayedDetailsResponse(
          type: type,
          rfqItems: rawList
              .map((e) => DelayedRfqItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'invoice':
        return DelayedDetailsResponse(
          type: type,
          invoiceItems: rawList
              .map(
                  (e) => DelayedInvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'petty_cash':
        return DelayedDetailsResponse(
          type: type,
          pettyCashItems: rawList
              .map((e) =>
                  DelayedPettyCashItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      default:
        return DelayedDetailsResponse(type: type);
    }
  }

  /// Returns the items as normalized card maps ready for display.
  List<Map<String, dynamic>> toCardItems() {
    final List<Map<String, dynamic>> items = [];

    for (final item in hrItems) {
      items.add({
        'type': 'HR',
        'id': item.id,
        'reqNo': item.name,
        'requestType': item.requestType,
        'employeeName': item.validatorName,
        'empCode': item.validatorEmpId,
        'requestDate': item.requestDate,
        'employeeImageUrl': item.validatorImage,
        'daysDelayed': item.daysDelayed,
      });
    }
    for (final item in rfqItems) {
      items.add({
        'type': 'RFQ',
        'id': item.id,
        'reqNo': item.name,
        'requestType': item.project,
        'employeeName': item.reviewerName,
        'empCode': item.reviewerEmpId,
        'requestDate': item.requestDate,
        'employeeImageUrl': item.reviewerImage,
        'daysDelayed': item.daysDelayed,
      });
    }
    for (final item in invoiceItems) {
      items.add({
        'type': 'INVOICE',
        'id': item.id,
        'reqNo': item.name,
        'requestType': item.project,
        'employeeName': item.reviewerName,
        'empCode': item.reviewerEmpId,
        'requestDate': item.requestDate,
        'employeeImageUrl': item.reviewerImage,
        'daysDelayed': item.daysDelayed,
      });
    }
    for (final item in pettyCashItems) {
      items.add({
        'type': 'PETTY CASH',
        'id': item.id,
        'reqNo': item.name,
        'requestType': item.project,
        'employeeName': item.reviewerName,
        'empCode': item.reviewerEmpId,
        'requestDate': item.requestDate,
        'employeeImageUrl': item.reviewerImage,
        'daysDelayed': item.daysDelayed,
      });
    }
    return items;
  }
}
