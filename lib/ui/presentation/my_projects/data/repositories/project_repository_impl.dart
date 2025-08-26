import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:el_race/ui/presentation/my_projects/data/models/project_model.dart';
import 'package:el_race/ui/presentation/my_projects/domain/entities/attachment_entity.dart';
import 'package:el_race/ui/presentation/my_projects/domain/entities/project_entity.dart';
import 'package:el_race/ui/presentation/my_projects/domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource remoteDataSource;

  ProjectRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ProjectEntity>> getProjects() async {
    final List<ProjectModel> models = await remoteDataSource.fetchProjects();
    return models.map((model) => ProjectEntity(
          projectId: model.projectId,
          partnerId: model.partnerId,
          agreementId: model.agreementId,
          woRefNo: model.woRefNo,
          name: model.name,
          woAmount: model.woAmount,
          projectStatus: model.projectStatus,
          date: model.date,
          dateStart: model.dateStart,
        )).toList();
  }

  @override
  Future<List<AttachmentEntity>> getProjectAttachement(String projectID) async{
    final List<AttachmentEntity> models = await remoteDataSource.fetchProjectAttachments(projectID);
    return models.map((model) => AttachmentEntity(
          name: model.name,
          type: model.type, 
          url: model.url, 
          source: model.source, 
          isFile: model.isFile, 
          folder: model.folder, 
          id: model.id,
        )).toList();
  }
}
