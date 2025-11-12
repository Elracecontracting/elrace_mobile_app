// To parse this JSON data, do
//
//     final employeeModel = employeeModelFromJson(jsonString);

import 'dart:convert';

EmployeeModel employeeModelFromJson(String str) =>
    EmployeeModel.fromJson(json.decode(str));

String employeeModelToJson(EmployeeModel data) => json.encode(data.toJson());

class EmployeeModel {
  final String? jsonrpc;
  final dynamic id;
  final Result? result;

  EmployeeModel({
    this.jsonrpc,
    this.id,
    this.result,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: json["result"] == null ? null : Result.fromJson(json["result"]),
      );

  Map<String, dynamic> toJson() => {
        "jsonrpc": jsonrpc,
        "id": id,
        "result": result?.toJson(),
      };
}

class Result {
  final List<Employee>? employees;

  Result({
    this.employees,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        employees: json["employees"] == null
            ? []
            : List<Employee>.from(
                json["employees"]!.map((x) => Employee.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "employees": employees == null
            ? []
            : List<dynamic>.from(employees!.map((x) => x.toJson())),
      };
}

class Employee {
  final int? id;
  final String? name;
  final dynamic mobilePhone;
  final dynamic jobId;
  final String? profilePhotoUrl;

  Employee({
    this.id,
    this.name,
    this.mobilePhone,
    this.jobId,
    this.profilePhotoUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json["id"],
        name: json["name"],
        mobilePhone: json["mobile_phone"],
        jobId: json["job_id"],
        profilePhotoUrl: json["profile_photo_url"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "mobile_phone": mobilePhone,
        "job_id": jobId,
        "profile_photo_url": profilePhotoUrl,
      };
}
