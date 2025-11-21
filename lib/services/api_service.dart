import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // API Gateway endpoint
  static const String baseUrl =
      'https://evtwkxans4.execute-api.ap-south-1.amazonaws.com/prod';

  // Cognito configuration
  static const String userPoolId = 'ap-south-1_KEGPzHo0I';
  static const String clientId = 'os5urmu6qi4k96ascqt5m2re0';
  static const String region = 'ap-south-1';

  // Get Cognito ID Token for authorization
  static Future<String?> _getIdToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // First try to get the stored ID token
      final storedToken = prefs.getString('cognito_id_token');
      if (storedToken != null && storedToken.isNotEmpty) {
        debugPrint('Using stored ID token');
        return storedToken;
      }

      // Fallback: Try to get session from Cognito (for older sessions)
      final email = prefs.getString('cognito_user_email');
      if (email == null) {
        debugPrint('User not logged in - no email');
        return null;
      }

      final userPool = CognitoUserPool(userPoolId, clientId);
      final cognitoUser = CognitoUser(email, userPool);

      final session = await cognitoUser.getSession();
      if (session == null || !session.isValid()) {
        debugPrint('Session invalid or null');
        return null;
      }

      // Store the token for next time
      final token = session.getIdToken().getJwtToken();
      if (token != null) {
        await prefs.setString('cognito_id_token', token);
      }

      return token;
    } catch (e) {
      debugPrint('Error getting ID token: $e');
      return null;
    }
  }

  // Get common headers with Cognito authorization
  static Future<Map<String, String>> _getHeaders() async {
    final idToken = await _getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': idToken ?? '',
    };
  }

  // ==================== USER ENDPOINTS ====================

  /// Get user profile
  static Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final headers = await _getHeaders();
      debugPrint('Getting user with ID: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      debugPrint('Get user response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('User data received: $data');
        return data;
      } else {
        debugPrint('Get user error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Get user exception: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>?> updateUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      debugPrint('Updating user $userId with data: $userData');
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
        body: json.encode(userData),
      );

      debugPrint('Update user response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Updated user data: $data');
        return data;
      } else {
        debugPrint(
            'Update user error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Update user exception: $e');
      return null;
    }
  }

  // ==================== ITEMS ENDPOINTS ====================

  /// Get list of items with optional filters
  static Future<List<Map<String, dynamic>>> getItems({
    String? category,
    String? sellerId,
    String status = 'active',
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'status': status,
        if (category != null) 'category': category,
        if (sellerId != null) 'sellerId': sellerId,
      };

      final uri =
          Uri.parse('$baseUrl/items').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        debugPrint('Get items error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Get items exception: $e');
      return [];
    }
  }

  /// Get single item details
  static Future<Map<String, dynamic>?> getItem(String itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/items/$itemId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Get item error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Get item exception: $e');
      return null;
    }
  }

  /// Create new item
  static Future<Map<String, dynamic>?> createItem(
    Map<String, dynamic> itemData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/items'),
        headers: headers,
        body: json.encode(itemData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        debugPrint(
            'Create item error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Create item exception: $e');
      return null;
    }
  }

  /// Update existing item
  static Future<Map<String, dynamic>?> updateItem(
    String itemId,
    Map<String, dynamic> itemData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/items/$itemId'),
        headers: headers,
        body: json.encode(itemData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint(
            'Update item error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Update item exception: $e');
      return null;
    }
  }

  /// Delete item
  static Future<bool> deleteItem(String itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/items/$itemId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            'Delete item error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Delete item exception: $e');
      return false;
    }
  }

  // ==================== CART ENDPOINTS ====================

  /// Get user's cart items
  static Future<List<Map<String, dynamic>>> getCart() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        debugPrint('Get cart error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Get cart exception: $e');
      return [];
    }
  }

  /// Add item to cart
  static Future<bool> addToCart({
    required String itemId,
    required String sellerId,
    int quantity = 1,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/cart'),
        headers: headers,
        body: json.encode({
          'itemId': itemId,
          'sellerId': sellerId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Add to cart error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Add to cart exception: $e');
      return false;
    }
  }

  /// Remove item from cart
  static Future<bool> removeFromCart(String itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$itemId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            'Remove from cart error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Remove from cart exception: $e');
      return false;
    }
  }

  /// Checkout selected items
  static Future<Map<String, dynamic>?> checkout(List<String> itemIds) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/cart/checkout'),
        headers: headers,
        body: json.encode({'itemIds': itemIds}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('Checkout error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Checkout exception: $e');
      return null;
    }
  }

  // ==================== PURCHASES ENDPOINTS ====================

  /// Get user's purchase history
  static Future<List<Map<String, dynamic>>> getPurchases() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/purchases'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['purchases'] ?? []);
      } else {
        debugPrint(
            'Get purchases error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Get purchases exception: $e');
      return [];
    }
  }
}
