import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';

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
        print('Using stored ID token');
        return storedToken;
      }

      // Fallback: Try to get session from Cognito (for older sessions)
      final email = prefs.getString('cognito_user_email');
      if (email == null) {
        print('User not logged in - no email');
        return null;
      }

      final userPool = CognitoUserPool(userPoolId, clientId);
      final cognitoUser = CognitoUser(email, userPool);

      final session = await cognitoUser.getSession();
      if (session == null || !session.isValid()) {
        print('Session invalid or null');
        return null;
      }

      // Store the token for next time
      final token = session.getIdToken().getJwtToken();
      if (token != null) {
        await prefs.setString('cognito_id_token', token);
      }
      
      return token;
    } catch (e) {
      print('Error getting ID token: $e');
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
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Get user error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get user exception: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>?> updateUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Update user error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Update user exception: $e');
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
        print('Get items error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get items exception: $e');
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
        print('Get item error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get item exception: $e');
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
        print('Create item error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Create item exception: $e');
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
        print('Update item error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Update item exception: $e');
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
        print('Delete item error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Delete item exception: $e');
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
        print('Get cart error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get cart exception: $e');
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
        print('Add to cart error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Add to cart exception: $e');
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
        print(
            'Remove from cart error: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Remove from cart exception: $e');
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
        print('Checkout error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Checkout exception: $e');
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
        print('Get purchases error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('Get purchases exception: $e');
      return [];
    }
  }
}
