abstract class ProjectListEvent {}

class LoadProjectsEvent extends ProjectListEvent {
  final bool refresh;
  LoadProjectsEvent({this.refresh = false});
}

class GetProjectAttachmentsEvent extends ProjectListEvent {
  final String projectId;

  GetProjectAttachmentsEvent(this.projectId);
}

class LoadMoreProjectsEvent extends ProjectListEvent {}
