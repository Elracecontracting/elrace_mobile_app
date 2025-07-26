import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../../../../../../utils/di.dart';
import '../../../../utils/api_query.dart';
import '../../../../utils/urll_utils.dart';
import '../../signin/data/repository.dart';

final userRepo = sl.get<UserRepo>();

class ContactRepo {
  ApiQuery apiQuery = ApiQuery();

  Future<http.Response> getEmployeeList() async {
    var url = Uri.parse(UrlUtil.baseUrl + UrlUtil.contactApi);

    final loginResponse = await userRepo.getLoginResponse();

    var token = loginResponse!.result!.token!;

    Map<String, String> header = {
      "Content-Type": "application/json",
      'Accept': 'application/json',
      "Authorization": "Bearer $token"
    };
    // Map<String, dynamic> body = {"jsonrpc": "2.0", "params": {}};

    log(header.toString());

    // var response = await http.get(url, headers: headers);

    final request = http.Request('GET', url)
      ..headers.addAll(header)
      ..body = jsonEncode({});

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    /*var response = await http.get(
      url,
      headers: header,
      body:
    );*/

    /*Response? response = await apiQuery.getQuery(
        UrlUtil.contactApi, header, {}, 'contact', true, true, false);*/

    return response;
  }
}
