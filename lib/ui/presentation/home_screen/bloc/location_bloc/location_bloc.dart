import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:el_race/ui/presentation/landing_screen/repository/location_reop.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

part 'location_event.dart';
part 'location_state.dart';

LocationRepo _locationRepo = LocationRepo();

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationInitial()) {
    on<LocationEvent>((event, emit) {
    });

    on<GetCurrentLocationET>(getCurrentLocationMethod);
  }

  FutureOr<void> getCurrentLocationMethod(
      GetCurrentLocationET event, Emitter<LocationState> emit) async {
    Position _location = await _locationRepo.getCurrentLocation();

    log('_location.latitude ${_location.latitude}');
    log('_location.longitude ${_location.longitude}');
  }
}
