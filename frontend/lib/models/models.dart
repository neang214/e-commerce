// ─── User ────────────────────────────────────────────────────────────────────
class User {
  final String id;
  final String name;
  final String email;
  final String role;

  User({required this.id, required this.name, required this.email, required this.role});

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['_id'] ?? '',
    name: j['name'] ?? '',
    email: j['email'] ?? '',
    role: j['role'] ?? 'user',
  );
}

// ─── Category ────────────────────────────────────────────────────────────────
class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['_id'] ?? '',
    name: j['name'] ?? '',
  );
}

// ─── Product ─────────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String? image;
  final int stock;
  final Category? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.image,
    required this.stock,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['_id'] ?? '',
    name: j['name'] ?? '',
    price: (j['price'] ?? 0).toDouble(),
    description: j['description'] ?? '',
    image: j['image'],
    stock: j['stock'] ?? 0,
    category: j['category'] is Map
        ? Category.fromJson(j['category'])
        : null,
  );
}

// ─── CartItem ─────────────────────────────────────────────────────────────────
class CartItem {
  final String id;
  final Product product;
  int quantity;

  CartItem({required this.id, required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    id: j['_id'] ?? '',
    product: Product.fromJson(j['product']),
    quantity: j['quantity'] ?? 1,
  );
}

// ─── Address ──────────────────────────────────────────────────────────────────
class Address {
  final String id;
  final String phone;
  final String addressLine;
  final String city;

  Address({
    required this.id,
    required this.phone,
    required this.addressLine,
    required this.city,
  });

  String get display => '$addressLine, $city';

  factory Address.fromJson(Map<String, dynamic> j) => Address(
    id: j['_id'] ?? '',
    phone: j['phone'] ?? '',
    addressLine: j['addressLine'] ?? '',
    city: j['city'] ?? '',
  );
}

// ─── Order ───────────────────────────────────────────────────────────────────
class Order {
  final String id;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final Address? address;

  Order({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.address,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['_id'] ?? '',
    totalPrice: (j['totalPrice'] ?? 0).toDouble(),
    status: j['status'] ?? 'pending',
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    address: j['address'] is Map ? Address.fromJson(j['address']) : null,
  );
}
