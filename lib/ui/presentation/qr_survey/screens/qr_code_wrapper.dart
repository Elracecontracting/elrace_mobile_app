import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/qr_survey_data_provider.dart';
import 'list_questions_screen.dart';
import 'list_documents_screen.dart';
import 'list_media_screen.dart';

/// Central wrapper that displays content based on the type from provider
class QrCodeWrapper extends StatelessWidget {
  const QrCodeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<QrSurveyDataProvider>(
      builder: (context, provider, child) {
        if (!provider.hasContent) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Loading...'),
              backgroundColor: Colors.blue,
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Display the appropriate screen based on content type
        switch (provider.contentType) {
          case 'survey':
            return ListQuestionsScreen(
              questions: provider.data as List<dynamic>,
              surveyId: provider.surveyId!,
              title: provider.title ?? 'Survey',
            );
          case 'documents':
            return ListDocumentsScreen(
              documents: provider.data as List<dynamic>,
            );
          case 'media':
            return ListMediaScreen(
              mediaList: provider.data as List<dynamic>,
            );
          default:
            return Scaffold(
              appBar: AppBar(
                title: const Text('Unknown Content'),
              ),
              body: const Center(
                child: Text('Unknown content type'),
              ),
            );
        }
      },
    );
  }
}
