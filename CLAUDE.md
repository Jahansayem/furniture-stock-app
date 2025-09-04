# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FurniTrack** is a comprehensive Flutter application for furniture inventory management. It's a furniture stock management app that handles inventory tracking from factory to showroom, supporting both online and offline operations with real-time synchronization.

## Architecture & Key Components

### Core Stack
- **Frontend**: Flutter 3.32+ with Dart SDK 3.0+
- **Backend**: Supabase (PostgreSQL with real-time subscriptions)
- **State Management**: Provider pattern
- **Navigation**: GoRouter for declarative routing
- **Notifications**: OneSignal for push notifications
- **Storage**: Hive for offline data, Supabase Storage for files
- **Charts**: fl_chart for analytics and reports

### Application Structure
```
lib/
├── config/              # Configuration files (Supabase)
├── constants/           # App constants (OneSignal config)
├── models/             # Data models (Product, Stock, Sale, etc.)
├── providers/          # State management (Auth, Product, Stock, etc.)
├── screens/           # UI screens organized by feature
├── services/          # Core services (OneSignal, Sync, Connectivity)
└── utils/            # Utilities and theme
```

### Key Services
- **AuthProvider**: Handles authentication, user profiles, location-based check-in/out
- **SyncService**: Manages offline/online data synchronization
- **OneSignalService**: Push notifications with extensive retry logic
- **ConnectivityService**: Network state management for offline functionality
- **OfflineStorageService**: Hive-based local data storage

### Database Schema (Supabase)
Core tables: `user_profiles`, `products`, `stocks`, `stock_locations`, `stock_movements`, `sales`, `notifications`, `attendance_log`

## Development Commands

### Running the Application
```bash
# 🎉 NEW: Simple development run (AI-coding-resistant configuration)
flutter run

# The app now automatically loads from .env file - no more complex --dart-define flags!
# Your Supabase credentials are safely stored with multiple fallback sources

# Legacy method (still works as fallback):
flutter run \
  --dart-define SUPABASE_URL=$SUPABASE_URL \
  --dart-define SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define ONESIGNAL_APP_ID=$ONESIGNAL_APP_ID

# Build for release
flutter build apk --release
flutter build appbundle --release  # For Play Store
flutter build ios --release        # For iOS
```

### Code Quality & Testing
```bash
# CRITICAL: Always run analysis before commits - fixes theme errors and 258+ violations
flutter analyze

# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Generate coverage report
flutter test --coverage

# Generate Hive type adapters after model changes
flutter packages pub run build_runner build

# Fix common dependency issues
flutter clean && flutter pub get && flutter pub deps
```

### Dependencies Management
```bash
# Install dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Generate code (for Hive models)
flutter packages pub run build_runner build

# Clean and reset
flutter clean && flutter pub get
```

### Platform-Specific Builds
```bash
# Android
flutter build apk --split-per-abi
flutter build appbundle

# iOS
flutter build ios --release --no-codesign

# Desktop platforms
flutter build windows
flutter build linux
flutter build macos
```

## Environment Configuration

### 🛡️ AI-Coding-Resistant Configuration System
**Your Supabase credentials are now protected from AI coding sessions!**

The app uses a robust multi-source configuration system:
1. **`.env` file** (primary) - automatically loaded
2. **`--dart-define` flags** (secondary) - legacy fallback  
3. **Hardcoded fallbacks** (emergency) - your specific credentials

### Environment Variables
- `SUPABASE_URL`: https://rcfhwkiusmupbasprqjr.supabase.co
- `SUPABASE_ANON_KEY`: Your JWT token (already configured)
- `ONESIGNAL_APP_ID`: OneSignal application ID (optional)

### Quick Recovery Commands
```bash
# Check environment status
dart scripts/setup_env.dart --check

# Restore environment if deleted by AI coding
dart scripts/setup_env.dart --restore

# Get dependencies after restoration
flutter pub get
```

### Database Setup
1. Import `SUPABASE_SETUP.sql` into Supabase SQL Editor
2. Run `migrate_to_onesignal.sql` if migrating from Firebase
3. Configure Row Level Security (RLS) policies as defined in SQL files

## Critical Architecture Notes

### ⚠️ KNOWN ISSUES TO FIX FIRST
1. **Duplicate Structure**: Remove `furniture_stock_app/` subdirectory - entire codebase is duplicated
2. **Theme Errors**: Fix `lib/utils/app_theme.dart:38-40` - invalid BottomNavigationBarTheme constructor
3. **Incomplete Features**: Complete 10+ TODO implementations before adding new features
4. **Print Abuse**: Replace 137+ print() statements with proper logging (flutter_lints violations)

### Offline-First Architecture
- **Singleton Services**: ConnectivityService and SyncService use singleton pattern for state management
- **Pending Actions Queue**: `OfflineStorageService` stores operations for later sync when online
- **Three-Layer Sync**: Pending actions → Server download → Local upload pattern
- **Realtime Subscriptions**: Managed by EnhancedNotificationProvider, initialized post-authentication

### State Management Architecture
- **Provider Pattern**: All state managed through ChangeNotifier providers
- **Service Layer**: Separate singleton services (Sync, Connectivity, OneSignal) from UI providers
- **Error Propagation**: Consistent error handling pattern with `_setError()` across all providers
- **Loading States**: All async operations properly manage loading states for UI feedback

### Authentication Flow
- **Initialization**: AuthProvider loads current user on startup, handles profile creation
- **Location Integration**: Check-in/out operations capture GPS coordinates and reverse geocoding
- **Profile Management**: Automatic profile creation on first login with proper error recovery
- **Session Management**: Auth state changes trigger realtime subscription updates

