// providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

final userIdProvider = StateProvider<int?>((ref) => null);
const _storage = FlutterSecureStorage();

class AuthState {
  final bool isLoading;
  bool isVerified = true;
  final bool isSignedUp;
  final bool isLoggedIn;
  final String errorMessage;
  final String? token;
  final String? refreshToken;
  final int? userId;
  final int? carId;
  final String? driverUsername;
  final String? carName;

  AuthState({
    required this.isLoading,
    required this.isSignedUp,
    required this.isLoggedIn,
    required this.errorMessage,
    required this.isVerified,
    this.token,
    this.refreshToken,
    this.userId,
    this.carId,
    this.driverUsername,
    this.carName,
  });

  factory AuthState.initial() {
    return AuthState(
      isLoading: false,
      isVerified: true,
      isSignedUp: false,
      isLoggedIn: false,
      errorMessage: '',
      token: null,
      refreshToken: null,
      userId: null,
      carId: null,
      driverUsername: null,
      carName: null,
    );
  }

  AuthState copyWith({
    bool? isLoading,
    bool? isSignedUp,
    bool? isLoggedIn,
    String? errorMessage,
    String? token,
    String? refreshToken,
    int? userId,
    int? carId,
    String? driverUsername,
    String? carName,
    bool? isVerified = true,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isSignedUp: isSignedUp ?? this.isSignedUp,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      errorMessage: errorMessage ?? this.errorMessage,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      carId: carId ?? this.carId,
      driverUsername: driverUsername ?? this.driverUsername,
      carName: carName ?? this.carName,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final Ref _ref;

  AuthNotifier(this._ref, this._apiService) : super(AuthState.initial());

  void _setUserId(int? userId) {
    _ref.read(userIdProvider.notifier).state = userId;
  }

  Future<void> login({
    required String username,
    required String password,
    required WidgetRef ref,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: '', isSignedUp: false);
    print("_apiService.login ");

    final result = await _apiService.login(
      username: username,
      password: password,
    );
    print("result = $result");

    if (result != null) {
      // Check if the response contains an error message (from 404 or other error status)
      if (result['message'] != null) {
        String errorMessage = result['message'];
        
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage,
        );
      }
      // Check if the response contains a generic error field
      else if (result['error'] != null) {
        String errorMessage = result['error'];
        
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage,
        );
      }
      // Check for a successful login based on your API response structure
      else if (result['token'] != null && 
               result['refresh_token'] != null && 
               result['car_id'] != null) {
        final token = result['token'];
        final refreshToken = result['refresh_token'];
        final carId = result['car_id'];
        final driverUsername = result['driver_username'];
        final carName = result['car_name'];

        // Set car_id as user ID for compatibility
        _setUserId(carId);

        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isSignedUp: false,
          token: token,
          refreshToken: refreshToken,
          userId: carId, // Using car_id as userId
          carId: carId,
          driverUsername: driverUsername,
          carName: carName,
          isVerified: true, // User is verified after login success
        );
      }
      // If the response is unexpected (i.e., no token or refresh_token)
      else {
        print("response is unexpected");
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Login failed. Please check your credentials.',
        );
      }
    } else {
      print("Login Failed!!");
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed. Please try again.',
      );
    }
  }

  void logout(WidgetRef ref) {
    _storage.deleteAll();
    _setUserId(null);
    state = AuthState.initial();
  }

  clearStateError() {
    state = state.copyWith(errorMessage: '');
  }

  // Initialize auth state from stored tokens
  Future<void> initializeAuth() async {
    try {
      final token = await _storage.read(key: 'token');
      final refreshToken = await _storage.read(key: 'refresh_token');
      final carIdStr = await _storage.read(key: 'car_id');
      final driverUsername = await _storage.read(key: 'driver_username');
      final carName = await _storage.read(key: 'car_name');

      if (token != null && refreshToken != null && carIdStr != null) {
        final carId = int.tryParse(carIdStr);
        if (carId != null) {
          _setUserId(carId);
          state = state.copyWith(
            isLoggedIn: true,
            isVerified: true,
            token: token,
            refreshToken: refreshToken,
            userId: carId,
            carId: carId,
            driverUsername: driverUsername,
            carName: carName,
          );
        }
      }
    } catch (e) {
      print('Error initializing auth: $e');
      // Clear corrupted data
      await _storage.deleteAll();
    }
  }
}

// Create a provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref, ApiService());
});