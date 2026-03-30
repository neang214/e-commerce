import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User?  _user;
  bool   _loading     = false;
  bool   _initialized = false;

  User? get user        => _user;
  bool  get loading     => _loading;
  bool  get isLoggedIn  => _user != null;
  bool  get initialized => _initialized;

  // Called once on app launch — restores session from stored token
  Future<void> init() async {
    final token = await ApiService.getToken();
    if (token != null) {
      try {
        _user = await ApiService.getMe();
      } catch (_) {
        // Token expired or invalid — clear it
        await ApiService.clearToken();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  // Returns null on success, error string on failure
  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.login(email, password);
      await ApiService.saveToken(data['token']);
      _user = User.fromJson(data['user']);
      return null; // success
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners(); // always fires — covers both success and failure
    }
  }

  // Registers then auto-logs in. Returns null on success, error string on failure.
  Future<String?> register(String name, String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      await ApiService.register(name, email, password);
      // Auto-login after successful registration
      final data = await ApiService.login(email, password);
      await ApiService.saveToken(data['token']);
      _user = User.fromJson(data['user']);
      return null; // success — _AuthGate will now show _Shell
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners(); // always fires — triggers _AuthGate rebuild
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners(); // _AuthGate will switch back to LoginScreen
  }
}
