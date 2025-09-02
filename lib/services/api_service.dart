import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = '';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<bool>? _refreshTokenFuture;

  // Safe JSON decode helper method
  Map<String, dynamic>? safeJsonDecode(String responseBody) {
    try {
      return json.decode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      print('JSON decode error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/driver/login');

    print('[DRIVER_LOGIN] Starting driver login process...');
    print('[DRIVER_LOGIN] POST to: $url');
    print('[DRIVER_LOGIN] username: $username');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      print('[DRIVER_LOGIN] Response status: ${response.statusCode}');
      print('[DRIVER_LOGIN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = safeJsonDecode(response.body);
        
        if (responseData != null) {
          // Save all relevant fields to secure storage
          final fieldsToStore = {
            'token': responseData['token']?.toString(),
            'refresh_token': responseData['refresh_token']?.toString(),
            'user_id': responseData['user_id']?.toString(),
            'driver_id': responseData['driver_id']?.toString(), // Driver-specific ID
            'phone_number': responseData['phone_number']?.toString(),
            'first_name': responseData['first_name']?.toString(),
            'middle_name': responseData['middle_name']?.toString(),
            'last_name': responseData['last_name']?.toString(),
            'username': responseData['username']?.toString(),
            'vehicle_info': responseData['vehicle_info']?.toString(), // Driver vehicle info
            'license_number': responseData['license_number']?.toString(), // Driver license
            'status': responseData['status']?.toString(), // Driver status (active/inactive)
          };

          for (var entry in fieldsToStore.entries) {
            if (entry.value != null) {
              await _secureStorage.write(key: entry.key, value: entry.value!);
            }
          }

          print('[DRIVER_LOGIN] Login successful, data stored');
          return responseData;
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - wrong credentials or unverified account
        final responseData = safeJsonDecode(response.body);
        print('[DRIVER_LOGIN] Unauthorized: ${responseData?['error']}');
        return responseData ?? {'error': 'Invalid credentials'};
      } else if (response.statusCode == 403) {
        // Forbidden - account might be suspended or not approved
        final responseData = safeJsonDecode(response.body);
        print('[DRIVER_LOGIN] Forbidden: ${responseData?['error']}');
        return responseData ?? {'error': 'Account not approved or suspended'};
      } else {
        print('[DRIVER_LOGIN] Unexpected status code: ${response.statusCode}');
        final responseData = safeJsonDecode(response.body);
        return responseData ?? {'error': 'Login failed. Please try again.'};
      }
    } catch (ex) {
      print('[DRIVER_LOGIN] Exception occurred: $ex');
      return {'error': 'Network error. Please check your connection.'};
    }

    return null;
  }

  // Make authenticated requests with automatic token refresh
  static Future<http.Response> makeAuthenticatedRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
    int retryCount = 0,
  }) async {
    final token = await _secureStorage.read(key: 'token');
    final driverId = await _secureStorage.read(key: 'driver_id');

    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (driverId != null) 'Driver-ID': driverId,
      ...?headers,
    };

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(Uri.parse(url), headers: requestHeaders, body: body);
          break;
        case 'PUT':
          response = await http.put(Uri.parse(url), headers: requestHeaders, body: body);
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      print('[AUTH_REQUEST] Network error: $e');
      throw Exception('Network error: $e');
    }

    // If we get a 401 (unauthorized) and haven't already retried
    if (response.statusCode == 401 && retryCount == 0) {
      print('[AUTH_REQUEST] Received 401, attempting token refresh...');

      final refreshSuccess = await refreshToken();
      if (refreshSuccess) {
        print('[AUTH_REQUEST] Token refreshed, retrying original request...');
        // Retry the original request with the new token
        return makeAuthenticatedRequest(
          method: method,
          url: url,
          headers: headers,
          body: body,
          retryCount: 1, // Prevent infinite retry loop
        );
      } else {
        print('[AUTH_REQUEST] Token refresh failed, clearing tokens...');
        // Clear only authentication tokens, preserve user data
        await _secureStorage.delete(key: 'token');
        await _secureStorage.delete(key: 'refresh_token');
      }
    }

    return response;
  }

  static Future<bool> refreshToken() async {
    // If there's already a refresh in progress, wait for it to complete
    if (_refreshTokenFuture != null) {
      print('[REFRESH_TOKEN] Waiting for existing refresh to complete...');
      return await _refreshTokenFuture!;
    }

    // Start the refresh process and store the future
    _refreshTokenFuture = _performTokenRefresh();
    
    try {
      final result = await _refreshTokenFuture!;
      return result;
    } finally {
      // Clear the future when done
      _refreshTokenFuture = null;
    }
  }

  // Extract the actual refresh logic to a separate method
  static Future<bool> _performTokenRefresh() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (refreshToken == null) {
        print('[REFRESH_TOKEN] No refresh token found');
        return false;
      }

      print('[REFRESH_TOKEN] Attempting to refresh driver token...');

      final url = Uri.parse('$_baseUrl/driver/refresh-token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'refresh_token': refreshToken,
          'user_type': 'driver',
        }),
      );

      print('[REFRESH_TOKEN] Response status: ${response.statusCode}');
      print('[REFRESH_TOKEN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Save new tokens
        await _secureStorage.write(key: 'token', value: responseData['token']);
        await _secureStorage.write(key: 'refresh_token', value: responseData['refresh_token']);

        print('[REFRESH_TOKEN] Driver token refreshed successfully');
        return true;
      } else {
        print('[REFRESH_TOKEN] Failed to refresh token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[REFRESH_TOKEN] Error refreshing token: $e');
      return false;
    }
  }
}