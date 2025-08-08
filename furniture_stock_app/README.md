# Furniture Stock Management App

A comprehensive Flutter application for managing furniture inventory from factory to showroom, built with Supabase backend.

## Features

- **User Authentication**: Secure sign-up/sign-in with role-based access
- **Product Management**: Add, edit, and track furniture products
- **Stock Tracking**: Monitor inventory levels in factory and showroom
- **Inventory Movement**: Transfer stock between locations
- **Reports**: Generate daily, weekly, and monthly reports
- **Notifications**: Low stock alerts and system notifications
- **Blue Theme**: Professional blue color scheme throughout

## User Roles

- **Packaging Expert**: Full access to all features
- **Owner**: Full access to all features  
- **Stock Mover**: Full access to all features

## Tech Stack

- **Frontend**: Flutter 3.32.8+ with Dart 3.8.1+
- **Backend**: Supabase (PostgreSQL database)
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI**: Material Design 3 with custom blue theme

## Getting Started

1. Follow the setup instructions in `flutter_setup_guide.md`
2. Configure Supabase using `supabase_setup_guide.md`
3. Update Supabase credentials in `lib/config/supabase_config.dart`
4. Run `flutter pub get`
5. Run `flutter run -d windows` (or your preferred platform)

## Project Structure

```
lib/
├── config/          # Configuration files
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── utils/           # Utilities and themes
└── main.dart        # App entry point
```

## Database Schema

The app uses a comprehensive database schema with:
- User profiles and authentication
- Product catalog with images
- Stock levels by location
- Movement tracking and history
- Production batch tracking
- Notification system

## Development Status

- ✅ Authentication system
- ✅ Blue theme implementation
- ✅ Navigation structure
- ✅ Dashboard with user info
- ✅ Database schema design
- 🚧 Product management (ready for implementation)
- 🚧 Stock tracking (ready for implementation)
- 🚧 Reports and analytics (ready for implementation)

## License

This project is created for furniture shop stock management purposes.

