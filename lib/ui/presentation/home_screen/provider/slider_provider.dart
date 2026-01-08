import 'package:el_race/data/models/announcement_model.dart';
import 'package:el_race/data/models/announcement_details_model.dart';
import 'package:el_race/data/services/announcements_api_service.dart';
import 'package:flutter/material.dart';

class SliderProvider extends ChangeNotifier {
  final AnnouncementsApiService _apiService;

  SliderProvider({AnnouncementsApiService? apiService})
      : _apiService = apiService ?? AnnouncementsApiService();

  // Fallback static data
  final List<String> _fallbackImages = [
    'assets/jpeg/slide_1_c.jpg',
    'assets/jpeg/slide_2_c.jpg',
    'assets/jpeg/slide_3_c.jpg',
    'assets/jpeg/slide_4_c.jpg',
  ];

  final List<String> _fallbackTitles = [
    "The much-anticipated project has officially reached completion...",
    "Successfully delivered on schedule, the project highlights...",
    "Stakeholders have praised the project for its efficiency and...",
    "A closing ceremony was held to commemorate the achievement...",
  ];

  // API-driven data
  List<AnnouncementModel> _announcements = [];
  List<AnnouncementDetailsModel> _bannerDetails = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get hasApiData => _bannerDetails.isNotEmpty;

  // Getters for images and titles (with fallback)
  List<String> get sliderImages {
    if (_bannerDetails.isEmpty) {
      return _fallbackImages;
    }
    return _bannerDetails
        .map((detail) => detail.attachmentUrl ?? _fallbackImages[0])
        .toList();
  }

  List<String> get titles {
    if (_bannerDetails.isEmpty) {
      print('📋 Using fallback titles');
      return _fallbackTitles.map((text) {
        return text.length > 30 ? '${text.substring(0, 30)}...' : text;
      }).toList();
    }

    final result = _bannerDetails.map((detail) {
      String text = detail.announcementText.isNotEmpty
          ? detail.announcementText.trim() // Clean whitespace
          : detail.title.isNotEmpty
              ? detail.title.trim() // Clean whitespace
              : "Announcement";
      print('📝 Banner text (cleaned): "$text"');
      // Limit to 30 characters
      final displayText =
          text.length > 30 ? '${text.substring(0, 30)}...' : text;
      print('📝 Display text: "$displayText"');
      return displayText;
    }).toList();

    print('📋 Total titles: ${result.length}');
    return result;
  }

  List<AnnouncementModel> get announcements => _announcements;
  List<AnnouncementDetailsModel> get bannerDetails => _bannerDetails;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// First fetches the list from /api/announcements, then fetches details for each
  Future<void> fetchAnnouncementsForBanner() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      print('========== FETCHING BANNER ANNOUNCEMENTS ==========');
      // Step 1: Fetch announcements list to get IDs (category 2 = Announcements for banner)
      final results = await _apiService.fetchAnnouncements(
        category: AnnouncementCategory.announcements,
      );

      print(
          '✅ Fetched ${results.length} announcements from /api/announcements');

      // If no announcements in category 2, try News (category 1)
      if (results.isEmpty) {
        print(
            '⚠️ No announcements found in category 2, trying News (category 1)...');
        final newsResults = await _apiService.fetchAnnouncements(
          category: AnnouncementCategory.news,
        );
        print('✅ Fetched ${newsResults.length} news items');
        _announcements = newsResults;
      } else {
        _announcements = results;
      }

      // Step 2: Fetch details for each announcement ID (limit to first 5 for performance)
      final List<AnnouncementDetailsModel> details = [];
      final announcementsToFetch = _announcements.take(5).toList();

      print(
          '📡 Fetching details for ${announcementsToFetch.length} announcements...');

      for (final announcement in announcementsToFetch) {
        try {
          print('  → Fetching details for ID: ${announcement.id}');
          final detail = await _apiService.fetchAnnouncementDetails(
            announcementId: announcement.id,
          );
          details.add(detail);
          final textPreview = detail.announcementText.length > 50
              ? '${detail.announcementText.substring(0, 50)}...'
              : detail.announcementText;
          print(
              '  ✅ Got details: title="${detail.title}", text="$textPreview"');
        } catch (e) {
          print(
              '  ❌ Error fetching details for announcement ${announcement.id}: $e');
          // Continue with next announcement if one fails
        }
      }

      _bannerDetails = details;
      print('✅ Total banner details loaded: ${_bannerDetails.length}');

      if (_bannerDetails.isNotEmpty) {
        print('📸 Images URLs:');
        for (var detail in _bannerDetails) {
          print('  - ${detail.attachmentUrl ?? "NO IMAGE"}');
        }
      }

      _isLoading = false;
      _hasError = false;

      // Reset index if it's out of bounds
      if (_currentIndex >= _bannerDetails.length && _bannerDetails.isNotEmpty) {
        _currentIndex = 0;
      }

      print('========== BANNER FETCH COMPLETE ==========');
    } on AnnouncementApiException catch (e) {
      print('❌ API Error: ${e.message}');
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.message;
      _announcements = [];
      _bannerDetails = [];
      print('Error fetching banner announcements: ${e.message}');
    } catch (e) {
      print('❌ Unexpected Error: $e');
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Failed to load banner data';
      _announcements = [];
      _bannerDetails = [];
      print('Error fetching banner announcements: $e');
    }

    notifyListeners();
  }

  /// Refresh announcements
  Future<void> refresh() async {
    await fetchAnnouncementsForBanner();
  }
}
