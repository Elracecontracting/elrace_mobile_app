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
    required this.message,
    required this.data,
  });

  final String status;
  final String message;
  final List<AttendanceData> data;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    status: json["status"],
    message: json["message"],
    data: List<AttendanceData>.from(
        json["data"].map((x) => AttendanceData.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

class AttendanceData {
  AttendanceData({
    required this.checkIn,
    required this.checkOut,
    required this.workedHours,
  });

  final String checkIn;
  final dynamic checkOut;
  final double workedHours;

  factory AttendanceData.fromJson(Map<String, dynamic> json) => AttendanceData(
    checkIn: json["check_in"],
    checkOut: json["check_out"],
    workedHours: json["worked_hours"].toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "check_in": checkIn,
    "check_out": checkOut,
    "worked_hours": workedHours,
  };
}
