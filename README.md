# 311security - Crime Prevention App

## 🚨 Emergency Response & Crime Reporting for Citizens

The 311 Security platform is designed for emergency response and community safety in Namibia. This repository contains the complete multi-app system including User App, Admin App, and Super Admin App.

### 📱 Features

- **Emergency Reporting**: Quick SOS alerts with location tracking
- **Crime Reporting**: Submit crime reports with photo evidence
- **Safety Alerts**: Receive community safety notifications
- **Emergency Contacts**: Quick access to emergency services
- **Real-time Location**: GPS tracking for emergency response
- **Multi-language Support**: English and local languages
- **Admin Dashboard**: Comprehensive management interface for emergency alerts, danger zones, and user management

### 🛠️ Technical Stack

- **Framework**: Flutter 3.6.0+
- **Backend**: Supabase (Database, Auth, Storage, Edge Functions)
- **Maps**: Google Maps Flutter Plugin
- **State Management**: Provider
- **Local Storage**: Hive
- **Authentication**: Supabase Auth

### 📋 Prerequisites

Before running this app, ensure you have:

- Flutter SDK 3.6.0 or higher
- Android Studio / Xcode for mobile development
- Google Maps API key (already configured)
- Supabase account (credentials provided in .env)

### 🚀 Quick Start

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure environment:**
   - The `.env` file is already configured with API keys
   - Google Maps is already set up for Android and iOS

3. **Run the app:**
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run --device-id ios
   ```

### 🗺️ Google Maps Configuration

✅ **Already Configured**: Google Maps API key is set up for both platforms:

- **Android**: `android/app/src/main/AndroidManifest.xml`
- **iOS**: `ios/Runner/AppDelegate.swift`
- **Environment**: `.env` file with `GOOGLE_MAPS_API_KEY`

### 🔧 Environment Variables

The `.env` file contains:
```env
# Supabase Configuration
SUPABASE_URL=https://aivxbtpeybyxaaokyxrh.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...

# Google Maps API Key
GOOGLE_MAPS_API_KEY=AIzaSyCO...

# App Configuration
APP_NAME=3:11 Security User
APP_VERSION=1.0.0
```

### 🏗️ Backend Setup

The Supabase backend is included in the `supabase/` folder:

1. **Database Tables**: User profiles, crime reports, emergency alerts
2. **Edge Functions**: Real-time notifications, data processing
3. **Storage Buckets**: Profile images, crime evidence
4. **Authentication**: User registration and login

To deploy the backend:
```bash
cd supabase
supabase deploy
```

### 📁 Project Structure

```
311_security_user_app/
├── lib/                       # User App source code
├── security_311_admin/        # Admin App source code
├── security_311_super_admin/  # Super Admin App source code
├── android/                   # Android configuration
├── ios/                       # iOS configuration
├── supabase/                  # Backend configuration
├── docs/                      # Documentation
├── .env                       # Environment variables
└── pubspec.yaml              # Dependencies
```

### 🔐 Security Features

- **User Authentication**: Secure login/signup with Supabase Auth
- **Data Encryption**: All sensitive data is encrypted
- **Location Privacy**: Location data is only shared during emergencies
- **Secure Storage**: Local data stored using Hive encryption

### 📱 Key Screens

1. **Home Screen**: Quick access to emergency features
2. **Emergency Screen**: SOS button with location tracking
3. **Crime Reporting**: Form to report incidents with photo upload
4. **Safety Alerts**: Community notifications
5. **Profile**: User settings and emergency contacts
6. **Map View**: Real-time location and incident mapping
7. **Admin Dashboard**: Emergency alerts management with user details

### 🔧 Troubleshooting

**Common Issues:**

1. **Maps not loading**: Verify Google Maps API key in Google Cloud Console
2. **Location not working**: Check location permissions in device settings
3. **Build errors**: Run `flutter clean && flutter pub get`
4. **Supabase connection**: Verify environment variables in `.env`

### 📚 Documentation

- `docs/google_maps_setup_guide.md` - Google Maps configuration
- `docs/supabase_setup_complete.md` - Backend setup guide
- `docs/flutter_app_updates.md` - App development guide

### 🆘 Emergency Contacts

The app includes pre-configured emergency contacts for Namibia:
- Police: 10111
- Ambulance: 10177
- Fire Department: 10177
- Women & Child Protection: 1061

### 📄 License

This project is part of the 3:11 Security platform for community safety in Namibia.

---

**Built with ❤️ for community safety in Namibia**
