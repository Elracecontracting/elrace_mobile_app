import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../utils/di.dart';

import 'package:http/http.dart' as http;

import '../data/model.dart';
import '../data/repository.dart';

part 'contact_event.dart';
part 'contact_state.dart';

final _contactRepo = sl.get<ContactRepo>();

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  ContactBloc() : super(ContactInitial()) {
    on<GetEmployeeLisET>(getEmpMethod);
  }

  FutureOr<void> getEmpMethod(
      GetEmployeeLisET event, Emitter<ContactState> emit) async {
    emit(const ContactLoadingState(isLoading: true));

    log('empModel.result!.employees! 1');

    http.Response? response = await _contactRepo.getEmployeeList();
    log('empModel.result!.employees! 2');

    if (response.statusCode == 200) {
      var empModel = employeeModelFromJson(response.body);

      if (empModel.result!.employees!.isNotEmpty) {
        emit(const ContactLoadingState(isLoading: false));

        log('empModel.result!.employees! ${empModel.result!.employees!}');
        emit(EmployeeListLoaded(empList: empModel.result!.employees!));
      }
    }

    log(response.body);
    try {} catch (e) {
      log('getEmpMethod $e');
    }
  }
}
