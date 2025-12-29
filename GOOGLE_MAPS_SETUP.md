# Google Maps Integration - Setup Guide

## ✅ Completed

1. **Added Google Maps Dependencies**
   - Added `google_maps_flutter: ^2.10.1` to `pubspec.yaml`
   - Removed flutter_map and latlong2 dependencies
   - Successfully installed dependencies

2. **Created Crime Location Model**
   - Created `lib/models/crime_location.dart`
   - Includes `CrimeLocation` data model
   - Includes `CrimeTypeVisuals` with color and icon mappings for different crime types
   - Support for crime types: theft, robbery, assault, vandalism, fraud, domestic_violence, drug_related, corruption

3. **Updated App Constants**
   - Added `googleMapsApiKey` getter in `lib/constants/app_constants.dart`
   - Configured to load from environment variable `GOOGLE_MAPS_API_KEY`

4. **Dashboard Updates**
   - Updated imports to use `google_maps_flutter` instead of `flutter_map`
   - Added crime markers set and loading function
   - Created sample crime locations for testing

## ⚠️ In Progress

The dashboard screen still needs to be fully updated to replace the FlutterMap widget with GoogleMap. The current state has:
- Updated state variables for Google Map Controller
- Added crime marker loading functionality
- Updated recenter button to use Google Maps API

## 📝 To Complete

### 1. Replace FlutterMap Widget with GoogleMap

In `lib/screens/dashboard_screen.dart`, replace the FlutterMap widget (around line 264) with:

```dart
// Google Maps with crime markers
GoogleMap(
  onMapCreated: (GoogleMapController controller) {
    _mapController = controller;
  },
  initialCameraPosition: CameraPosition(
    target: mapCenter,
    zoom: 14.0,
  ),
  markers: {
    // User location marker
    Marker(
      markerId: const MarkerId('user_location'),
      position: mapCenter,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(
        title: 'Your Location',
        snippet: 'Current position',
      ),
    ),
    // Add crime markers from admin
    ..._crimeMarkers,
  },
  mapType: MapType.normal,
  myLocationEnabled: true,
  myLocationButtonEnabled: false,
  zoomControlsEnabled: false,
  scrollGesturesEnabled: true,
  zoomGesturesEnabled: true,
  tiltGesturesEnabled: true,
  rotateGesturesEnabled: true,
),
```

### 2. Add Google Maps API Key

To make Google Maps work, you need to:

**For Web (Chrome):**
1. Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the following APIs:
   - Maps JavaScript API
   - Maps SDK for Flutter (for mobile later)
3. Add the API key to your environment or directly in `lib/constants/app_constants.dart`:

```dart
static String get googleMapsApiKey {
  return 'YOUR_API_KEY_HERE';
}
```

**For Web, add to `web/index.html`:**
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY"></script>
```

### 3. Database Integration

Currently using sample crime data. To integrate with Supabase:

1. Create a `crime_locations` table in Supabase:
```sql
CREATE TABLE crime_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  latitude DECIMAL(10,8) NOT NULL,
  longitude DECIMAL(11,8) NOT NULL,
  crime_type VARCHAR(50) NOT NULL,
  title VARCHAR(255),
  description TEXT,
  reported_at TIMESTAMP WITH TIME ZONE NOT NULL,
  severity VARCHAR(20) NOT NULL,
  is_verified BOOLEAN DEFAULT false,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

2. Update `_loadCrimeMarkers()` in dashboard to fetch from Supabase.

## 🎨 Crime Marker Features

The current implementation includes:
- **Color-coded markers** based on crime type
- **Info windows** showing crime details when tapped
- **Custom icons** (to be added in assets folder)
- **Severity-based styling**

## 📍 Current Crime Types

- Theft (Red)
- Robbery (Dark Red)
- Assault (Pink)
- Vandalism (Orange)
- Fraud (Purple)
- Domestic Violence (Deep Purple)
- Drug Related (Green)
- Corruption (Blue Grey)
- Other (Grey)

## 🚀 Testing

To test the implementation:
1. Add Google Maps API key
2. Run: `flutter run -d chrome`
3. Navigate to dashboard
4. See crime markers on the map
5. Tap markers to see info windows

## 📝 Notes

- The app currently shows 3 sample crime markers around Windhoek
- Markers are loaded in `_loadCrimeMarkers()` method
- The user's location is marked with a blue (azure) marker
- All markers are interactive and show info windows


