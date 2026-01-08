# Main Home Banner Implementation Guide

## Overview

This document describes the implementation of the Main Home Banner feature that consumes the Announcement Details API and displays dynamic banner content on the home screen.

## Implementation Summary

### 1. Model Layer

**File:** `lib/data/models/announcement_details_model.dart`

Created `AnnouncementDetailsModel` with the following fields:

- `id` (int): Announcement identifier
- `title` (String): Banner title
- `announcementText` (String): Main announcement text
- `hasAttachment` (bool): Flag indicating if banner has an image
- `attachmentUrl` (String?): URL to the banner image

Features:

- JSON serialization/deserialization
- Copy-with pattern for immutability
- Proper equality operators and hashCode

### 2. API Service Layer

**File:** `lib/data/services/announcements_api_service.dart`

Extended `AnnouncementsApiService` with new method:

```dart
Future<AnnouncementDetailsModel> fetchAnnouncementDetails({
  required int announcementId,
})
```

**API Details:**

- Endpoint: `POST /api/announcement_details`
- Authorization: Bearer Token
- Request Body (JSON-RPC):
  ```json
  {
    "jsonrpc": "2.0",
    "params": {
      "announcement_id": <ID>
    }
  }
  ```

Features:

- Full error handling with DioExceptions
- Timeout handling (15 seconds)
- Network error detection
- JSON-RPC error parsing

### 3. Provider Layer

**File:** `lib/providers/announcement_banner_provider.dart`

Created `AnnouncementBannerProvider` for state management:

- State management with `BannerState` enum (idle, loading, loaded, empty, error)
- `fetchBannerData()` method to load announcement details
- `refresh()` method for pull-to-refresh
- Proper disposal handling

**File:** `lib/ui/presentation/home_screen/provider/slider_provider.dart`

Enhanced `SliderProvider` to fetch announcements:

- Fetches announcements from API (category = announcements)
- Falls back to static data if API fails
- Manages carousel state and pagination
- Provides images and titles for the banner carousel

### 4. UI Components

#### Banner Widget

**File:** `lib/ui/presentation/home_screen/widgets/announcement_banner.dart`

Created reusable `AnnouncementBanner` widget with:

- Network image loading with `cached_network_image`
- Fallback to gradient background when no image
- Gradient overlay for text readability
- Title and announcement text with proper styling
- Tap gesture support for navigation
- Responsive design with ScreenUtil

#### Home Screen Integration

**File:** `lib/ui/presentation/home_screen/screens/main_home_content_widget.dart`

Updated main home content to:

- Fetch announcements on init
- Display loading state while fetching
- Show carousel with API-driven banners
- Support both network images and local assets
- Implement pull-to-refresh
- Display pagination indicators

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (MainHomeContentWidget, Providers)     │
├─────────────────────────────────────────┤
│         Domain/Service Layer            │
│     (AnnouncementsApiService)           │
├─────────────────────────────────────────┤
│           Data Layer                    │
│  (AnnouncementDetailsModel,             │
│   AnnouncementModel)                    │
└─────────────────────────────────────────┘
```

### State Flow

```
1. User opens home screen
   ↓
2. SliderProvider.fetchAnnouncementsForBanner()
   ↓
3. AnnouncementsApiService.fetchAnnouncements()
   ↓
4. API returns list of announcements
   ↓
5. Provider updates state and notifies listeners
   ↓
