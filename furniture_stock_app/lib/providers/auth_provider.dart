import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      _loadUserProfile();
    }
    
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', _user!.id)
          .single();
      
      _userProfile = UserProfile.fromJson(response);
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
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

  Future<bool> signUp(String email, String password, String fullName, String role) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Create user profile
        await _supabase.from(SupabaseConfig.profilesTable).insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'role': role,
        });
        
        _user = response.user;
        await _loadUserProfile();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
    }
    
    _setLoading(false);
    return false;
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

  Future<bool> updateProfile(String fullName, String role) async {
    if (_user == null) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      await _supabase.from(SupabaseConfig.profilesTable).update({
        'full_name': fullName,
        'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _user!.id);
      
      await _loadUserProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
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
}

