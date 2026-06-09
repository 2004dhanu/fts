import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/donor.dart';

class AuthProvider extends ChangeNotifier {
  static const String baseUrl = 'https://agstest.in/api2/public/api';
  
  bool _isLoading = false;
  String? _token;
  Map<String, dynamic>? _userData;
  List<Donor> _donors = [];

  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;
  List<Donor> get donors => _donors;

  AuthProvider() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      _userData = json.decode(userDataString);
    }
    // Use WidgetsBinding to schedule notification after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', json.encode(userData));
    _token = token;
    _userData = userData;
    notifyListeners();
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _token = null;
    _userData = null;
    _donors = [];
    notifyListeners();
  }

  // Check User API
  Future<Map<String, dynamic>?> checkUser(String username) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app-check-mobile'),
        body: {'username': username},
      );
      
      debugPrint('Check User Response: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Check user error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Sign Up API
  Future<Map<String, dynamic>> signUp(Map<String, String> userData) async {
    _setLoading(true);
    try {
      debugPrint('📝 Signup Request: $userData');
      
      final response = await http.post(
        Uri.parse('$baseUrl/app-signup'),
        body: userData,
      );
      
      debugPrint('📝 Signup Response Status: ${response.statusCode}');
      debugPrint('📝 Signup Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['code'] == 201) {
          // Try to login with the same credentials
          final loginResult = await login(
            userData['name']!, 
            userData['password']!
          );
          
          if (loginResult['success'] == true) {
            return {
              'success': true,
              'message': 'Account created and logged in successfully!',
              'autoLoggedIn': true,
            };
          }
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'User Created Successfully',
          'autoLoggedIn': false,
        };
      } else {
        return {
          'success': false,
          'message': 'Signup failed with status: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Sign up error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  // Login API
  Future<Map<String, dynamic>> login(String username, String password) async {
    _setLoading(true);
    try {
      debugPrint('🔐 Login Request - Username: $username');
      
      final response = await http.post(
        Uri.parse('$baseUrl/app-login'),
        body: {
          'username': username,
          'password': password,
        },
      );
      
      debugPrint('🔐 Login Response Status: ${response.statusCode}');
      debugPrint('🔐 Login Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['code'] == 200) {
          String? token;
          Map<String, dynamic>? user;
          
          if (data['data'] != null) {
            if (data['data']['token'] != null) {
              token = data['data']['token'];
              user = data['data']['user'];
            } else if (data['token'] != null) {
              token = data['token'];
              user = data['user'];
            }
          } else if (data['token'] != null) {
            token = data['token'];
            user = data['user'];
          }
          
          if (token != null) {
            await _saveAuthData(token, user ?? {});
            debugPrint('✅ Token saved successfully');
            
            return {
              'success': true,
              'message': data['message'] ?? 'Login successful',
              'token': token,
              'user': user,
            };
          } else {
            debugPrint('⚠️ No token found in response');
            return {
              'success': false,
              'message': 'No token received from server',
            };
          }
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Invalid username or password',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  // Forgot Password API
  Future<Map<String, dynamic>> forgotPassword(String username, String email) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app-forget-password'),
        body: {'username': username, 'email': email},
      );
      
      debugPrint('Forgot Password Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Reset instructions sent to your email',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send reset instructions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  // Change Password API
  Future<Map<String, dynamic>> changePassword(String username, String oldPassword, String newPassword) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/app-change-password'),
        body: {
          'username': username,
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      
      debugPrint('Change Password Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to change password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  // Fetch Donor List - Try multiple possible endpoints
 // Fetch Donor List - Updated with image URL handling
Future<List<Donor>> fetchDonorList() async {
  _setLoading(true);
  try {
    List<Donor> donors = [];
    String donorImageBaseUrl = '';
    
    // Try different possible endpoints
    final List<String> endpoints = [
      '$baseUrl/app-fetch-donor-list',
      '$baseUrl/donors',
      '$baseUrl/app-donors',
      '$baseUrl/indicomps',
    ];
    
    for (String endpoint in endpoints) {
      try {
        final uri = Uri.parse(endpoint);
        final request = http.Request('GET', uri);
        
        if (_token != null && _token!.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $_token';
        }
        
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        
        debugPrint('📊 Trying endpoint: $endpoint');
        debugPrint('📊 Status: ${response.statusCode}');
        
        if (response.statusCode == 200 && responseBody.isNotEmpty) {
          final dynamic data = json.decode(responseBody);
          
          // Parse image URLs from response
          if (data is Map<String, dynamic>) {
            // Extract image base URL if present
            if (data['image_url'] != null && data['image_url'] is List) {
              for (var img in data['image_url']) {
                if (img['image_for'] == 'Donor') {
                  donorImageBaseUrl = img['image_url'] ?? '';
                  debugPrint('📸 Donor image base URL: $donorImageBaseUrl');
                }
              }
            }
          }
          
          // Parse donor list
          List<dynamic> donorList = [];
          
          if (data is Map<String, dynamic>) {
            if (data['data'] != null && data['data'] is List) {
              donorList = data['data'] as List<dynamic>;
            } else if (data['donors'] != null && data['donors'] is List) {
              donorList = data['donors'] as List<dynamic>;
            } else if (data['users'] != null && data['users'] is List) {
              donorList = data['users'] as List<dynamic>;
            } else if (data['indicomps'] != null && data['indicomps'] is List) {
              donorList = data['indicomps'] as List<dynamic>;
            }
          } else if (data is List) {
            donorList = data;
          }
          
          if (donorList.isNotEmpty) {
            // Pass the image base URL to the Donor model
            donors = donorList.map((json) {
              var donor = Donor.fromJson(json as Map<String, dynamic>);
              // Update the image URL for each donor
              return Donor.fromJsonWithImageUrl(
                json as Map<String, dynamic>, 
                donorImageBaseUrl
              );
            }).toList();
            debugPrint('✅ Loaded ${donors.length} donors from $endpoint');
            break;
          }
        } else if (response.statusCode == 401) {
          debugPrint('❌ Unauthorized at $endpoint');
        }
      } catch (e) {
        debugPrint('Error with endpoint $endpoint: $e');
      }
    }
    
    _donors = donors;
    // Use WidgetsBinding to ensure notification happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    return _donors;
  } catch (e) {
    debugPrint('Fetch donor list error: $e');
    return [];
  } finally {
    _setLoading(false);
  }
}
  // Fetch Donor By ID
  Future<Donor?> fetchDonorById(String id) async {
    _setLoading(true);
    try {
      final uri = Uri.parse('$baseUrl/app-fetch-donor-by-id/$id');
      final request = http.Request('GET', uri);
      
      if (_token != null && _token!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(responseBody);
        if (data['data'] != null) {
          return Donor.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Fetch donor by id error: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  String get currentUserName {
    if (_userData != null) {
      return _userData!['name'] ?? _userData!['full_name'] ?? 'User';
    }
    return 'User';
  }

  void logout() async {
    await _clearAuthData();
    // Use WidgetsBinding to ensure notification happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    // Use WidgetsBinding to schedule notification after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}