6. UI rebuilds with banner carousel
```

## UI Behavior

### Banner Display

- **With Attachment:** Uses `attachment_url` as background image
- **Without Attachment:** Shows gradient background with fallback image
- **Text Overlay:** Title (bold, uppercase) + announcement text
- **Gradient Overlay:** Black gradient from transparent to 60% opacity for text readability

### Loading States

- **Loading:** Shows gray container with centered spinner
- **Loaded:** Displays banner carousel with API data
- **Error:** Falls back to static banner data
- **Empty:** Falls back to static banner data

### User Interactions

- **Tap on Banner:** Navigates to News Screen
- **Pull-to-Refresh:** Refreshes both home data and banner data
- **Pagination:** Dots indicator shows current banner position

## API Response Mapping

### Announcements List API

```json
{
  "result": {
    "data": [
      {
        "id": 1,
        "name": "Announcement Title",
        "description": "Announcement text...",
        "has_attachment": true,
        "attachment_url": "https://..."
      }
    ]
  }
}
```

### Announcement Details API

```json
{
  "result": {
    "data": {
      "id": 1,
      "title": "Banner Title",
      "announcement_text": "Detailed announcement text...",
      "has_attachment": true,
      "attachment_url": "https://..."
    }
  }
}
```

## Error Handling

### Network Errors

- Connection timeout (15s)
- Network unavailable
- Server errors (4xx, 5xx)

### Fallback Strategy

1. Try to load from API
2. On error, log and use static fallback data
3. Show error message if needed
4. Never crash the UI

### User Feedback

- Loading spinner during fetch
- Error messages are logged (not shown to user to avoid disruption)
- Static banners shown as graceful degradation

## Performance Considerations

### Image Caching

- Uses `cached_network_image` for efficient image loading
- Placeholder spinner while loading
- Error widget with fallback image

### API Efficiency

- Single API call on screen init
- Data cached in provider until refresh
- Pull-to-refresh for manual updates

### Memory Management

- Proper disposal of providers
- Lazy loading of images
- Reusable carousel items

## Testing Recommendations

### Manual Testing

1. **Banner with Image:**

   - Verify image loads from API
   - Check text overlay is readable
   - Test tap navigation

2. **Banner without Image:**

   - Verify fallback gradient shows
   - Check text is still readable

3. **Loading State:**

   - Verify spinner shows on initial load
   - Check smooth transition to content

4. **Error Handling:**

   - Disconnect network and verify fallback
   - Check no crashes occur

5. **Pull-to-Refresh:**

   - Verify data refreshes
   - Check loading indicator appears

6. **Pagination:**
   - Verify carousel auto-plays
   - Check dots indicator updates
   - Test manual swipe

### API Testing

```bash
# Test announcement list
curl -X POST https://erp.elrace.com/api/announcements \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","params":{"announcement_category_id":2}}'

# Test announcement details
curl -X POST https://erp.elrace.com/api/announcement_details \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","params":{"announcement_id":1}}'
```

## Files Created/Modified

### New Files

1. `/lib/data/models/announcement_details_model.dart`
2. `/lib/providers/announcement_banner_provider.dart`
3. `/lib/ui/presentation/home_screen/widgets/announcement_banner.dart`
4. `BANNER_IMPLEMENTATION.md` (this file)

### Modified Files

1. `/lib/data/services/announcements_api_service.dart`

   - Added `fetchAnnouncementDetails()` method
   - Added `_parseDetailsResponse()` helper

2. `/lib/ui/presentation/home_screen/provider/slider_provider.dart`

   - Converted to API-driven banner provider
   - Added fallback static data
   - Added `fetchAnnouncementsForBanner()` method

3. `/lib/ui/presentation/home_screen/screens/main_home_content_widget.dart`
   - Converted to StatefulWidget
   - Added init fetch of banner data
   - Added loading state UI
   - Implemented network image loading
   - Added refresh handler

## Future Enhancements

### Possible Improvements

1. **Analytics:** Track banner tap events
2. **Deep Linking:** Navigate to specific announcement details
3. **Caching:** Implement offline-first strategy
4. **Animations:** Add fade transitions between banners
5. **A/B Testing:** Support multiple banner variants
6. **Video Support:** Allow video attachments in banners
7. **Priority Sorting:** Sort banners by priority/date

### API Enhancements

1. Add pagination support for large datasets
2. Include expiry dates for banners
3. Support multiple image sizes for optimization
4. Add banner click tracking endpoint

## Dependencies

### Required Packages (Already in pubspec.yaml)

- `dio`: ^5.4.0 - HTTP client
- `provider`: ^6.1.1 - State management
- `cached_network_image`: ^3.3.1 - Image caching
- `carousel_slider`: ^4.2.1 - Carousel widget
- `flutter_screenutil`: ^5.9.0 - Responsive UI

## Support

For issues or questions:

- Check error logs in console
- Verify API token is valid
- Ensure network connectivity
- Review API response format

---

**Implementation Date:** January 8, 2026
**Version:** 1.0.0
**Status:** ✅ Complete and Ready for Testing
