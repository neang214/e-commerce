import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // ── Base URLs ──────────────────────────────────────────────────────────────
  // Change IP to your PC's local IP (ifconfig / ipconfig)
  static const String imageBaseUrl = 'http://192.168.1.7:5000';       // for images: http://IP:5000/uploads/abc.jpg
  static const String baseUrl      = 'http://192.168.1.7:5000/api';   // for API:    http://IP:5000/api/products

  // ── Token ──────────────────────────────────────────────────────────────────
  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('token');
  }

  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token);
  }

  static Future<void> clearToken() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await getToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  // ── Response handlers ──────────────────────────────────────────────────────
  // FIX: Guard against non-JSON (HTML) responses — show a clear error instead of a JSON parse crash
  static dynamic _tryDecode(http.Response res) {
    final ct = res.headers['content-type'] ?? '';
    if (!ct.contains('application/json')) {
      throw Exception(
        'Server error (${res.statusCode}): unexpected response format. '
        'Check the backend is running and the API URL is correct.');
    }
    try {
      return jsonDecode(res.body);
    } catch (_) {
      throw Exception('Invalid response from server (${res.statusCode})');
    }
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final body = _tryDecode(res);
    if (res.statusCode >= 400) {
      throw Exception(body['msg'] ?? 'Request failed (${res.statusCode})');
    }
    return body is Map<String, dynamic> ? body : {'data': body};
  }

  static List<dynamic> _decodeList(http.Response res) {
    if (res.statusCode >= 400) {
      final body = _tryDecode(res);
      throw Exception(body['msg'] ?? 'Request failed (${res.statusCode})');
    }
    return _tryDecode(res) as List;
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return _decode(res);
  }

  static Future<User> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(auth: true),
    );
    return User.fromJson(_decode(res));
  }

  // ── Products ───────────────────────────────────────────────────────────────
  static Future<List<Product>> getProducts() async {
    final res = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: await _headers(),
    );
    return _decodeList(res).map((j) => Product.fromJson(j)).toList();
  }

  static Future<Product> getProduct(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _headers(),
    );
    return Product.fromJson(_decode(res));
  }

  static Future<List<Product>> searchProducts(String keyword,
      {String? categoryId}) async {
    final params = {
      'keyword': keyword,
      if (categoryId != null) 'category': categoryId,
    };
    final uri = Uri.parse('$baseUrl/products/search')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    return _decodeList(res).map((j) => Product.fromJson(j)).toList();
  }

  // ── Categories ─────────────────────────────────────────────────────────────
  static Future<List<Category>> getCategories() async {
    final res = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers(),
    );
    return _decodeList(res).map((j) => Category.fromJson(j)).toList();
  }

  // ── Cart ───────────────────────────────────────────────────────────────────
  static Future<List<CartItem>> getCart() async {
    final res = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: await _headers(auth: true),
    );
    return _decodeList(res).map((j) => CartItem.fromJson(j)).toList();
  }

  static Future<void> addToCart(String productId, int quantity) async {
    final res = await http.post(
      Uri.parse('$baseUrl/cart/add'),
      headers: await _headers(auth: true),
      body: jsonEncode({'product': productId, 'quantity': quantity}),
    );
    _decode(res);
  }

  static Future<void> updateCartItem(String itemId, int quantity) async {
    final res = await http.put(
      Uri.parse('$baseUrl/cart/$itemId'),
      headers: await _headers(auth: true),
      body: jsonEncode({'quantity': quantity}),
    );
    _decode(res);
  }

  static Future<void> removeCartItem(String itemId) async {
    await http.delete(
      Uri.parse('$baseUrl/cart/$itemId'),
      headers: await _headers(auth: true),
    );
  }

  // ── Addresses ──────────────────────────────────────────────────────────────
  static Future<List<Address>> getAddresses() async {
    final res = await http.get(
      Uri.parse('$baseUrl/address'),
      headers: await _headers(auth: true),
    );
    return _decodeList(res).map((j) => Address.fromJson(j)).toList();
  }

  static Future<Address> createAddress(
      String phone, String addressLine, String city) async {
    final res = await http.post(
      Uri.parse('$baseUrl/address'),
      headers: await _headers(auth: true),
      body: jsonEncode(
          {'phone': phone, 'addressLine': addressLine, 'city': city}),
    );
    return Address.fromJson(_decode(res));
  }

  // ── Orders ─────────────────────────────────────────────────────────────────
  static Future<Order> createOrder(String addressId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(auth: true),
      body: jsonEncode({'address': addressId}),
    );
    return Order.fromJson(_decode(res));
  }

  static Future<List<Order>> getMyOrders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/my'),
      headers: await _headers(auth: true),
    );
    return _decodeList(res).map((j) => Order.fromJson(j)).toList();
  }

  static Future<Order> getOrder(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders/$id'),
      headers: await _headers(auth: true),
    );
    return Order.fromJson(_decode(res));
  }

  // ── Payments ───────────────────────────────────────────────────────────────
  static Future<void> pay(String orderId, String method) async {
    final res = await http.post(
      Uri.parse('$baseUrl/payments'),
      headers: await _headers(auth: true),
      body: jsonEncode({'order': orderId, 'method': method}),
    );
    _decode(res);
  }

  // ── Image upload ───────────────────────────────────────────────────────────
  static Future<String> uploadImage(String filePath) async {
    // 1. Ensure the URL is singular 'upload' to match your server.js
    final uri = Uri.parse('$baseUrl/upload');

    final request = http.MultipartRequest('POST', uri);

    // 2. Add Authorization header
    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Add the file with the key 'image'
    request.files.add(
      await http.MultipartFile.fromPath('image', filePath),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // 4. YOUR SERVER RETURNS 'path', NOT 'url' or 'image'
      // This is where your previous error likely was!
      return body['path'];
    } else {
      print('Upload Error Body: ${response.body}');
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }

  // ── Admin: Dashboard stats ─────────────────────────────────────────────────
  // FIX: Try the dedicated stats endpoint first; if it fails (e.g. old server
  // without the route), fall back to computing stats from existing endpoints.
  static Future<Map<String, dynamic>> adminGetStats() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: await _headers(auth: true),
      );
      return _decode(res);
    } catch (_) {
      // Fallback: compute stats from the data we can already fetch
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/orders'),   headers: await _headers(auth: true)),
        http.get(Uri.parse('$baseUrl/products'),  headers: await _headers(auth: true)),
        http.get(Uri.parse('$baseUrl/admin/users'), headers: await _headers(auth: true)),
      ]);

      final orders   = _decodeList(results[0]);
      final products = _decodeList(results[1]);
      List<dynamic> users = [];
      try { users = _decodeList(results[2]); } catch (_) {}

      final revenue = orders
          .where((o) => ['paid', 'shipped', 'completed'].contains(o['status']))
          .fold<double>(0, (sum, o) => sum + ((o['totalPrice'] ?? 0) as num).toDouble());

      return {
        'totalOrders':   orders.length,
        'totalProducts': products.length,
        'totalUsers':    users.length,
        'totalRevenue':  revenue,
      };
    }
  }

  // ── Admin: Products ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> adminCreateProduct(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> adminUpdateProduct(
      String id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<void> adminDeleteProduct(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _headers(auth: true),
    );
    _decode(res);
  }

  // ── Admin: Categories ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> adminCreateCategory(String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers(auth: true),
      body: jsonEncode({'name': name}),
    );
    return _decode(res);
  }

  static Future<void> adminDeleteCategory(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _headers(auth: true),
    );
    _decode(res);
  }

  // ── Admin: Orders ──────────────────────────────────────────────────────────
  static Future<List<Order>> adminGetAllOrders() async {
    final res = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(auth: true),
    );
    return _decodeList(res).map((j) => Order.fromJson(j)).toList();
  }

  static Future<Order> adminUpdateOrderStatus(String id, String status) async {
    final res = await http.put(
      Uri.parse('$baseUrl/orders/$id'),
      headers: await _headers(auth: true),
      body: jsonEncode({'status': status}),
    );
    return Order.fromJson(_decode(res));
  }

  // ── Admin: Users ───────────────────────────────────────────────────────────
  static Future<List<User>> adminGetAllUsers() async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: await _headers(auth: true),
    );
    return _decodeList(res).map((j) => User.fromJson(j)).toList();
  }
}