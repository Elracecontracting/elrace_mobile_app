import 'package:el_race/ui/presentation/my_projects/domain/entities/project_entity.dart';

class ProjectModel extends ProjectEntity {
  const ProjectModel({
    required int projectId,
    required String partnerId,
    required String agreementId,
    required String woRefNo,
    required String name,
    required double woAmount,
    required String projectStatus,
    required String date,
    required String dateStart,
  }) : super(
          projectId: projectId,
          partnerId: partnerId,
          agreementId: agreementId,
          woRefNo: woRefNo,
          name: name,
          woAmount: woAmount,
          projectStatus: projectStatus,
          date: date,
          dateStart: dateStart,
        );

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      projectId: json['project_id']??0,
      partnerId: json['partner_id'].toString(),
      agreementId: json['agreement_id'].toString(),
      woRefNo: json['wo_ref_no'],
      name: json['name'].toString(),
      woAmount: (json['wo_amount'] as num).toDouble(),
      projectStatus: json['project_status'].toString(),
      date: json['date'].toString(),
      dateStart: json['date_start'].toString(),
    );
  }
}