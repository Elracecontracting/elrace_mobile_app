import 'dart:convert';

import 'package:el_race/ui/presentation/my_projects/data/datasources/project_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ProjectRemoteDataSource.fetchUserProjects', () {
    test('returns parsed response on success', () async {
      final mockClient = MockClient((request) async {
        // Detailed logging for mock request
        print('=== MOCK REQUEST ===');
        print('URL: ${request.url}');
        print('Method: ${request.method}');
        print('Headers: ${request.headers}');
        print('Body: ${request.body}');
        print('Body Length: ${request.body.length}');
        print('====================');

        expect(
            request.url.toString(), 'https://erp.elrace.com/api/user/projects');
        expect(request.method, 'GET');

        final mockResponse = http.Response(
          jsonEncode({
            'result': {
              'success': true,
              'employee_id': 4255,
              'projects': [
                {
                  'project_id': 13171,
                  'project_name': 'Odoo Development',
                }
              ],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );

        print('=== MOCK RESPONSE ===');
        print('Status Code: 200');
        print('Body: ${mockResponse.body}');
        print('====================');

        return mockResponse;
      });

      final dataSource = ProjectRemoteDataSource(
        client: mockClient,
        getToken: () => 'mock_token',
      );

      final result = await dataSource.fetchUserProjects();

      expect(result.success, isTrue);
      expect(result.employeeId, 4255);
      expect(result.projects, hasLength(1));
      expect(result.projects.first.projectId, 13171);
      expect(result.projects.first.projectName, 'Odoo Development');
    });

    test('throws an exception on non-200 status', () async {
      final mockClient = MockClient((request) async {
        print('=== MOCK ERROR REQUEST ===');
        print('URL: ${request.url}');
        print('Method: ${request.method}');
        print('Headers: ${request.headers}');
        print('Body: ${request.body}');
        print('===========================');

        return http.Response('error', 500);
      });

      final dataSource = ProjectRemoteDataSource(
        client: mockClient,
        getToken: () => 'mock_token',
      );

      expect(() => dataSource.fetchUserProjects(), throwsA(isA<Exception>()));
    });
  });
}
