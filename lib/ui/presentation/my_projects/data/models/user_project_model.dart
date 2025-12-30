class UserProjectModel {
  final int projectId;
  final String projectName;

  const UserProjectModel({
    required this.projectId,
    required this.projectName,
  });

  factory UserProjectModel.fromJson(Map<String, dynamic> json) {
    final idValue = json['project_id'];
    return UserProjectModel(
      projectId: idValue is int
          ? idValue
          : int.tryParse(idValue?.toString() ?? '') ?? 0,
      projectName: json['project_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'project_id': projectId,
      'project_name': projectName,
    };
  }
}
