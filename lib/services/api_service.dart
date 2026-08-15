import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService with ChangeNotifier {
  final String _baseUrl = 'https://api.anzil.online/api';
  String? _token;
  Map<String, dynamic>? _user;

  // CACHE
  List<dynamic>? _cachedProducts;
  DateTime? _lastProductFetch;
  Map<String, dynamic>? _cachedWallet;
  List<dynamic>? _cachedUsers;
  List<dynamic>? _cachedCategories;

  ApiService() {
    _loadPersistedToken();
  }

  Future<void> _loadPersistedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('token');
      final savedUser = prefs.getString('user');
      if (savedToken != null) {
        _token = savedToken;
        if (savedUser != null) {
          _user = jsonDecode(savedUser);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading persisted token: $e');
    }
  }

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get currentUser => _user;

  Future<void> createUserByAdmin(String name, String email, String password, String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_parseErrorMessage(response, 'Failed to create user'));
    }
    _cachedUsers = null;
  }

  String _parseErrorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('message')) {
        return body['message'];
      }
    } catch (_) {
      if (response.statusCode == 404) {
        return 'Backend route not found (404). Please restart/redeploy your Node backend server on api.anzil.online.';
      }
      if (response.body.startsWith('<!DOCTYPE') || response.body.startsWith('<html')) {
        return 'Server error (${response.statusCode}). Backend returned HTML response instead of JSON.';
      }
    }
    return '$fallback (${response.statusCode})';
  }

  Future<void> sendRegisterOtp(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(_parseErrorMessage(response, 'Failed to send OTP'));
    }
  }

  Future<void> registerWithOtp({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'otp': otp,
      }),
    );

    if (response.statusCode == 201) {
      final resData = jsonDecode(response.body);
      _token = resData['token'];
      _user = resData;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(_user));

      notifyListeners();
    } else {
      throw Exception(_parseErrorMessage(response, 'Failed to complete registration'));
    }
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      _token = resData['token'];
      _user = resData;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(_user));
      
      notifyListeners();
    } else {
      throw Exception(_parseErrorMessage(response, 'Failed to login'));
    }
  }

  Future<List<dynamic>> getProducts({bool all = false, bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProducts != null && _lastProductFetch != null && 
        DateTime.now().difference(_lastProductFetch!).inMinutes < 5) {
      return _cachedProducts!;
    }

    final response = await http.get(Uri.parse('$_baseUrl/products${all ? '?all=true' : ''}'));
    if (response.statusCode == 200) {
      _cachedProducts = jsonDecode(response.body);
      _lastProductFetch = DateTime.now();
      return _cachedProducts!;
    } else {
      throw Exception('Failed to load products');
    }
  }

  // CATEGORY METHODS
  Future<List<dynamic>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null) return _cachedCategories!;

    final response = await http.get(Uri.parse('$_baseUrl/categories'));
    if (response.statusCode == 200) {
      _cachedCategories = jsonDecode(response.body);
      return _cachedCategories!;
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> createCategory(String name, String icon) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'name': name, 'icon': icon}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create category');
    }
    _cachedCategories = null;
  }

  Future<void> deleteCategory(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/categories/$id'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete category');
    }
    _cachedCategories = null;
  }

  Future<void> buyProduct(String productId, {int quantity = 1}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/orders/buy'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to buy: ${jsonDecode(response.body)['message']}');
    }
    _cachedWallet = null;
    _cachedProducts = null;
  }

  Future<Map<String, dynamic>> getMyWallet({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedWallet != null) return _cachedWallet!;

    final response = await http.get(
      Uri.parse('$_baseUrl/coins/mywallet'),
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );

    if (response.statusCode == 200) {
      _cachedWallet = jsonDecode(response.body);
      return _cachedWallet!;
    } else {
      throw Exception('Failed to load wallet');
    }
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required num priceInCoins,
    required String category,
    required int stock,
    required String imageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'priceInCoins': priceInCoins,
        'category': category,
        'stock': stock,
        'images': imageUrl.isNotEmpty ? [imageUrl] : [],
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create product: ${jsonDecode(response.body)['message']}');
    }
    _cachedProducts = null;
  }

  Future<List<dynamic>> getUsers({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUsers != null) return _cachedUsers!;

    final response = await http.get(
      Uri.parse('$_baseUrl/users'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode == 200) {
      _cachedUsers = jsonDecode(response.body);
      return _cachedUsers!;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> blockUser(String id) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$id/block'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to block user');
    }
    _cachedUsers = null;
  }

  Future<void> unblockUser(String id) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$id/unblock'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to unblock user');
    }
    _cachedUsers = null;
  }

  Future<void> addCoins(String userId, int amount) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId/coins'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
      body: jsonEncode({'amount': amount}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add coins');
    }
    _cachedUsers = null;
    _cachedWallet = null;
  }

  Future<List<dynamic>> getPendingOrders() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/pending'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load pending orders');
    }
  }

  Future<List<dynamic>> getMyOrders() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/myorders'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load your orders');
    }
  }

  Future<void> approveOrder(String orderId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/orders/$orderId/approve'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to approve order');
    }
    _cachedProducts = null;
    _cachedWallet = null;
  }

  Future<void> rejectOrder(String orderId) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/orders/$orderId/reject'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject order');
    }
    _cachedProducts = null;
    _cachedWallet = null;
  }

  Future<void> blockProduct(String id) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$id/block'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to block product');
    }
    _cachedProducts = null;
  }

  Future<void> unblockProduct(String id) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/products/$id/unblock'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to unblock product');
    }
    _cachedProducts = null;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _cachedProducts = null;
    _cachedWallet = null;
    _cachedUsers = null;
    _cachedCategories = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }
}
