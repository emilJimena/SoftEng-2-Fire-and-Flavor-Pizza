import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';

class SalesData {
  static final SalesData _instance = SalesData._internal();
  factory SalesData() => _instance;
  SalesData._internal();

  final List<Map<String, dynamic>> orders = [];
  late String saveApiUrl;
  late String fetchApiUrl;

  /// Initialize SalesData: load saved orders and set API URLs
  Future<void> init() async {
    await _loadSavedSales();
    await _setApiUrls();
  }

  /// Determine API URLs based on platform
  Future<void> _setApiUrls() async {
    // ✅ Replace everything inside this method with:
    final base = await ApiConfig.getBaseUrl();
    saveApiUrl = "$base/salesdata/save_order.php";
    fetchApiUrl = "$base/salesdata/get_orders.php";

    print("✅ API URLs set: save=$saveApiUrl, fetch=$fetchApiUrl");
  }

  Future<void> addOrder(
    List<Map<String, dynamic>> cartItems, {
    required String paymentMethod,
  }) async {
    if (cartItems.isEmpty) return;
    if (saveApiUrl.isEmpty) await _setApiUrls();

    final now = DateTime.now();
final todayStr = '${_monthName(now.month)} ${now.day}, ${now.year}';

// Count existing orders for today
final todayOrdersCount = orders.where((o) => o['orderDate'] == todayStr).length;

final newOrder = {
  'orderName': 'Order ${todayOrdersCount + 1}',
  'orderDate': todayStr,
  'orderTime':
      '${now.hour > 12 ? now.hour - 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? "PM" : "AM"}',
  'paymentMethod': paymentMethod,
  'items': cartItems.map((item) {
    final price = (item['price'] ?? 0) * (item['quantity'] ?? 1);
    return {
      'menuItem': item['name'] ?? '',
      'category': item['category'] ?? '',
      'quantity': item['quantity'].toString(),
      'size': item['size'] ?? '',
      'price': price.toStringAsFixed(2),
      'addons': List<String>.from(item['addons'] ?? []),
    };
  }).toList(),
};


    orders.add(newOrder);
    await _saveSales();

    try {
      final response = await http.post(
        Uri.parse(saveApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newOrder),
      );

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == 'success') {
          print("✅ Order saved to database successfully!");
        } else {
          print("❌ PHP Error: ${res['message']}");
        }
      } else {
        print("❌ HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error sending order: $e");
    }
  }

  /// Fetch orders from PHP and overwrite local orders
  Future<void> loadOrders() async {
    if (fetchApiUrl.isEmpty) await _setApiUrls();

    try {
      final response = await http.get(Uri.parse(fetchApiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          orders.clear();
          orders.addAll(List<Map<String, dynamic>>.from(data['orders']));
          await _saveSales(); // update local storage
          print("✅ Orders loaded successfully from server.");
        } else {
          print("⚠️ ${data['message']}");
        }
      } else {
        print("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error fetching orders: $e");
    }
  }

  /// Save orders locally
  Future<void> _saveSales() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sales_orders', jsonEncode(orders));
  }

  /// Load orders from local storage
  Future<void> _loadSavedSales() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('sales_orders');
    if (savedData != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(savedData);
        orders.clear();
        orders.addAll(jsonList.cast<Map<String, dynamic>>());
      } catch (e) {
        print("⚠️ Failed to load saved sales: $e");
      }
    }
  }

  /// Calculate total price of an order
  double calculateOrderTotal(Map<String, dynamic> order) {
    double total = 0;
    for (var item in order['items']) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      total += price;
    }
    return total;
  }

  /// Helper to convert month number to name
  static String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
