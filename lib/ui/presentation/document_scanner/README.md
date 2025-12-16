# Document Scanner Module

A comprehensive document scanning feature for Flutter, similar to CamScanner.

## Architecture

This module follows **Clean Architecture** with feature-based folder structure:

```
document_scanner/
├── domain/                    # Business Logic Layer
│   ├── entities/             # Business entities
│   ├── repositories/         # Repository interfaces
│   └── usecases/             # Use cases
├── data/                      # Data Layer
│   ├── repositories/         # Repository implementations
│   └── services/             # Services (image processing, export)
├── presentation/              # UI Layer
│   ├── bloc/                 # State management
│   ├── screens/              # UI screens
│   └── widgets/              # Reusable widgets
└── README.md
```

## Features

- ✅ Open device camera directly
- ✅ Real-time document edge detection
- ✅ Manual corner adjustment after capture
- ✅ Image enhancement filters (Original, Grayscale, B&W)
- ✅ Crop and perspective correction
- ✅ Single and multiple page scans
- ✅ Export as PNG/JPEG or multi-page PDF

## Key Components

### Domain Layer
- `ScannedDocument`: Entity representing a scanned document
- `DocumentPage`: Entity for individual pages
- `IDocumentScannerRepository`: Repository interface
- `ScanDocumentUseCase`: Orchestrates the scanning flow

### Data Layer
- `DocumentScannerRepository`: Implements repository interface
- `ImageProcessingService`: Handles image manipulation
- `EdgeDetectionService`: Detects document edges
- `DocumentExportService`: Exports to PDF/images

### Presentation Layer
- `DocumentScannerBloc`: Manages scanning state
- `ScannerCameraScreen`: Camera preview with edge detection
- `CropAdjustmentScreen`: Manual corner adjustment
- `FilterScreen`: Apply image filters
- `DocumentPreviewScreen`: Preview and export

## Performance Optimizations

1. **Memory Management**
   - Images are processed in isolates to avoid blocking UI
   - Large bitmaps are disposed immediately after use
   - Thumbnail generation for preview

2. **Edge Detection**
   - Uses efficient contour detection algorithm
   - Debounced detection to avoid excessive processing
   - Runs in separate isolate

3. **Camera Performance**
   - Uses optimal resolution preset for device
   - Frame rate optimization for smooth preview
   - Auto-exposure and focus handling

## Usage

```dart
import 'package:el_race/ui/presentation/document_scanner/document_scanner.dart';

// Navigate to scanner
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DocumentScannerScreen(),
  ),
);

// Or use the launcher widget
DocumentScannerLauncher(
  onDocumentScanned: (document) {
    // Handle scanned document
    print('Scanned ${document.pages.length} pages');
  },
  onExported: (filePath, type) {
    // Handle exported file
    print('Exported to: $filePath');
  },
);
```

## Dependencies

- `camera`: Camera access and preview
- `image`: Image manipulation
- `pdf`: PDF generation
- `path_provider`: File system access
- `permission_handler`: Camera permissions

## Platform Notes

### iOS
- Requires `NSCameraUsageDescription` in Info.plist
- Uses native feel with iOS-style controls

### Android
- Requires camera permission in AndroidManifest.xml
- Follows Material Design guidelines
