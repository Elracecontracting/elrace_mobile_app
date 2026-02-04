abstract class ProjectListEvent {}

class LoadProjectsEvent extends ProjectListEvent {
  final bool refresh;
  LoadProjectsEvent({this.refresh = false});
}

class LoadProjectsByPartnerEvent extends ProjectListEvent {
  final int partnerId;
  final bool refresh;

  LoadProjectsByPartnerEvent({required this.partnerId, this.refresh = false});
}

class GetProjectAttachmentsEvent extends ProjectListEvent {
  final String projectId;
  final String? folderType;

  GetProjectAttachmentsEvent(this.projectId, {this.folderType});
}

class LoadMoreProjectsEvent extends ProjectListEvent {}
