# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview

This is a Flutter multi-app project (3:11 Security) with 3 apps sharing a hosted Supabase backend:
- **User App** (`/workspace`) — citizen-facing emergency/crime reporting
- **Admin App** (`/workspace/security_311_admin`) — police/security admin dashboard
- **Super Admin App** (`/workspace/security_311_super_admin`) — system admin for user management

### Running the Apps

All apps target Flutter web for development in this environment. Use `flutter run -d web-server` for headless mode:

```bash
# User App (port 8080)
cd /workspace && flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0

# Admin App (port 8081)
cd /workspace/security_311_admin && flutter run -d web-server --web-port=8081 --web-hostname=0.0.0.0

# Super Admin App (port 8082)
cd /workspace/security_311_super_admin && flutter run -d web-server --web-port=8082 --web-hostname=0.0.0.0
```

### Lint & Test Commands

```bash
# Lint (all 3 apps)
flutter analyze                          # from each app root
# Tests (user app has the only passing test)
cd /workspace && flutter test
```

### Key Gotchas

- **Flutter PATH**: Flutter is installed at `/opt/flutter/bin`. Ensure `export PATH="/opt/flutter/bin:$PATH"` is in your shell (already in `~/.bashrc`).
- **`.env` files**: Each app needs a `.env` file in its root. The Supabase URL and anon key have hardcoded fallbacks in `app_constants.dart`, but `flutter_dotenv` will warn if `.env` is missing. Create them with the Supabase credentials from `docs/QUICK_START.md`.
- **Pre-existing lint errors**: The codebase has pre-existing analysis issues (deprecation warnings, missing `geolocator`/`permission_handler`/`geocoding` imports in super_admin's `location_service.dart`, and stale default widget tests in admin/super_admin). These are NOT regressions.
- **Admin/Super Admin widget tests fail**: The default `widget_test.dart` in both admin and super_admin apps references `MyApp` which doesn't exist in those projects. These tests have never passed.
- **Supabase backend is remote**: The backend at `https://aivxbtpeybyxaaokyxrh.supabase.co` is hosted externally. No local database setup needed, but network access to this URL is required for full app functionality.
- **Web build**: Use `flutter build web` for a production build. The `--release` flag works for all 3 apps.
- **No Docker, no Makefile, no setup scripts**: Dependencies are managed entirely via `flutter pub get`.
