# Google Maps API Setup Guide - 3:11 Security Apps

## ✅ Configuration Complete

The Google Maps API has been successfully configured for all three 3:11 Security Flutter applications:

- **Admin App** (`security_311_admin/`)
- **Super Admin App** (`security_311_super_admin/`)  
- **User App** (`user_input_files/security_311_user/`)

## API Key Information

**Google Maps API Key:** `AIzaSyCO0kKndUNlmQi3B5mxy4dblg_8WYcuKuk`

## What Was Configured

### 1. Dependencies ✅
All three apps already had the required dependency:
```yaml
dependencies:
  google_maps_flutter: ^2.10.1
```

### 2. Android Configuration ✅
Updated `android/app/src/main/AndroidManifest.xml` for all apps:
- Fixed app labels (Admin, Super Admin, User)
- Added Google Maps API key meta-data:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyCO0kKndUNlmQi3B5mxy4dblg_8WYcuKuk" />
```

### 3. iOS Configuration ✅
Updated `ios/Runner/AppDelegate.swift` for all apps:
- Added GoogleMaps import
- Added API key initialization:
```swift
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyCO0kKndUNlmQi3B5mxy4dblg_8WYcuKuk")
```

### 4. Environment Variables ✅
Created `.env` files for all apps with:
- Google Maps API key
- Supabase configuration
- App-specific names and versions

## Usage in Flutter Code

### Basic Google Map Widget
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-22.5609, 17.0658), // Windhoek, Namibia
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map')),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: _initialPosition,
        markers: {
          // Add markers here
        },
      ),
    );
  }
}
```

### Loading Environment Variables
Make sure to load the .env file in your main.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

### Accessing API Key in Code
```dart
String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
```

## Security Notes

1. **API Key Security**: The API key is stored in multiple locations for convenience, but consider using more secure methods for production
2. **Environment Files**: .env files are included in the project - ensure they're properly gitignored in production
3. **API Restrictions**: Configure API key restrictions in Google Cloud Console for production use

## Next Steps

1. **Test the Maps**: Run each app and verify Google Maps functionality
2. **Add Map Features**: Implement specific map features like:
   - Emergency incident markers
   - Real-time location tracking
   - Route planning for responders
   - Geofenced safe zones
3. **Configure API Restrictions**: Set up proper API key restrictions in Google Cloud Console
4. **Handle Permissions**: Ensure location permissions are properly requested

## Troubleshooting

### Common Issues:
1. **Map not loading**: Check API key is correct and has Maps SDK enabled
2. **iOS build errors**: Run `cd ios && pod install` to update iOS dependencies
3. **Permission denied**: Ensure location permissions are granted
4. **API quota exceeded**: Monitor usage in Google Cloud Console

### Required Google Cloud APIs:
- Maps SDK for Android
- Maps SDK for iOS
- Places API (if using places features)
- Geocoding API (if converting addresses to coordinates)

## File Locations

### Configuration Files:
- `security_311_admin/.env`
- `security_311_super_admin/.env`
- `user_input_files/security_311_user/.env`

### Android Manifests:
- `security_311_admin/android/app/src/main/AndroidManifest.xml`
- `security_311_super_admin/android/app/src/main/AndroidManifest.xml`
- `user_input_files/security_311_user/android/app/src/main/AndroidManifest.xml`

### iOS AppDelegates:
- `security_311_admin/ios/Runner/AppDelegate.swift`
- `security_311_super_admin/ios/Runner/AppDelegate.swift`
- `user_input_files/security_311_user/ios/Runner/AppDelegate.swift`

---

**Setup completed on:** November 4, 2025  
**MiniMax Agent** - Google Maps API Configuration