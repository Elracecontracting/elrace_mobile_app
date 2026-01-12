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
    print('\n🟢 ========== FETCHING CONTACTS ==========');
    print('📊 Current empList size: ${empList.length}');

    if (empList.isNotEmpty) {
      print('✅ Using cached data');
      print('🟢 ========== END FETCHING CONTACTS ==========\n');
      return;
    }

    print('⏳ Loading contacts from API...');
    emit(const ContactLoadingState(isLoading: true));

    log('empModel.result!.employees! 1');

    http.Response? response = await _contactRepo.getEmployeeList();
    log('empModel.result!.employees! 2');

    if (response.statusCode == 200) {
      print('✅ API Response Success (200)');
      final empModel = employeeModelFromJson(response.body);

      // Guard against error payloads and nulls
      final employees = empModel.result?.employees ?? [];
      print('📊 Parsed ${employees.length} employees');

      emit(const ContactLoadingState(isLoading: false));
      if (employees.isNotEmpty) {
        empList = employees;
        filteredEmpList = employees;

        // Print first 3 employees for verification
        print('\n📋 First 3 Employees:');
        for (var i = 0;
            i < (employees.length > 3 ? 3 : employees.length);
            i++) {
          final emp = employees[i];
          print('  ${i + 1}. ${emp.name}');
          print('     - Database ID: ${emp.id}');
          print('     - Employee ID: ${emp.empId ?? "NULL"} ⚠️');
          print('     - Job ID: ${emp.jobId}');
          print('     - Mobile: ${emp.mobilePhone}');
        }

        emit(EmployeeListLoaded(List<Employee>.from(filteredEmpList)));
        print('✅ Emitted ${employees.length} employees to UI');
        print('🟢 ========== END FETCHING CONTACTS ==========\n');
      }
      return;
    } else {
      print('❌ API Response Failed: ${response.statusCode}');
      print('🟢 ========== END FETCHING CONTACTS ==========\n');
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
              employee.empId?.toString().toLowerCase().contains(keyword) ==
                  true ||
              employee.id?.toString().toLowerCase().contains(keyword) == true ||
              employee.department?.toString().toLowerCase().contains(keyword) ==
                  true ||
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
