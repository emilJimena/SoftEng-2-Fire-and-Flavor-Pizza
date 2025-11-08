import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

String? apiBase;

class BasketItem {
  Map<String, dynamic> menuItem;
  int quantity;

  BasketItem({required this.menuItem, required this.quantity});
}

class CustomerMenuPage extends StatefulWidget {
  final String? username; // could be user's email or display name
  final String? role;
  final String? userId;

  const CustomerMenuPage({Key? key, this.username, this.role, this.userId})
    : super(key: key);

  @override
  State<CustomerMenuPage> createState() => _CustomerMenuPageState();
}

class _CustomerMenuPageState extends State<CustomerMenuPage> {
  int currentTab = 0;

  List<Map<String, dynamic>> menuItems = [];
  List<Map<String, dynamic>> rawMaterials = [];
  List<BasketItem> basket = [];
  List<Map<String, dynamic>> customerOrders = [];

  bool isLoading = true;
  bool isLoadingOrders = false;

  // Persistent quantities per menu item
  Map<int, int> menuItemQuantities = {};

  @override
  void initState() {
    super.initState();
    fetchData();
    _initApiBase();
  }

  Future<void> _initApiBase() async {
    apiBase = await ApiConfig.getBaseUrl(); // 👈 loads your dynamic URL
    await fetchData();
  }

  // === FETCH MENU AND MATERIALS ===
  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final menuResp = await http.get(
        Uri.parse("$apiBase/menu/get_menu_items.php"),
      );
      final materialsResp = await http.get(
        Uri.parse("$apiBase/raw_materials/get_materials.php"),
      );

      final menuData = jsonDecode(menuResp.body);
      final materialsData = jsonDecode(materialsResp.body);

