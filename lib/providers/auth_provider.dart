import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _errorMessage;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _loadAppUser(user.uid);
      } else {
        _appUser = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  AppUser? get appUser => _appUser;
  String? get role => _appUser?.role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadAppUser(String uid) async {
    _appUser = await _firestoreService.getUser(uid);
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn && _authService.currentUser != null) {
      _user = _authService.currentUser;
      await _loadAppUser(_user!.uid);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _authService.signIn(
        email: email,
        password: password,
      );
      _user = credential?.user;
      if (_user != null) {
        await _loadAppUser(_user!.uid);
        if (_appUser != null && !_appUser!.isActive) {
          await _authService.signOut();
          _user = null;
          _appUser = null;
          _errorMessage = 'Account deactivated. Contact administrator.';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final credential = await _authService.signUp(
        email: email,
        password: password,
      );
      _user = credential?.user;
      if (_user != null) {
        final newUser = AppUser(
          uid: _user!.uid,
          name: name,
          email: email,
          role: 'rider',
          isActive: true,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUserDoc(newUser);
        _appUser = newUser;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _user = null;
    _appUser = null;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
