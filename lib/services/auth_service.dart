import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  static const String _sessionKey = 'user_session';

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = prefs.getString(_sessionKey);
      
      if (session != null) {
        final user = _supabase.auth.currentUser;
        return user != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await prefs.setString(_sessionKey, session.accessToken);
      }
    } catch (e) {
      // Handle error
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await _supabase.auth.signOut();
    } catch (e) {
      // Handle error
    }
  }

  static Future<supabase.User?> getCurrentUser() async {
    try {
      return _supabase.auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      await clearSession();
    } catch (e) {
      // Handle error
    }
  }

  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<supabase.AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  supabase.User? get currentUser => _supabase.auth.currentUser;
} 