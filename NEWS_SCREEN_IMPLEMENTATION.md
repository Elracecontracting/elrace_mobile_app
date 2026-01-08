# News Screen Implementation Guide

## Overview

This implementation provides a complete, production-ready News Screen that consumes the `/api/announcements` API following clean architecture principles.

## Architecture

### 1. **Model Layer** ([announcement_model.dart](lib/data/models/announcement_model.dart))

- `AnnouncementModel`: Strongly-typed model with the following fields:
  - `id` (int)
  - `name` (String) - Title
  - `description` (String) - Full description
  - `hasAttachment` (bool)
  - `attachmentUrl` (String?) - Optional URL
- Includes `fromJson`, `toJson`, `copyWith`, and proper equality operators

### 2. **API Service Layer** ([announcements_api_service.dart](lib/data/services/announcements_api_service.dart))

- `AnnouncementsApiService`: Handles API communication
  - Endpoint: `POST /api/announcements`
  - JSON-RPC 2.0 format with proper request body
  - Bearer token authentication
  - Comprehensive error handling
  - Timeout configuration (15 seconds)
- `AnnouncementCategory` enum:
  - `news` (1)
  - `announcements` (2)
  - `circulars` (3)

### 3. **State Management Layer** ([announcements_provider.dart](lib/providers/announcements_provider.dart))

- `AnnouncementsProvider`: ChangeNotifier-based provider
- States:
  - `idle` - Initial state
  - `loading` - Fetching data
  - `loaded` - Data successfully loaded
  - `empty` - No data available
  - `error` - API error occurred
- Features:
  - `fetchAnnouncements()` - Fetch by category
  - `refresh()` - Refresh current category
  - `clear()` - Reset state
  - Automatic disposal handling

### 4. **UI Layer**

#### Main Screen ([news_screen.dart](lib/ui/presentation/News Banner/news_screen.dart))

- `NewsScreen`: Main list view
- Features:
  - Pull-to-refresh
  - Loading state with spinner
  - Empty state with icon and message
  - Error state with retry button
  - News card list with:
    - Title
    - Description preview (150 chars)
    - Attachment indicator
    - "Read More" button
    - "Attachment" button (if available)
- Proper state handling using Consumer<AnnouncementsProvider>

#### Detail Screen ([news_detail_screen_api.dart](lib/ui/presentation/News Banner/news_detail_screen_api.dart))

- `NewsDetailScreenAPI`: Full news detail view
- Features:
  - Full description display
  - Attachment download/view button
  - Proper navigation with back button
  - URL launcher integration for attachments

## Usage

### 1. Navigation to News Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NewsScreen(),
  ),
);
```

### 2. Accessing Different Categories

```dart
// In your widget
context.read<AnnouncementsProvider>().fetchAnnouncements(
  category: AnnouncementCategory.news, // or .announcements, .circulars
);
```

### 3. Manual Refresh

```dart
await context.read<AnnouncementsProvider>().refresh();
```

## API Contract

### Request

```json
{
  "jsonrpc": "2.0",
  "params": {
    "announcement_category_id": 1
  }
}
```

### Expected Response

```json
{
  "jsonrpc": "2.0",
  "result": {
    "data": [
      {
        "id": 1,
        "name": "News Title",
        "description": "Full news description text",
        "has_attachment": true,
        "attachment_url": "https://example.com/file.pdf"
      }
    ]
  }
}
```

## State Handling

### Loading State

- Displays centered CircularProgressIndicator
- Shows "Loading news..." message

### Empty State

- Displays article icon
- Shows "No News Available" message
- Informative subtitle

### Error State

- Displays error icon
- Shows error message from API
- "Retry" button to refetch data

### Loaded State

- Displays scrollable list of news cards
- Each card shows:
  - Title
  - Description preview
  - Attachment indicator (if has_attachment)
  - Action buttons

## Error Handling

### Network Errors

- Connection timeout
- Network unavailable
- DNS resolution failures

### API Errors

- JSON-RPC error responses
- HTTP error codes
- Authentication failures

### User Feedback

- Error messages displayed in UI
- Snackbar notifications for attachment errors
- Retry functionality

## Dependencies Required

Ensure these are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  dio: ^5.0.0
  url_launcher: ^6.0.0
  flutter_screenutil: ^5.0.0
  google_fonts: ^6.0.0
  flutter_translate: ^4.0.0
```

## Provider Registration

The `AnnouncementsProvider` is already registered in [main.dart](lib/main.dart):

```dart
ChangeNotifierProvider(create: (_) => AnnouncementsProvider()),
```

## Testing Checklist

- [ ] News loads on screen open
- [ ] Pull-to-refresh works
- [ ] Loading state displays correctly
- [ ] Empty state displays when no data
- [ ] Error state displays on API failure
- [ ] Retry button refetches data
- [ ] News cards display properly
- [ ] Navigation to detail screen works
- [ ] Attachment button opens URL
- [ ] Attachment indicator shows when has_attachment is true
- [ ] Back navigation works correctly

## Future Enhancements

Potential improvements:

1. **Pagination**: Add load more functionality
2. **Search**: Filter news by keyword
3. **Favorites**: Save news items locally
4. **Sharing**: Share news via social media
5. **Image Support**: Display news thumbnail images
6. **Offline Mode**: Cache news for offline viewing
7. **Push Notifications**: Alert users of new news

## Troubleshooting

### News Not Loading

1. Check authentication token in SharedPref
2. Verify API endpoint URL is correct
3. Check network connectivity
4. Review API response format

### Attachments Not Opening

1. Verify `url_launcher` is configured for iOS/Android
2. Check attachment URL is valid
3. Ensure URL scheme is supported (http/https)

### Provider State Issues

1. Ensure provider is registered in main.dart
2. Check widget tree has access to provider
3. Verify proper use of Consumer or context.read/watch

## Code Quality

✅ **Clean Architecture**: Separated concerns (Model, Service, Provider, UI)  
✅ **Type Safety**: Strongly-typed models with null safety  
✅ **Error Handling**: Comprehensive error catching and user feedback  
✅ **State Management**: Proper state transitions and loading indicators  
✅ **Code Reusability**: Modular components and services  
✅ **Production Ready**: Includes loading, empty, and error states

---

**Implementation Date**: January 2026  
**Status**: ✅ Complete and Production-Ready
