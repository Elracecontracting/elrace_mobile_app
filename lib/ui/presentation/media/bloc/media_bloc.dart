import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/media_model.dart';
import '../repository/i_media_repository.dart';

part 'media_event.dart';
part 'media_state.dart';

class MediaBloc extends Bloc<MediaEvent, MediaState> {
  final IMediaRepository mediaRepository;

  static MediaBloc get(BuildContext context) => BlocProvider.of(context);

  MediaBloc({required this.mediaRepository}) : super(MediaInitial()) {
    on<FetchMediaList>(_fetchMediaList);
    on<FetchMediaByType>(_fetchMediaByType);
    on<AddMedia>(_addMedia);
    on<UpdateMedia>(_updateMedia);
    on<DeleteMedia>(_deleteMedia);
  }

  Future<void> _fetchMediaList(
    FetchMediaList event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());
      final mediaList = await mediaRepository.getMediaList();
      emit(MediaLoaded(mediaList));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  Future<void> _fetchMediaByType(
    FetchMediaByType event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaLoading());
      final mediaList = await mediaRepository.getMediaByType(event.type);
      emit(MediaLoaded(mediaList));
    } catch (e) {
      emit(MediaError(e.toString()));
    }
  }

  Future<void> _addMedia(
    AddMedia event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaActionLoading());
      await mediaRepository.addMedia(event.media);
      emit(MediaActionSuccess());
      add(const FetchMediaList());
    } catch (e) {
      emit(MediaActionError(e.toString()));
    }
  }

  Future<void> _updateMedia(
    UpdateMedia event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaActionLoading());
      await mediaRepository.updateMedia(event.media);
      emit(MediaActionSuccess());
      add(const FetchMediaList());
    } catch (e) {
      emit(MediaActionError(e.toString()));
    }
  }

  Future<void> _deleteMedia(
    DeleteMedia event,
    Emitter<MediaState> emit,
  ) async {
    try {
      emit(MediaActionLoading());
      await mediaRepository.deleteMedia(event.mediaId);
      emit(MediaActionSuccess());
      add(const FetchMediaList());
    } catch (e) {
      emit(MediaActionError(e.toString()));
    }
  }
} 