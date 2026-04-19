import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';
import '../utils/permission_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _initialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  // Initialize and restore user from storage
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await ApiService.getToken();
      final userJson = prefs.getString('user_data');
      
      if (token != null && userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
        // Force reload permissions on every app start to get latest changes
        await PermissionHelper.loadPermissions(_user!.role, forceReload: true);
      }
    } catch (e) {
      // Ignore errors during initialization
    }
    
    _initialized = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post(
        ApiConfig.authEndpoint,
        {'username': username, 'password': password},
      );

      if (response['success'] == true) {
        // Save token
        await ApiService.saveToken(response['token']);
        
        // Save user data to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(response['user']));
        
        // Set user in memory
        _user = User.fromJson(response['user']);
        
        // Load permissions for this user
        await PermissionHelper.loadPermissions(_user!.role);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    await ApiService.removeToken();
    
    // Remove user data from storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    
    // Clear permission cache
    PermissionHelper.clearCache();
    
    notifyListeners();
  }
}
