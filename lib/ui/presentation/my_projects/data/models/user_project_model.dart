class UserProjectModel {
  final int projectId;
  final String projectName;
  final int totalProjects;
  final double totalProjectsAmount;
  final String? photoUrl;

  const UserProjectModel({
    required this.projectId,
    required this.projectName,
    required this.totalProjects,
    required this.totalProjectsAmount,
    this.photoUrl,
  });

  factory UserProjectModel.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];

    // Fix malformed photo URL from API (erp.elrace.compublic -> erp.elrace.com/public)
    String? photoUrl = json['photo_url']?.toString();
    if (photoUrl != null && photoUrl.contains('erp.elrace.compublic')) {
      photoUrl =
          photoUrl.replaceAll('erp.elrace.compublic', 'erp.elrace.com/public');
    }

    return UserProjectModel(
      projectId: idValue is int
          ? idValue
          : int.tryParse(idValue?.toString() ?? '') ?? 0,
      projectName: json['name']?.toString() ?? '',
      totalProjects: json['total_projects'] as int? ?? 0,
      totalProjectsAmount:
          (json['total_projects_amount'] as num?)?.toDouble() ?? 0.0,
      photoUrl: photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': projectId,
      'name': projectName,
      'total_projects': totalProjects,
      'total_projects_amount': totalProjectsAmount,
      'photo_url': photoUrl,
    };
  }
}
