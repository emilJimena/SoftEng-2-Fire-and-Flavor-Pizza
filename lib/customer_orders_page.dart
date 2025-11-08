import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

String? apiBase;

class CustomerOrdersPage extends StatefulWidget {
  final String userId;

  const CustomerOrdersPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchOrders();
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    apiBase = await ApiConfig.getBaseUrl(); // 👈 loads your dynamic URL
    await fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse("$apiBase/order/get_orders.php"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            orders = List<Map<String, dynamic>>.from(data['orders']);
          });
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("HTTP Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch orders: $e")));
    }

    setState(() => isLoading = false);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    List<Map<String, dynamic>> items = [];

    if (order['order_items'] != null) {
      final raw = order['order_items'];
      if (raw is String) {
        items = List<Map<String, dynamic>>.from(jsonDecode(raw));
      } else if (raw is List) {
        items = List<Map<String, dynamic>>.from(raw);
      }
    }

    final totalAmount = order['total_amount'] ?? '0.00';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        title: Text(
          "Order #${order['id']}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: ${order['user_email'] ?? 'Unknown'}"),
            Text(
              "Status: ${order['status']}",
              style: TextStyle(
                color: getStatusColor(order['status']),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text("Availability: ${order['availability']}"),
            Text(
              "Payment: ${order['payment_method']} (${order['payment_status']})",
            ),
            Text("Total: ₱$totalAmount"),
            Text("Date: ${order['created_at']}"),
          ],
        ),

        children: [
          ...items.map(
            (item) => ListTile(
              title: Text(item['name'] ?? 'Unknown Item'),
              subtitle: Text("Qty: ${item['quantity']}"),
              trailing: Text("₱${item['price']}"),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: const Text("Proceed to Payment"),
                  onPressed: () {
                    if (order['payment_status'] == 'paid') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("This order is already paid."),
                        ),
                      );
                    } else {
                      _showPaymentOptions(order['id']);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.update),
                  label: const Text("Update Status"),
                  onPressed: () => _showStatusOptions(order['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions(int orderId) async {
    final paymentMethod = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Select Payment Method"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Cash"),
            child: const Text("Cash"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Card"),
            child: const Text("Card"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "E-Wallet"),
            child: const Text("E-Wallet"),
          ),
        ],
      ),
    );

    if (paymentMethod != null) {
      await _updatePaymentStatus(orderId, paymentMethod);
    }
  }

  Future<void> _updatePaymentStatus(int orderId, String method) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/order/update_payment_status.php"),
        body: {
          'order_id': orderId.toString(),
          'payment_method': method,
          'payment_status': 'paid',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment successful via $method")),
        );
        fetchOrders();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Payment update failed: $e")));
    }
  }

  void _showStatusOptions(int orderId) async {
    final status = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text("Update Order Status"),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "pending"),
            child: const Text("Pending"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "processing"),
            child: const Text("Processing"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "completed"),
            child: const Text("Completed"),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "cancelled"),
            child: const Text("Cancelled"),
          ),
        ],
      ),
    );

    if (status != null) {
      await _updateOrderStatus(orderId, status);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/order/update_order_status.php"),
        body: {'order_id': orderId.toString(), 'status': status},
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Order status updated to $status")),
        );
        fetchOrders();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${data['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update order: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Ordering Management"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchOrders),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? const Center(child: Text("No orders found"))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return buildOrderCard(orders[index]);
              },
            ),
    );
  }
}
