import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? _user;
  UserProfile? _userProfile;
  UserRole? _userRole;
  bool _isLoading = true; // Start with loading true
  String? _errorMessage;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  UserRole? get userRole => _userRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _user = _supabase.auth.currentUser;
      if (_user != null) {
        // Load user profile asynchronously but don't block
        _loadUserProfile().catchError((e) {
          AppLogger.error('Error loading user profile during init', error: e);
        });
      }

      // Listen to auth state changes
      _supabase.auth.onAuthStateChange.listen((data) {
        final newUser = data.session?.user;
        if (newUser?.id != _user?.id) {
          _user = newUser;
          if (_user != null) {
            _loadUserProfile().catchError((e) {
              AppLogger.error('Error loading user profile', error: e);
            });
          } else {
            _userProfile = null;
            _userRole = null;
          }
          notifyListeners();
        }
      });
    } catch (e) {
      AppLogger.error('Error initializing AuthProvider', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select('''
            *, 
            user_roles(*)
          ''')
          .eq('id', _user!.id)
          .single();

      _userProfile = UserProfile.fromJson(response);
      
      // Load user role if available
      if (response['user_roles'] != null) {
        _userRole = UserRole.fromJson(response['user_roles'] as Map<String, dynamic>);
        AppLogger.info('User role loaded: ${_userRole?.displayName}');
      }
      
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading user profile', error: e);
      // If profile doesn't exist, try to create one
      if (e.toString().contains('PGRST116')) {
        await _createUserProfile();
      }
    }
  }

  Future<void> _createUserProfile() async {
    if (_user == null) return;

    try {
      // Get default role (employee) - later can be changed by admin
      final roleResponse = await _supabase
          .from('user_roles')
          .select('id')
          .eq('role_name', 'employee')
          .single();

      final profileData = {
        'id': _user!.id,
        'email': _user!.email!,
        'full_name':
            _user!.userMetadata?['full_name'] ?? _user!.email!.split('@')[0],
        'role': _user!.userMetadata?['role'] ?? 'staff', // Legacy field
        'role_id': roleResponse['id'],
        'is_checked_in': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(SupabaseConfig.profilesTable).insert(profileData);

      // Profile and role will be loaded in _loadUserProfile
      await _loadUserProfile();
    } catch (e) {
      AppLogger.error('Error creating user profile', error: e);
      // Only set error if it's not a "already exists" error
      if (!e.toString().contains('duplicate key') && 
          !e.toString().contains('unique constraint')) {
        _setError('Unable to create user profile: ${e.toString()}');
      } else {
        // Profile already exists, try to load it
        await _loadUserProfile();
      }
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadUserProfile();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
    }

    _setLoading(false);
    return false;
  }

  // Future<bool> signUp(
  //     String email, String password, String fullName, String role) async {
  //   _setLoading(true);
  //   _clearError();

  //   try {
  //     final response = await _supabase.auth.signUp(
  //       email: email,
  //       password: password,
  //     );

  //     if (response.user != null) {
  //       // Create user profile with all required fields
  //       await _supabase.from(SupabaseConfig.profilesTable).insert({
  //         'id': response.user!.id,
  //         'email': email,
  //         'full_name': fullName,
  //         'role': role,
  //         'is_checked_in': false,
  //         'created_at': DateTime.now().toIso8601String(),
  //         'updated_at': DateTime.now().toIso8601String(),
  //       });

  //       _user = response.user;
  //       await _loadUserProfile();
  //       _setLoading(false);
  //       return true;
  //     }
  //   } catch (e) {
  //     _setError('Registration failed: ${e.toString()}');
  //   }

  //   _setLoading(false);
  //   return false;
  // }

  Future<bool> signUp(
    String email,
    String password,
    String fullName,
    String role,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );

      // In latest SDK, errors throw exceptions, so no 'response.error'
      if (response.user == null) {
        _setError('Registration failed: No user returned.');
        _setLoading(false);
        return false;
      }

      _user = response.user;
      // Wait a moment for any automatic profile creation to complete
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadUserProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      AppLogger.error('Registration failed', error: e);
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _supabase.auth.signOut();
      _user = null;
      _userProfile = null;
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    }

    _setLoading(false);
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      _setLoading(true);
      await _loadUserProfile();
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? role,
    String? profilePictureUrl,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updateData['full_name'] = fullName;
      if (role != null) updateData['role'] = role;
      if (profilePictureUrl != null) {
        updateData['profile_picture_url'] = profilePictureUrl;
      }

      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update(updateData)
          .eq('id', _user!.id);

      await _loadUserProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Password change failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Image picker and upload
  Future<String?> uploadProfilePicture() async {
    if (_user == null) return null;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image == null) return null;

      final file = File(image.path);
      final fileName =
          'profile_${_user!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to profile-pictures bucket
      await _supabase.storage.from('profile-pictures').upload(fileName, file);

      // Get the public URL
      final publicUrl =
          _supabase.storage.from('profile-pictures').getPublicUrl(fileName);

      // Update user profile with new picture URL
      await updateProfile(profilePictureUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      _setError('Failed to upload profile picture: $e');
      return null;
    }
  }

  // Location services
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _setError('Location permission denied');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return position;
    } catch (e) {
      _setError('Failed to get location: $e');
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check-in/Check-out functionality
  Future<bool> checkIn() async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final position = await getCurrentLocation();
      if (position == null) return false;

      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .update({
            'is_checked_in': true,
            'last_checked_in_at': DateTime.now().toIso8601String(),
            'last_known_latitude': position.latitude,
            'last_known_longitude': position.longitude,
            'last_known_address': address,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _user!.id)
          .select()
          .single();

      _userProfile = UserProfile.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to check in: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkOut() async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final position = await getCurrentLocation();
      if (position == null) return false;

      final address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .update({
            'is_checked_in': false,
            'last_checked_out_at': DateTime.now().toIso8601String(),
            'last_known_latitude': position.latitude,
            'last_known_longitude': position.longitude,
            'last_known_address': address,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _user!.id)
          .select()
          .single();

      _userProfile = UserProfile.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to check out: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
