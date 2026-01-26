/// Model for a single delayed HR approval item
class DelayedHrItem {
  final int id;
  final String name;
  final String requestType;
  final String validatorName;
  final String validatorEmpId;
  final String validatorImage;
  final int daysDelayed;

  DelayedHrItem({
    required this.id,
    required this.name,
    required this.requestType,
    required this.validatorName,
    required this.validatorEmpId,
    required this.validatorImage,
    this.daysDelayed = 0,
  });

  factory DelayedHrItem.fromJson(Map<String, dynamic> json) {
    return DelayedHrItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      requestType: json['request_type'] ?? '',
      validatorName: json['validator_name'] ?? '',
      validatorEmpId: json['validator_emp_id']?.toString() ?? '',
      validatorImage: json['validator_image'] ?? '',
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
  final int daysDelayed;

  DelayedRfqItem({
    required this.id,
    required this.name,
    required this.project,
    required this.reviewerName,
    required this.reviewerEmpId,
    required this.reviewerImage,
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
  final int daysDelayed;

  DelayedInvoiceItem({
    required this.id,
    required this.name,
    required this.project,
    required this.reviewerName,
    required this.reviewerEmpId,
    required this.reviewerImage,
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
  final int daysDelayed;

  DelayedPettyCashItem({
    required this.id,
    required this.name,
    required this.project,
    required this.reviewerName,
    required this.reviewerEmpId,
    required this.reviewerImage,
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

    return DelayedApprovalsResponse(
      status: result['status'] ?? '',
      message: result['message'] ?? '',
      hrItems: (data['hr'] as List<dynamic>?)
              ?.map((item) => DelayedHrItem.fromJson(item))
              .toList() ??
          [],
      rfqItems: (data['rfq'] as List<dynamic>?)
              ?.map((item) => DelayedRfqItem.fromJson(item))
              .toList() ??
          [],
      invoiceItems: (data['invoice'] as List<dynamic>?)
              ?.map((item) => DelayedInvoiceItem.fromJson(item))
              .toList() ??
          [],
      pettyCashItems: (data['petty_cash'] as List<dynamic>?)
              ?.map((item) => DelayedPettyCashItem.fromJson(item))
              .toList() ??
          [],
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
}
