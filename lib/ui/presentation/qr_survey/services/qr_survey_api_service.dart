import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:http/http.dart' as http;
import '../models/qr_question_model.dart';
import '../models/qr_document_model.dart';
import '../models/qr_media_model.dart';

class QrSurveyApiService {
  static const String baseUrl = 'https://test.elrace.com/api';

  /// Get content after QR code is scanned
  /// Returns a Map with type and data
  /// type can be: 'survey', 'documents', 'media'
  Future<Map<String, dynamic>?> getContentAfterQrCodeScanned() async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('$baseUrl/survey/any_published');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] != null && data['result']['data'] != null) {
          final result = data['result']['data'];

          // Check what type of content is available
          if (result['survey'] != null) {
            return {
              'type': 'survey',
              'survey_id': result['survey']['id'],
              'title': result['survey']['title'],
              'data': (result['survey']['questions'] as List)
                  .map((q) => QrQuestionModel.fromJson(q))
                  .toList(),
            };
          } else if (result['documents'] != null) {
            return {
              'type': 'documents',
              'data': (result['documents'] as List)
                  .map((d) => QrDocumentModel.fromJson(d))
                  .toList(),
            };
          } else if (result['media'] != null) {
            return {
              'type': 'media',
              'data': (result['media'] as List)
                  .map((m) => QrMediaModel.fromJson(m))
                  .toList(),
            };
          }
        }
      }

      return null;
    } catch (e) {
      print('❌ Error fetching QR content: $e');
      return null;
    }
  }

  /// Submit survey answers
  Future<bool> submitSurveyAnswers({
    required int surveyId,
    required List<QrQuestionModel> questions,
    String? guestName,
    String? guestContact,
  }) async {
    try {
      final token = SharedPref.getLoginData().result?.token;
      final isGuest = token == null;

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Prepare answers
      final answers = questions.map((q) {
        Map<String, dynamic> answer = {
          'question_id': q.id,
        };

        switch (q.type) {
          case 'date':
            if (q.dateAnswer != null) {
              answer['answer'] = q.dateAnswer!.toIso8601String();
            }
            break;
          case 'simple_choice':
            if (q.selectedAnswer != null) {
              answer['answer'] = q.selectedAnswer;
            }
            break;
          case 'char_box':
            if (q.textAnswer != null) {
              answer['answer'] = q.textAnswer;
            }
            break;
        }

        return answer;
      }).toList();

      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {
          'survey_id': surveyId,
          'answers': answers,
          if (isGuest) ...{
            'guest_name': guestName,
            'guest_contact': guestContact,
          },
        },
      });

      final url = Uri.parse('$baseUrl/survey/submit/$surveyId');
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result']?['status'] == 'success';
      }

      return false;
    } catch (e) {
      print('❌ Error submitting survey: $e');
      return false;
    }
  }
}
