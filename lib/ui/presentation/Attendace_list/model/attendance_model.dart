import 'dart:convert';

AttendanceModel attendanceModelFromJson(String str) =>
    AttendanceModel.fromJson(json.decode(str));

String attendanceModelToJson(AttendanceModel data) => json.encode(data.toJson());

class AttendanceModel {
  AttendanceModel({
    required this.result,
  });

  final Result result;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
    result: Result.fromJson(json["result"]),
  );

  Map<String, dynamic> toJson() => {
    "result": result.toJson(),
  };
}

class Result {
  Result({
    required this.status,
    required this.mode,
    required this.total,
    required this.limit,
    required this.offset,
    required this.data,
  });

  final String status;
  final String mode;
  final int total;
  final int limit;
  final int offset;
  final List<AttendanceData> data;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    status: json["status"] ?? "success",
    mode: json["mode"] ?? "flat",
    total: json["total"] ?? 0,
    limit: json["limit"] ?? 50,
    offset: json["offset"] ?? 0,
    data: List<AttendanceData>.from(
        (json["data"] as List? ?? []).map((x) => AttendanceData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "mode": mode,
    "total": total,
    "limit": limit,
    "offset": offset,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class AttendanceData {
  AttendanceData({
    required this.employeeName,
    required this.empId,
    required this.employeeImageUrl,
    required this.checkIn,
    required this.checkOut,
    required this.workedHours,
    required this.isOpen,
  });

  final String employeeName;
  final String empId;
  final String employeeImageUrl;
  final String checkIn;
  final dynamic checkOut;
  final double workedHours;
  final bool isOpen;

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
    employeeName: json["employee_name"] ?? "",
    empId: json["emp_id"] ?? "",
    employeeImageUrl: json["employee_image_url"] ?? "",
    checkIn: json["check_in"] ?? "",
    checkOut: json["check_out"],
    workedHours: (json["worked_hours"] ?? 0.0).toDouble(),
    isOpen: json["is_open"] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "employee_name": employeeName,
    "emp_id": empId,
    "employee_image_url": employeeImageUrl,
    "check_in": checkIn,
    "check_out": checkOut,
    "worked_hours": workedHours,
    "is_open": isOpen,
  };
}
