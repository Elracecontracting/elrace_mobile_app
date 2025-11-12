import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:el_race/ui/presentation/signin/data/model.dart';
import 'package:el_race/ui/presentation/signin/data/repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../firebase_service.dart';
import '../../../../utils/di.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

final userRepo = sl.get<UserRepo>();
var loginResponseModel = sl.get<LoginResponseModel>();

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  static SignInBloc get(BuildContext context) => BlocProvider.of(context);

  SignInBloc() : super(SignInInitial()) {
    on<CheckSignedIn>(checkSignInMethod);
    on<SignInET>(signInMethod);
  }

  FutureOr<void> signInMethod(SignInET event, Emitter<SignInState> emit) async {
    var deviceName = '';

    emit(const LoadingST(isLoading: true));

    await FirebaseService.ensureFCMToken();

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      print('Running on ${androidInfo.model}');
      print('Running on id ${androidInfo.id}');
      print('Running on brand ${androidInfo.brand}');
      print('Running on device ${androidInfo.device}');

      // Use a more unique device identifier
      deviceName =
          '${androidInfo.brand}_${androidInfo.device}_${androidInfo.id}';
    }

    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      print('Running on ${iosInfo.utsname.machine}');
      print('Running on name ${iosInfo.name}');
      print('Running on model ${iosInfo.model}');

      // Use a more unique device identifier for iOS
      deviceName =
          '${iosInfo.name}_${iosInfo.model}_${iosInfo.utsname.machine}';
    }
    // event.deviceId;

    try {
      Response response =
          await userRepo.loginApiCall(event.email, event.password, deviceName);
      if (response.statusCode == 200) {
        var n = jsonEncode(response.data);
        loginResponseModel = loginResponseModelFromJson(n);

        await userRepo.setDeviceInfo(deviceName);

        log('loginResponseModel ${response.data}');

        if (loginResponseModel.result!.success == true) {
          emit(InitialSignedInST(loginResponse: loginResponseModel));
          emit(const LoadingST(isLoading: false));
          await userRepo.setLoginResponse(loginResponseModel);
          await userRepo.setISLoggedIn(true);
        } else {
          emit(ErrMsg(
              msg: (loginResponseModel.result?.message ??
                  'something'
                      ' went wrong')));
          emit(const LoadingST(isLoading: false));
        }
      }
    } catch (e) {
      log('signInMethod $e');
      emit(const ErrMsg(msg: 'something went wrong'));
      emit(const LoadingST(isLoading: false));
    }
  }

  FutureOr<void> checkSignInMethod(
      CheckSignedIn event, Emitter<SignInState> emit) async {
    final isSignedIn = await userRepo.getIsLoggedIn();

    log('isSignedIn $isSignedIn');
    // if (isSignedIn!) {
    final loginResponse = await userRepo.getLoginResponse();
    emit(InitialSignedInST(loginResponse: loginResponse!));
    // } else {
    //   emit(NotSignedInST());
    // }
    try {} catch (e) {
      log('checkSignInMethod $e');
    }
  }
}