      if (menuData['success'] && materialsData['success']) {
        setState(() {
          menuItems = List<Map<String, dynamic>>.from(menuData['data']);
          rawMaterials = List<Map<String, dynamic>>.from(
            materialsData['materials'],
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // === FETCH CUSTOMER ORDERS ===
  Future<void> fetchCustomerOrders() async {
    setState(() => isLoadingOrders = true);
    try {
      final userId = widget.userId ?? "0";
      final response = await http.get(
        Uri.parse("$apiBase/order/get_orders.php?user_id=$userId"),
      );
      final data = jsonDecode(response.body);

      if (data['success']) {
        final orders = List<Map<String, dynamic>>.from(data['orders']);
        setState(() {
          customerOrders = orders;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch orders: ${data['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to fetch orders: $e")));
    } finally {
      setState(() => isLoadingOrders = false);
    }
  }

  // === BASKET LOGIC ===
  void addToBasket(Map<String, dynamic> menuItem, int quantity) {
    if (!canOrderMenuItem(menuItem, quantity)) return;

    final id = menuItem['id'];
    if (id == null) return; // safety check

    final existing = basket.indexWhere((b) => b.menuItem['id'] == id);

    setState(() {
      if (existing != -1) {
        basket[existing].quantity += quantity;
      } else {
        basket.add(BasketItem(menuItem: menuItem, quantity: quantity));
      }

      // Reset quantity for next add
      menuItemQuantities[id] = 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${menuItem['name']} added to basket")),
    );
  }

  void changeQuantity(BasketItem item, int delta) {
    setState(() {
      item.quantity += delta;
      if (item.quantity <= 0) {
        basket.remove(item);
      } else {
        // sync quantity back to menuItemQuantities
        final id = item.menuItem['id'];
        if (id != null) menuItemQuantities[id] = item.quantity;
      }
    });
  }

  bool canOrderMenuItem(Map<String, dynamic> menuItem, int quantity) {
    if (menuItem['ingredients'] == null) return true;

    List<String> insufficient = [];

    for (var ing in menuItem['ingredients']) {
      final materialId = ing['material_id'];
      final requiredQty = (ing['quantity'] ?? 0) * quantity;

      final material = rawMaterials.firstWhere(
        (m) => m['id'] == materialId,
        orElse: () => {},
      );

      final availableQty = material['stock'] ?? 0;

      if (availableQty < requiredQty) {
        insufficient.add(
          "${material['name'] ?? 'Unknown'} (needed: $requiredQty, available: $availableQty)",
        );
      }
    }

    if (insufficient.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Cannot order ${menuItem['name']}. Insufficient stock for:\n${insufficient.join('\n')}",
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

  // === PLACE ORDER ===
  Future<void> placeBasketOrder() async {
    if (basket.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Basket is empty!")));
      return;
    }

    try {
      final total = basket.fold<double>(
        0,
        (sum, b) =>
            sum +
            (double.tryParse(b.menuItem['price'].toString()) ?? 0) * b.quantity,
      );

      final payload = {
        "user_id": int.tryParse(widget.userId ?? "0") ?? 0,
        "items": basket
            .map(
              (b) => {
                "id": b.menuItem['id'],
                "name": b.menuItem['name'],
                "price": double.tryParse(b.menuItem['price'].toString()) ?? 0.0,
                "quantity": b.quantity,
              },
            )
            .toList(),
        "total_amount": total,
        "status": "pending",
        "availability": "available",
        "payment_method": "Cash",
        "payment_status": "unpaid",
      };

      final response = await http.post(
        Uri.parse("$apiBase/order/create_order.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully!")),
        );
        setState(() => basket.clear());
        await fetchData();
        await fetchCustomerOrders();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${data['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error placing order: $e")));
    }
  }

  void showBasket() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (_) => BasketSheet(
        basket: basket,
        changeQuantity: changeQuantity,
        placeBasketOrder: placeBasketOrder,
      ),
    );
  }

  // === UI ===
  @override
  Widget build(BuildContext context) {
    final tabs = [buildMenuView(), buildOrdersView()];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Welcome, ${widget.username ?? "Customer"}"),
        backgroundColor: Colors.orange,
        actions: [
          if (currentTab == 0)
            IconButton(
              icon: const Icon(Icons.shopping_basket),
              onPressed: showBasket,
            ),
          if (currentTab == 1)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: fetchCustomerOrders,
            ),
        ],
      ),
      body: tabs[currentTab],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white54,
        currentIndex: currentTab,
        onTap: (index) {
          setState(() => currentTab = index);
          if (index == 1) fetchCustomerOrders();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Menu"),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: "My Orders",
          ),
        ],
      ),
    );
  }

  // === MENU TAB ===
  Widget buildMenuView() {
    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final id = item['id'];
              if (id == null) return const SizedBox();

              int quantity = menuItemQuantities[id] ?? 1;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    item['name'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle:
                      item['ingredients'] != null &&
                          item['ingredients'].isNotEmpty
                      ? Text(
                          "Ingredients: " +
                              (item['ingredients'] as List)
                                  .map(
                                    (ing) =>
                                        "${ing['name']} (${ing['quantity']} ${ing['unit']})",
                                  )
                                  .join(", "),
                          style: const TextStyle(color: Colors.white70),
                        )
                      : const Text(
                          "No ingredients",
                          style: TextStyle(color: Colors.white54),
                        ),
                  trailing: SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () {
                            if (quantity > 1) {
                              setState(() {
                                quantity--;
                                menuItemQuantities[id] = quantity;
                              });
                            }
                          },
                        ),
                        Text(
                          "$quantity",
                          style: const TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.green),
                          onPressed: () {
                            setState(() {
                              quantity++;
                              menuItemQuantities[id] = quantity;
                            });
                          },
                        ),
                        ElevatedButton(
                          onPressed: () => addToBasket(item, quantity),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 30),
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text(
                            "Add",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  // === ORDERS TAB ===
  Widget buildOrdersView() {
    if (isLoadingOrders) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (customerOrders.isEmpty) {
      return const Center(
        child: Text("No orders yet.", style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customerOrders.length,
      itemBuilder: (context, index) {
        final order = customerOrders[index];
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              "Order #${order['id']}",
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Customer: ${order['user_email'] ?? 'Unknown'}",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "Status: ${order['status']}",
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  "Date: ${order['created_at']}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                ...(((order['order_items'] ?? []) as List)
                    .map(
                      (it) => Text(
                        "- ${it['name']} x${it['quantity']} @ ₱${it['price']}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                    .toList()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BasketSheet extends StatelessWidget {
  final List<BasketItem> basket;
  final Function(BasketItem, int) changeQuantity;
  final Future<void> Function() placeBasketOrder;

  const BasketSheet({
    super.key,
    required this.basket,
    required this.changeQuantity,
    required this.placeBasketOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(16),
      height: 400,
      child: Column(
        children: [
          const Text(
            "Basket",
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: basket.isEmpty
                ? const Center(
                    child: Text(
                      "Basket is empty",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : StatefulBuilder(
                    builder: (context, setStateSB) {
                      return ListView.builder(
                        itemCount: basket.length,
                        itemBuilder: (context, index) {
                          final item = basket[index];
                          return ListTile(
                            title: Text(
                              item.menuItem['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    changeQuantity(item, -1);
                                    setStateSB(() {});
                                  },
                                ),
                                Text(
                                  "${item.quantity}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    changeQuantity(item, 1);
                                    setStateSB(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          ElevatedButton(
            onPressed: placeBasketOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Place Order"),
          ),
        ],
      ),
    );
  }
}
