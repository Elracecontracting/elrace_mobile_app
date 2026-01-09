import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:el_race/ui/widgets/header_widget.dart';
import 'package:el_race/utils/color_utils.dart';
import '../providers/qr_survey_data_provider.dart';
import 'list_documents_screen.dart';
import 'list_media_screen.dart';
import 'list_questions_screen.dart';

/// Wrapper widget that displays QR Survey content within HomeScreen structure
/// This widget is shown as part of the MainScreen bottom navigation
class QrSurveyContentWrapper extends StatelessWidget {
  const QrSurveyContentWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QrSurveyDataProvider>(
      builder: (context, provider, child) {
        // Get content from provider
        final contentType = provider.contentType;
        final dynamic data = provider.contentData;

        // Show QR Survey content based on type
        Widget qrSurveyContent;
        if (contentType == 'survey' && data is Map<String, dynamic>) {
          qrSurveyContent = ListQuestionsScreen(
            questions: data['questions'] ?? [],
            surveyId: data['id'] ?? 0,
            title: data['title'] ?? 'Survey',
          );
        } else if (contentType == 'documents') {
          // documents might be in data['documents'] if data is Map, or data itself if List
          List<dynamic> documents = [];
          if (data is List<dynamic>) {
            documents = data;
          } else if (data is Map<String, dynamic> &&
              data['documents'] is List) {
            documents = data['documents'] as List<dynamic>;
          }
          qrSurveyContent = ListDocumentsScreen(documents: documents);
        } else if (contentType == 'media') {
          // media might be in data['media'] if data is Map, or data itself if List
          List<dynamic> media = [];
          if (data is List<dynamic>) {
            media = data;
          } else if (data is Map<String, dynamic> && data['media'] is List) {
            media = data['media'] as List<dynamic>;
          }
          qrSurveyContent = ListMediaScreen(mediaList: media);
        } else {
          qrSurveyContent = const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Scan a QR code to view content',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: const HeaderWidget(),
          backgroundColor: lightGrey,
          body: qrSurveyContent,
        );
      },
    );
  }
}
