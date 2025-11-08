import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sales_data.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetch menu ingredients from API
Future<List<Map<String, dynamic>>> fetchMenuIngredients(
  String apiBase,
  int menuId,
) async {
  try {
    final res = await http.get(
      Uri.parse("$apiBase/menu/get_menu_ingredients.php?menu_id=$menuId"),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data']);
    }
    return [];
  } catch (e) {
    print("Error fetching ingredients: $e");
    return [];
  }
}

Future<Map<String, dynamic>> deductMainIngredients(
  String apiBase,
  List<Map<String, dynamic>> deductions,
) async {
  if (deductions.isEmpty) {
    return {'success': false, 'message': 'No main ingredients to deduct'};
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      return {'success': false, 'message': 'User ID not found'};
    }

    final res = await http.post(
      Uri.parse("$apiBase/inventory/deduct_main_ingredients.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'items': deductions,
        'user_id': userId,
        'reason': 'Checkout deduction (main ingredients)',
      }),
    );

    return jsonDecode(res.body);
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final List rawMaterials;
  final String apiBase;
  final VoidCallback onClose;

  const CartPage({
    required this.cartItems,
    required this.rawMaterials,
    required this.apiBase,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String? selectedPaymentMethod;

  double get subtotal => widget.cartItems.fold(
    0,
    (sum, item) => sum + (item['price'] * (item['quantity'] ?? 1)),
  );

  void _increaseQty(int index) {
    setState(() => widget.cartItems[index]['quantity']++);
  }

  void _decreaseQty(int index) {
    setState(() {
      if (widget.cartItems[index]['quantity'] > 1) {
        widget.cartItems[index]['quantity']--;
      }
    });
  }

  void _removeItem(int index) {
    setState(() => widget.cartItems.removeAt(index));
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _checkout() async {
    if (widget.cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Your cart is empty.")));
      return;
    }

    if (selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a payment method.")),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      // ✅ Fetch user ID from either 'user_id' or fallback to 'id'
      final userId = prefs.getString('user_id') ?? prefs.getString('id');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Checkout failed: User ID missing")),
        );
        return;
      }

      // 1️⃣ Prepare main ingredient deductions
      List<Map<String, dynamic>> mainIngredientDeductions = [];

      for (var item in widget.cartItems) {
        final menuQty = parseInt(item['quantity']);
        final menuId = parseInt(item['menu_id']);
        if (menuId <= 0) continue;

        final ingredients = await fetchMenuIngredients(widget.apiBase, menuId);

        for (var ing in ingredients) {
          final inventoryId = parseInt(ing['inventory_id']);
          if (inventoryId <= 0) continue;

          final amt = parseDouble(ing['quantity']);
          if (amt <= 0) continue;

          final existingIndex = mainIngredientDeductions.indexWhere(
            (e) => e['id'] == inventoryId,
          );
          if (existingIndex >= 0) {
            mainIngredientDeductions[existingIndex]['amount'] += amt * menuQty;
          } else {
            mainIngredientDeductions.add({
              'id': inventoryId,
              'amount': amt * menuQty,
            });
          }
        }
      }

      if (mainIngredientDeductions.isNotEmpty) {
        final mainRes = await deductMainIngredients(
          widget.apiBase,
          mainIngredientDeductions,
        );

        if (mainRes['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Main ingredient deduction failed: ${mainRes['message']}",
              ),
            ),
          );
          return;
        }
      }

      // 2️⃣ Prepare add-on deductions
      List<String> addonNames = [];
      List<double> addonAmounts = [];

      for (var item in widget.cartItems) {
        final menuQty = parseInt(item['quantity']);
        final deductions = item['deduction'] ?? {};
        if (deductions is Map) {
          for (var entry in deductions.entries) {
            final name = entry.key.toString();
            final amt = parseDouble(entry.value);
            if (amt <= 0) continue;

            addonNames.add(name);
            addonAmounts.add(amt * menuQty);
          }
        }
      }

      if (addonNames.isNotEmpty) {
        final res = await http.post(
          Uri.parse("${widget.apiBase}/inventory/deduct_inventory.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": addonNames,
            "amount": addonAmounts,
            "user_id": userId,
            "reason": "Checkout deduction (add-ons)",
          }),
        );

        final data = jsonDecode(res.body);
        if (data['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Add-on deduction failed: ${data['message']}"),
            ),
          );
          return;
        }
      }

      // 3️⃣ Record order with payment method
      await SalesData().addOrder(
        List<Map<String, dynamic>>.from(widget.cartItems),
        paymentMethod: selectedPaymentMethod!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Order completed via $selectedPaymentMethod! Inventory updated.",
          ),
        ),
      );

      // Clear cart and reset
      setState(() {
        widget.cartItems.clear();
        selectedPaymentMethod = null;
      });

      widget.onClose();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error during checkout: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.orange),
                  onPressed: widget.onClose,
                ),
                Text(
                  "Your Cart",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Cart Items
            Expanded(
              child: widget.cartItems.isEmpty
                  ? Center(
                      child: Text(
                        "Your cart is empty.",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(children: _buildCartGroupedByCategory()),
                    ),
            ),

            // Checkout Section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Payment Method
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Select Payment Method:",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _paymentBox("Cash", Icons.money),
                      _paymentBox("Card", Icons.credit_card),
                      _paymentBox("GCash", Icons.phone_android),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subtotal:",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        "₱${subtotal.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _checkout,
                      child: Text(
                        "Checkout",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentBox(String method, IconData icon) {
    bool isSelected = selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = method),
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.grey.shade700,
            ),
            const SizedBox(height: 6),
            Text(
              method,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.orange : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCartGroupedByCategory() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in widget.cartItems) {
      final category = item['category'] ?? 'Others';
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(item);
    }

    List<Widget> widgets = [];

    grouped.forEach((category, items) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
      );

      for (var item in items) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['category'] ?? 'Others',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['name'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item['size'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          "Size: ${item['size']}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    if (item['addons'] != null &&
                        (item['addons'] as List).isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Addons:",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...((item['addons'] as List).map(
                            (addon) => Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                bottom: 2,
                              ),
                              child: Text(
                                "- $addon",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _quantityButton(
                              Icons.remove,
                              () =>
                                  _decreaseQty(widget.cartItems.indexOf(item)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                "${item['quantity']}",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _quantityButton(
                              Icons.add,
                              () =>
                                  _increaseQty(widget.cartItems.indexOf(item)),
                            ),
                          ],
                        ),
                        Text(
                          "₱${(item['price'] * item['quantity']).toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFCDD2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                _removeItem(widget.cartItems.indexOf(item)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    });

    return widgets;
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFE0B2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.deepOrange),
        onPressed: onPressed,
      ),
    );
  }
}