### Navigation & Routing
- **Shell Layout**: MainLayout provides consistent bottom navigation across authenticated screens
- **Route Protection**: GoRouter redirect logic handles authentication state and loading states
- **Dynamic Navigation**: Bottom nav index syncs with current route via post-frame callbacks
- **Back Button**: Custom PopScope handling for proper app exit behavior

## 🤖 AI-Coding Protection Features

### How It Prevents Credential Loss
- **Multiple Fallback Sources**: If `.env` gets deleted, hardcoded fallbacks kick in
- **Protected File Markers**: `.gitignore` has clear warnings about protected files  
- **Auto-Recovery Scripts**: `scripts/setup_env.dart` can restore everything instantly
- **Clear Documentation**: This CLAUDE.md file explains the protection system
- **Startup Validation**: App checks credentials on startup and shows clear error messages

### If Credentials Get Deleted (Recovery Steps)
```bash
# Option 1: Quick restore (recommended)
dart scripts/setup_env.dart --restore
flutter pub get
flutter run

# Option 2: Manual restore
# Copy .env.example to .env and fill in your credentials
cp .env.example .env
# Edit .env with your actual values

# Option 3: Emergency mode
# The app has hardcoded fallbacks for your specific project
# It will still work even if .env is completely missing
```

### Files Protected from AI Coding
- `.env` - Your Supabase credentials  
- `CLAUDE.md` - This documentation file
- `lib/config/environment.dart` - The protection system itself
- `scripts/setup_env.dart` - Recovery script

## Development Guidelines

### Code Patterns
- **Provider Lifecycle**: Always implement `_setLoading()`, `_setError()`, `_clearError()` in new providers
- **Service Registration**: Register new services in `main.dart` MultiProvider and initialize in startup sequence
- **Error Recovery**: Use try-catch with fallback to offline storage in all providers
- **Async Patterns**: All database operations use async/await with proper error propagation

### Adding New Features
1. **Models First**: Create models in `lib/models/` with proper JSON serialization
2. **Provider Layer**: Add provider extending ChangeNotifier with loading/error states
3. **Screen Integration**: Place screens in feature-based subdirectories under `lib/screens/`
4. **Route Registration**: Add route to Shell or main routes in `main.dart:_createRouter()`
5. **Offline Support**: Implement pending actions via `SyncService.addPendingAction()`
6. **Navigation Update**: Add to bottom nav items in `main.dart:_navigationItems` if needed

### Critical Development Workflow
- **Before Coding**: Run `flutter analyze` to see current 258 issues
- **During Development**: Never use `print()` - use debugPrint() or proper logging
- **Database Operations**: Always handle both online/offline scenarios in providers
- **Testing**: Test offline/online transitions and sync behavior extensively

### Database & Sync Architecture
- **Dual Storage**: Every table operation updates both Supabase and Hive storage
- **Pending Actions**: Offline operations queue as actions with type/data structure
- **Sync Triggers**: Auto-sync on connectivity change, manual backup sync available
- **Error Recovery**: Failed sync operations are retried with exponential backoff

### Notification Integration
- **Background Init**: OneSignal initializes 500ms after app start to prevent blocking
- **Retry Logic**: Player ID retrieval has 5-attempt retry with 3-second delays
- **Dual Channels**: Foreground notifications via local notifications, background via OneSignal
- **Debug Screens**: Use `/debug/onesignal` and `/debug/onesignal-diagnostic` for testing

### Platform Considerations
- All platforms supported (Android, iOS, Web, Desktop)
- Location permissions handled per platform
- Platform-specific notification channels configured
- Storage paths configured for each target platform

## Common Issues & Solutions

### 🔴 Critical Build Issues
1. **Theme Constructor Errors**: `app_theme.dart:38` has invalid BottomNavigationBarTheme parameters - fix before any theme work
2. **Duplicate Codebase**: Two copies of entire codebase exist - consolidate to main `lib/` directory
3. **Missing TODO Implementations**: Image upload (`add_product_screen.dart:366`) and navigation actions are incomplete

### Supabase Connection Issues
- Verify environment variables are properly set
- Check network connectivity and Supabase project status  
- Review RLS policies if data access fails
- Profile creation may fail on first login - check `_createUserProfile()` error handling

### OneSignal Integration
- ONESIGNAL_APP_ID must be set via --dart-define (not .env file)
- Player ID retrieval uses 5-attempt retry with 3-second delays
- Background initialization has 500ms delay to prevent app startup blocking
- Debug screens: `/debug/onesignal` for testing, `/debug/onesignal-diagnostic` for troubleshooting

### Offline/Sync Issues
- **Connectivity Callbacks**: Services register callbacks with ConnectivityService for auto-sync
- **Pending Actions**: Use `SyncService.addPendingAction()` for offline operations
- **Dual Storage**: All providers must update both Supabase and OfflineStorageService
- **Sync Failure Recovery**: Check `SyncService.getSyncStats()` for pending actions and errors

### Performance Issues
- **Route Calculations**: MainLayout recalculates selected index every frame - optimize if performance problems
- **Future.delayed Overuse**: 10+ artificial delays in codebase - remove unnecessary ones
- **Memory Leaks**: Ensure proper disposal of realtime subscriptions in providers

## Testing Strategy

- Unit tests for core business logic in providers
- Widget tests for UI components
- Integration tests for complete workflows
- Manual testing on multiple platforms and network conditions

The application supports comprehensive furniture inventory management with robust offline capabilities, real-time synchronization, and professional notification systems suitable for production deployment.