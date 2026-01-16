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

  // Timestamp to force image cache refresh
  int _lastFetchTimestamp = DateTime.now().millisecondsSinceEpoch;
  int get lastFetchTimestamp => _lastFetchTimestamp;

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
      // Limit to 30 characters
      final displayText =
          text.length > 30 ? '${text.substring(0, 30)}...' : text;
      return displayText;
    }).toList();

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
      // Step 1: Fetch announcements list to get IDs (category 2 = Announcements for banner)
      final results = await _apiService.fetchAnnouncements(
        category: AnnouncementCategory.announcements,
      );

      // If no announcements in category 2, try News (category 1)
      if (results.isEmpty) {
        final newsResults = await _apiService.fetchAnnouncements(
          category: AnnouncementCategory.news,
        );
        _announcements = newsResults;
      } else {
        _announcements = results;
      }

      // Step 2: Fetch details for each announcement ID (limit to first 5 for performance)
      final List<AnnouncementDetailsModel> details = [];
      final announcementsToFetch = _announcements.take(5).toList();

      for (final announcement in announcementsToFetch) {
        try {
          final detail = await _apiService.fetchAnnouncementDetails(
            announcementId: announcement.id,
          );
          details.add(detail);
        } catch (e) {
          // Continue with next announcement if one fails
        }
      }

      _bannerDetails = details;

      // Update timestamp to force cache refresh
      _lastFetchTimestamp = DateTime.now().millisecondsSinceEpoch;

      _isLoading = false;
      _hasError = false;

      // Reset index if it's out of bounds
      if (_currentIndex >= _bannerDetails.length && _bannerDetails.isNotEmpty) {
        _currentIndex = 0;
      }
    } on AnnouncementApiException catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.message;
      _announcements = [];
      _bannerDetails = [];
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Failed to load banner data';
      _announcements = [];
      _bannerDetails = [];
    }

    notifyListeners();
  }

  /// Refresh announcements
  Future<void> refresh() async {
    await fetchAnnouncementsForBanner();
  }
}
