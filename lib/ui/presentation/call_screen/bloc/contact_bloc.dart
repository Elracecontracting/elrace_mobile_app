import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../../../../../utils/di.dart';
import '../data/model.dart';
import '../data/repository.dart';

part 'contact_event.dart';
part 'contact_state.dart';

final _contactRepo = sl.get<ContactRepo>();

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  ContactBloc() : super(ContactInitial()) {
    on<GetEmployeeLisET>(getEmpMethod);
    on<SearchContactsEvent>(searchContactsMethod);
  }

  List<Employee> empList = [];
  List<Employee> filteredEmpList = [];
  FutureOr<void> getEmpMethod(
      GetEmployeeLisET event, Emitter<ContactState> emit) async {
    if (empList.isNotEmpty) return;
    emit(const ContactLoadingState(isLoading: true));

    log('empModel.result!.employees! 1');

    http.Response? response = await _contactRepo.getEmployeeList();
    log('empModel.result!.employees! 2');

    if (response.statusCode == 200) {
      final empModel = employeeModelFromJson(response.body);

      // Guard against error payloads and nulls
      final employees = empModel.result?.employees ?? [];
      emit(const ContactLoadingState(isLoading: false));
      if (employees.isNotEmpty) {
        empList = employees;
        filteredEmpList = employees;
        emit(EmployeeListLoaded(List<Employee>.from(filteredEmpList)));
      }
      return;
    }

    log(response.body);
    try {} catch (e) {
      log('getEmpMethod $e');
    }
  }

  FutureOr<void> searchContactsMethod(
      SearchContactsEvent event, Emitter<ContactState> emit) async {
    final keyword = event.keyword.toLowerCase();

    if (keyword.isEmpty) {
      filteredEmpList = empList;
    } else {
      filteredEmpList = empList
          .where((employee) =>
              employee.name?.toLowerCase().contains(keyword) == true ||
              employee.mobilePhone
                      ?.toString()
                      .toLowerCase()
                      .contains(keyword) ==
                  true ||
              employee.jobId?.toString().toLowerCase().contains(keyword) ==
                  true)
          .toList();
    }

    emit(EmployeeListLoaded(List<Employee>.from(filteredEmpList)));
  }
}
