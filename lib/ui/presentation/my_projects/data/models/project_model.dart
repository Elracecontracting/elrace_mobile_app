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
    int? differenceDays,
    String? projectManagerPhoto,
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
          differenceDays: differenceDays,
          projectManagerPhoto: projectManagerPhoto,
        );

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Debug print to check the values
    print(
        '🔍 difference_days: ${json['difference_days']} (${json['difference_days'].runtimeType})');
    print('🔍 project_manager_photo: ${json['project_manager_photo']}');

    return ProjectModel(
      projectId: json['project_id'] ?? 0,
      partnerId: json['partner_id'].toString(),
      agreementId: json['agreement_id'].toString(),
      woRefNo: json['wo_ref_no'] ?? '',
      name: json['name']?.toString() ?? '',
      woAmount: (json['wo_amount'] as num?)?.toDouble() ?? 0.0,
      projectStatus: json['project_status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      dateStart: json['date_start']?.toString() ?? '',
      differenceDays: json['difference_days'] as int?,
      projectManagerPhoto: json['project_manager_photo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'partner_id': partnerId,
      'agreement_id': agreementId,
      'wo_ref_no': woRefNo,
      'name': name,
      'wo_amount': woAmount,
      'project_status': projectStatus,
      'date': date,
      'date_start': dateStart,
      'difference_days': differenceDays,
      'project_manager_photo': projectManagerPhoto,
    };
  }
}
