import 'package:el_race/ui/presentation/my_projects/data/models/project_model.dart';
import 'package:el_race/ui/presentation/my_projects/domain/entities/partner_entity.dart';

class PartnerModel extends PartnerEntity {
  final List<ProjectModel> projects;

  const PartnerModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.workOrdersCount,
    required this.projects,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    final projectsList = json['projects'] as List<dynamic>? ?? [];
    final projects =
        projectsList.map((project) => ProjectModel.fromJson(project)).toList();

    return PartnerModel(
      id: json['partner_id'] ?? 0,
      name: json['partner_name'] ?? '',
      icon:
          json['icon'], 
      workOrdersCount: projects.length,
      projects: projects,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partner_id': id,
      'partner_name': name,
      'icon': icon,
      'projects': projects.map((project) => project.toJson()).toList(),
    };
  }
}
