part of 'media_bloc.dart';

sealed class MediaEvent extends Equatable {
  const MediaEvent();

  @override
  List<Object> get props => [];
}

final class FetchMediaList extends MediaEvent {
  const FetchMediaList();
}

final class FetchMediaByType extends MediaEvent {
  final MediaType type;
  const FetchMediaByType(this.type);
  
  @override
  List<Object> get props => [type];
}

final class AddMedia extends MediaEvent {
  final MediaModel media;
  const AddMedia(this.media);
  
  @override
  List<Object> get props => [media];
}

final class UpdateMedia extends MediaEvent {
  final MediaModel media;
  const UpdateMedia(this.media);
  
  @override
  List<Object> get props => [media];
}

final class DeleteMedia extends MediaEvent {
  final String mediaId;
  const DeleteMedia(this.mediaId);
  
  @override
  List<Object> get props => [mediaId];
} 