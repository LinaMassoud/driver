import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = 'http://fawran.ddns.net:8080/ords/emdad/driver';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<bool>? _refreshTokenFuture;
  static bool _isRefreshing = false;

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
    final url = Uri.parse('$_baseUrl/login');

    print('[DRIVER_LOGIN] Starting driver login process...');
    print('[DRIVER_LOGIN] POST to: $url');
    print('[DRIVER_LOGIN] username: $username');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'driver_username': username,
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
            'token': responseData['token'],
            'refresh_token': responseData['refresh_token'],
            'car_id': responseData['car_id']?.toString(),
            'driver_username': responseData['driver_username'],
            'car_name': responseData['car_name'],
            'car_brand': responseData['car_brand'],
            'car_color': responseData['car_color'],
          };

          for (var entry in fieldsToStore.entries) {
            if (entry.value != null) {
              await _secureStorage.write(key: entry.key, value: entry.value!);
            }
          }

          print('[DRIVER_LOGIN] Login successful, data stored');
          return responseData;
        }
      } else if (response.statusCode == 404) {
        final responseData = safeJsonDecode(response.body);
        print('[DRIVER_LOGIN] Login failed: ${responseData?['message']}');
        return responseData ?? {'error': 'Driver not found'};
      } else if (response.statusCode == 401) {
        final responseData = safeJsonDecode(response.body);
        print('[DRIVER_LOGIN] Unauthorized: ${responseData?['message']}');
        return responseData ?? {'error': 'Invalid credentials'};
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

  // Make authenticated requests with improved token refresh handling
  static Future<http.Response> makeAuthenticatedRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
    int retryCount = 0,
  }) async {
    // If we're currently refreshing, wait for it to complete
    if (_isRefreshing && _refreshTokenFuture != null) {
      print('[AUTH_REQUEST] Waiting for ongoing refresh to complete...');
      await _refreshTokenFuture!;
    }

    final token = await _secureStorage.read(key: 'token');
    print('[AUTH_REQUEST] Using token: ${token}');

    final requestHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'token': token,
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

    print('[AUTH_REQUEST] Response status: ${response.statusCode} for $method $url');

    // If we get a 401 (unauthorized) and haven't already retried
    if (response.statusCode == 401 && retryCount == 0) {
      print('[AUTH_REQUEST] Received 401, attempting token refresh...');

      final refreshSuccess = await refreshToken();
      if (refreshSuccess) {
        print('[AUTH_REQUEST] Token refreshed successfully, retrying original request...');
        // Add a small delay to ensure token is properly saved
        await Future.delayed(Duration(milliseconds: 100));
        
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

    // Set the flag to indicate refresh is in progress
    _isRefreshing = true;
    
    // Start the refresh process and store the future
    _refreshTokenFuture = _performTokenRefresh();
    
    try {
      final result = await _refreshTokenFuture!;
      return result;
    } finally {
      // Clear the future and flag when done
      _refreshTokenFuture = null;
      _isRefreshing = false;
    }
  }

  // Extract the actual refresh logic to a separate method
  static Future<bool> _performTokenRefresh() async {
    try {
      final oldToken = await _secureStorage.read(key: 'token');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (refreshToken == null) {
        print('[REFRESH_TOKEN] No refresh token found');
        return false;
      }

      print('[REFRESH_TOKEN] Attempting to refresh driver token...');
      print('[REFRESH_TOKEN] Using refresh token: ${refreshToken.substring(0, 10)}...');

      final url = Uri.parse('$_baseUrl/refresh-token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'refresh_token': refreshToken,
        }),
      );

      print('[REFRESH_TOKEN] Response status: ${response.statusCode}');
      print('[REFRESH_TOKEN] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Validate that we received both tokens
        if (responseData['token'] != null && responseData['refresh_token'] != null) {
          final newToken = responseData['token'].toString();
          
          // CHECK: If server returned the same token, it's a server bug
          if (newToken == oldToken) {
            print('[REFRESH_TOKEN] WARNING: Server returned the same token! This is a server-side bug.');
            print('[REFRESH_TOKEN] Old token: ${oldToken?.substring(0, 30)}...');
            print('[REFRESH_TOKEN] New token: ${newToken.substring(0, 30)}...');
            
            // Return false to indicate refresh failed due to server issue
            return false;
          }
          
          // Save new tokens
          await _secureStorage.write(key: 'token', value: newToken);
          await _secureStorage.write(key: 'refresh_token', value: responseData['refresh_token']);

          print('[REFRESH_TOKEN] New token saved: ${newToken.substring(0, 20)}...');
          print('[REFRESH_TOKEN] Driver token refreshed successfully');
          return true;
        } else {
          print('[REFRESH_TOKEN] Invalid response: missing tokens');
          return false;
        }
      } else {
        print('[REFRESH_TOKEN] Failed to refresh token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('[REFRESH_TOKEN] Error refreshing token: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>?> getOrderTypes() async {
    try {
      final url = '$_baseUrl/order-types';
      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url,
      );

      print('[ORDER_TYPES] Response status: ${response.statusCode}');
      print('[ORDER_TYPES] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('[ORDER_TYPES] Failed to fetch order types: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[ORDER_TYPES] Error fetching order types: $e');
      return null;
    }
  }

  // Fetch shifts
  static Future<List<Map<String, dynamic>>?> getShifts() async {
    try {
      final url = Uri.parse('$_baseUrl/shifts');
      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url.toString(),
      );

      print('[SHIFTS] Response status: ${response.statusCode}');
      print('[SHIFTS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('[SHIFTS] Failed to fetch shifts: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[SHIFTS] Error fetching shifts: $e');
      return null;
    }
  }

  // Fetch visit statuses
  static Future<List<Map<String, dynamic>>?> getVisitStatuses() async {
    try {
      final url = Uri.parse('$_baseUrl/visit-statuses');
      final response = await makeAuthenticatedRequest(
        method: 'GET',
        url: url.toString(),
      );

      print('[VISIT_STATUSES] Response status: ${response.statusCode}');
      print('[VISIT_STATUSES] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('[VISIT_STATUSES] Failed to fetch visit statuses: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('[VISIT_STATUSES] Error fetching visit statuses: $e');
      return null;
    }
  }

  static Future<dynamic> getVisits({
  required int carId,
  required int shiftId,
  required String date,
}) async {
  try {
    final url = Uri.parse('$_baseUrl/get-visits');
    final requestBody = {
      'car_id': carId,
      'shift_id': shiftId,
      'date': date,
    };

    print('[GET_VISITS] Request body: ${json.encode(requestBody)}');
    final response = await makeAuthenticatedRequest(
      method: 'POST',
      url: url.toString(),
      body: json.encode({
        'car_id': carId,
        'shift_id': shiftId,
        'date': date,
      }),
    );

    print('[GET_VISITS] Response status: ${response.statusCode}');
    print('[GET_VISITS] Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Handle both array and object responses
      final responseData = json.decode(response.body);
      return responseData; // Return the decoded data directly
    } else {
      print('[GET_VISITS] Failed to fetch visits: ${response.statusCode}');
      final responseData = json.decode(response.body);
      return {'error': responseData['message'] ?? 'Failed to fetch visits'};
    }
  } catch (e) {
    print('[GET_VISITS] Error fetching visits: $e');
    return {'error': 'Network error. Please check your connection.'};
  }
}

static Future<Map<String, dynamic>?> getCustomerAddressDetails(int addressId) async {
  try {
    final url = Uri.parse('$_baseUrl/get-customer-address-details/$addressId');
    final response = await makeAuthenticatedRequest(
      method: 'GET',
      url: url.toString(),
    );

    print('[ADDRESS_DETAILS] Response status: ${response.statusCode}');
    print('[ADDRESS_DETAILS] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data;
    } else {
      print('[ADDRESS_DETAILS] Failed to fetch address details: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('[ADDRESS_DETAILS] Error fetching address details: $e');
    return null;
  }
}
static Future<Map<String, dynamic>> updateAppointment({
  required int appointmentId,
  int? visitStatusId,
  String? actualStartDatetime,
  String? actualEndDatetime,
  String? location,
  String? notes,
}) async {
  try {
    final url = Uri.parse('$_baseUrl/update-appointment');
    
    // Build request body - only include non-null values
    final Map<String, dynamic> requestBody = {
      'appointment_id': appointmentId,
    };
    
    if (visitStatusId != null) {
      requestBody['visit_status_id'] = visitStatusId;
    }
    if (actualStartDatetime != null) {
      requestBody['actual_start_datetime'] = actualStartDatetime;
    }
    if (actualEndDatetime != null) {
      requestBody['actual_end_datetime'] = actualEndDatetime;
    }
    if (location != null) {
      requestBody['location'] = location;
    }
    if (notes != null) {
      requestBody['notes'] = notes;
    }

    print('[UPDATE_APPOINTMENT] Request body: ${json.encode(requestBody)}');
    
    final response = await makeAuthenticatedRequest(
      method: 'PUT',
      url: url.toString(),
      body: json.encode(requestBody),
    );

    print('[UPDATE_APPOINTMENT] Response status: ${response.statusCode}');
    print('[UPDATE_APPOINTMENT] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return {
        'success': true,
        'data': responseData,
      };
    } else {
      final responseData = json.decode(response.body);
      return {
        'success': false,
        'error': responseData['message'] ?? 'Failed to update appointment',
      };
    }
  } catch (e) {
    print('[UPDATE_APPOINTMENT] Error updating appointment: $e');
    return {
      'success': false,
      'error': 'Network error. Please check your connection.',
    };
  }
}
}