import 'dart:convert';
import 'package:el_race/core/utils/shared_pref.dart';
import 'package:http/http.dart' as http;
import '../models/qr_question_model.dart';
import '../models/qr_document_model.dart';
import '../models/qr_media_model.dart';

class QrSurveyApiService {
  static const String baseUrl = 'https://erp.elrace.com/api';

  /// Get content after QR code is scanned
  /// Returns a Map with type and data
  /// type can be: 'survey', 'documents', 'media'
  Future<Map<String, dynamic>?> getContentAfterQrCodeScanned() async {
    try {
      final token = SharedPref.getLoginData().result?.token;

      // Backend expects JSON; use POST with minimal JSON body
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final url = Uri.parse('$baseUrl/survey/any_published');

      final body = jsonEncode({
        'jsonrpc': '2.0',
        'params': {},
      });

      final response = await http.post(url, headers: headers, body: body);

      print(
          '🌐 QR API call -> ${response.statusCode} ${response.reasonPhrase}');
      print('🌐 Headers sent: hasAuth=${token != null}');
      print('🌐 Request body: $body');

      if (response.statusCode == 200) {
        final bodyText = response.body;
        print('🌐 QR API body length: ${bodyText.length}');
        final data = jsonDecode(bodyText);

        if (data['result'] != null && data['result']['data'] != null) {
          final result = data['result']['data'];

          // Check what type of content is available
          if (result['survey'] != null) {
            print('🌐 QR API payload: survey found');
            return {
              'type': 'survey',
              'survey_id': result['survey']['id'],
              'title': result['survey']['title'],
              'data': (result['survey']['questions'] as List)
                  .map((q) => QrQuestionModel.fromJson(q))
                  .toList(),
            };
          } else if (result['documents'] != null) {
            print('🌐 QR API payload: documents found');
            return {
              'type': 'documents',
              'data': (result['documents'] as List)
                  .map((d) => QrDocumentModel.fromJson(d))
                  .toList(),
            };
          } else if (result['media'] != null) {
            print('🌐 QR API payload: media found');
            return {
              'type': 'media',
              'data': (result['media'] as List)
                  .map((m) => QrMediaModel.fromJson(m))
                  .toList(),
            };
          } else {
            print('⚠️ QR API payload: no survey/documents/media in result');
          }
        } else {
          print('⚠️ QR API payload: result.data missing');
        }
      } else {
        print('❌ QR API non-200: body=${response.body}');
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
