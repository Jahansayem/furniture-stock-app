#!/usr/bin/env dart

import 'dart:io';

/// Development script to setup or restore environment configuration
/// This script helps recover from AI coding sessions that may delete .env files
void main(List<String> args) async {
  print('🛠️  FurniTrack Environment Setup Script');
  print('=====================================');
  
  final envFile = File('.env');
  final envExampleFile = File('.env.example');
  
  if (args.contains('--check') || args.contains('-c')) {
    await checkEnvironment();
    return;
  }
  
  if (args.contains('--restore') || args.contains('-r')) {
    await restoreEnvironment();
    return;
  }
  
  if (args.contains('--help') || args.contains('-h')) {
    printHelp();
    return;
  }
  
  // Default: Setup environment
  await setupEnvironment();
}

Future<void> checkEnvironment() async {
  print('🔍 Checking environment configuration...\n');
  
  final envFile = File('.env');
  final envExampleFile = File('.env.example');
  
  // Check .env file
  if (envFile.existsSync()) {
    print('✅ .env file exists');
    final content = await envFile.readAsString();
    
    final hasSupabaseUrl = content.contains('SUPABASE_URL=https://');
    final hasSupabaseKey = content.contains('SUPABASE_ANON_KEY=eyJ');
    
    if (hasSupabaseUrl && hasSupabaseKey) {
      print('✅ Supabase credentials found in .env');
    } else {
      print('⚠️  .env file exists but missing credentials');
    }
  } else {
    print('❌ .env file missing');
  }
  
  // Check .env.example file
  if (envExampleFile.existsSync()) {
    print('✅ .env.example template exists');
  } else {
    print('❌ .env.example template missing');
  }
  
  // Check pubspec.yaml for flutter_dotenv
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final pubspecContent = await pubspecFile.readAsString();
    if (pubspecContent.contains('flutter_dotenv:')) {
      print('✅ flutter_dotenv dependency found');
    } else {
      print('❌ flutter_dotenv dependency missing');
    }
    
    if (pubspecContent.contains('- .env')) {
      print('✅ .env file configured in assets');
    } else {
      print('❌ .env file not configured in assets');
    }
  }
  
  print('\n📋 Configuration Summary:');
  print('- Run with --restore to restore missing files');
  print('- Run flutter pub get after any changes');
}

Future<void> restoreEnvironment() async {
  print('🔧 Restoring environment configuration...\n');
  
  final envFile = File('.env');
  final envExampleFile = File('.env.example');
  
  // Restore .env file with your specific credentials
  const envContent = '''SUPABASE_URL=https://rcfhwkiusmupbasprqjr.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjZmh3a2l1c211cGJhc3BycWpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTczMTgsImV4cCI6MjA2OTczMzMxOH0.QyBcrMvBvc5E9bkN-oyTT9Uh86zZ-cPKcaUmSg-D_ZU
ONESIGNAL_APP_ID=

# IMPORTANT: This file is auto-restored by the setup script
# AI-coding-resistant configuration - multiple fallback sources available
''';
  
  await envFile.writeAsString(envContent);
  print('✅ .env file restored with your Supabase credentials');
  
  // Restore .env.example if missing
  if (!envExampleFile.existsSync()) {
    const exampleContent = '''# Environment Variables Template
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
ONESIGNAL_APP_ID=your-onesignal-app-id

# This is a template file - copy to .env and fill with actual values
''';
    await envExampleFile.writeAsString(exampleContent);
    print('✅ .env.example template restored');
  }
  
  print('\n🎉 Environment restored successfully!');
  print('💡 You can now run: flutter run (no --dart-define flags needed)');
}

Future<void> setupEnvironment() async {
  print('🚀 Setting up environment for FurniTrack...\n');
  
  final envFile = File('.env');
  
  if (envFile.existsSync()) {
    print('✅ .env file already exists');
    
    stdout.write('Do you want to overwrite it? (y/N): ');
    final response = stdin.readLineSync()?.toLowerCase();
    
    if (response != 'y' && response != 'yes') {
      print('Setup cancelled');
      return;
    }
  }
  
  await restoreEnvironment();
}

void printHelp() {
  print('''
🛠️  FurniTrack Environment Setup Script
=====================================

Usage: dart scripts/setup_env.dart [options]

Options:
  --check, -c      Check current environment configuration
  --restore, -r    Restore .env file with your Supabase credentials
  --help, -h       Show this help message

Examples:
  dart scripts/setup_env.dart           # Setup environment (default)
  dart scripts/setup_env.dart --check   # Check configuration
  dart scripts/setup_env.dart --restore # Restore missing files

This script helps recover from AI coding sessions that may modify
or delete environment configuration files.
''');
}