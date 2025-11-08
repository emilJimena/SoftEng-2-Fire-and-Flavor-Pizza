import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/api_config.dart';

class Addons {
  final Map<String, double> sizes;
  final Map<String, double> crusts;
  final Map<String, double> dips;
  final Map<String, double> stuffed;
  final Map<String, double> pizzaAddons;
  final Map<String, Map<String, double>> pastaAddons;
  final Map<String, Map<String, double>> riceAddons;

  Addons({
    required this.sizes,
    required this.crusts,
    required this.dips,
    required this.stuffed,
    required this.pizzaAddons,
    required this.pastaAddons,
    required this.riceAddons,
  });

  factory Addons.fromJson(Map<String, dynamic> json) {
    Map<String, double> toMap(dynamic input) {
      if (input is Map) {
        return input.map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        );
      }
      return {};
    }

    Map<String, Map<String, double>> toNestedMap(dynamic input) {
      if (input is Map) {
        return input.map((k, v) => MapEntry(k.toString(), toMap(v)));
      }
      return {};
    }

    return Addons(
      sizes: toMap(json['sizes']),
      crusts: toMap(json['crusts']),
      dips: toMap(json['dips']),
      stuffed: toMap(json['stuffed']),
      pizzaAddons: toMap(json['pizzaAddons']),
      pastaAddons: toNestedMap(json['pastaAddons']),
      riceAddons: toNestedMap(json['riceAddons']),
    );
  }
}

// --- Fetch addons from PHP API ---
Future<Addons> fetchAddons() async {
  final apiBase = await ApiConfig.getBaseUrl(); // ✅ use shared base
  final url = '$apiBase/addons/get_addons.php';

  try {
    print("Fetching addons from $url");
    final res = await http.get(Uri.parse(url));

    print("Status code: ${res.statusCode}");
    print(
      "Body: ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}",
    );

    if (res.statusCode == 200) {
      // Handle invalid JSON (like HTML error pages)
      if (res.body.trim().startsWith('<')) {
        throw Exception(
          "Server returned HTML instead of JSON (check your PHP file path or server error)",
        );
      }

      final data = jsonDecode(res.body);
      return Addons.fromJson(data);
    } else {
      throw Exception('Failed to load addons: ${res.statusCode}');
    }
  } catch (e) {
    print("Error fetching addons: $e");
    rethrow;
  }
}

// --- Main popup function ---
void showOrderPopup(
  BuildContext context,
  Map<String, dynamic> item,
  void Function(Map<String, dynamic>) onAddToCart,
) async {
  late Addons addons;
  try {
    addons = await fetchAddons();
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Failed to load addons: $e')));
    return;
  }

  double basePrice = 0.0;
  if (item.containsKey('price')) {
    final val = item['price'];
    if (val is num)
      basePrice = val.toDouble();
    else if (val is String)
      basePrice = double.tryParse(val) ?? 0.0;
  }

  String selectedSize = "Medium";
  String selectedCrustType = "Thin";
  String selectedDip = "Garlic";
  String selectedStuffed = "None";

  List<String> pizzaAddonsSelected = [];
  List<String> pastaAddonsSelected = [];
  List<String> riceAddonsSelected = [];

  final String type =
      (item['type'] ?? item['category']?.toString().toLowerCase() ?? 'pizza')
          .toString()
          .toLowerCase();

  final Map<String, double> sizeMultiplier = addons.sizes;
  final Map<String, double> crustPrices = addons.crusts;
  final Map<String, double> dipPrices = addons.dips;
  final Map<String, double> stuffedPrices = addons.stuffed;
  final Map<String, double> pizzaAddonPrices = addons.pizzaAddons;
  final Map<String, Map<String, double>> pastaAddons = addons.pastaAddons;
  final Map<String, Map<String, double>> riceAddons = addons.riceAddons;

  Map<String, Map<String, double>> getCurrentAddons() {
    if (type == 'pasta') return pastaAddons;
    if (type == 'rice') return riceAddons;
    return {};
  }

  double computeTotal() {
    double total = basePrice;
    if (type == 'pizza') {
      total *= sizeMultiplier[selectedSize] ?? 1.0;
      total += crustPrices[selectedCrustType] ?? 0.0;
      total += dipPrices[selectedDip] ?? 0.0;
      total += stuffedPrices[selectedStuffed] ?? 0.0;
      for (var addon in pizzaAddonsSelected) {
        total += pizzaAddonPrices[addon] ?? 0.0;
      }
    } else if (type == 'pasta' || type == 'rice') {
      final addonsMap = getCurrentAddons();
      final selected = type == 'pasta'
          ? pastaAddonsSelected
          : riceAddonsSelected;
      for (var category in addonsMap.values) {
        for (var addon in selected) {
          if (category.containsKey(addon)) total += category[addon]!;
        }
      }
    }
    return total;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final totalPrice = computeTotal();

          return AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Customize ${item['name'] ?? 'Meal'}",
              style: GoogleFonts.poppins(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Base Price: ₱${basePrice.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // PIZZA OPTIONS
                  if (type == 'pizza') ...[
                    Text(
                      "Sizes",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    Column(
                      children: sizeMultiplier.keys.map((size) {
                        final priceForSize =
                            basePrice * (sizeMultiplier[size] ?? 1.0);
                        return RadioListTile<String>(
                          value: size,
                          groupValue: selectedSize,
                          onChanged: (value) =>
                              setState(() => selectedSize = value!),
                          title: Text(
                            "$size (₱${priceForSize.toStringAsFixed(2)})",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          activeColor: Colors.orangeAccent,
                          dense: true,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Addons",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    ...pizzaAddonPrices.entries.map((entry) {
                      return CheckboxListTile(
                        value: pizzaAddonsSelected.contains(entry.key),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true)
                              pizzaAddonsSelected.add(entry.key);
                            else
                              pizzaAddonsSelected.remove(entry.key);
                          });
                        },
                        title: Text(
                          "${entry.key} (+₱${entry.value.toStringAsFixed(2)})",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        activeColor: Colors.orangeAccent,
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      );
                    }).toList(),
                    const SizedBox(height: 10),
                    _buildRadioSection(
                      "Crust Type",
                      crustPrices,
                      selectedCrustType,
                      (val) => setState(() => selectedCrustType = val),
                    ),
                    _buildRadioSection(
                      "Side Dips",
                      dipPrices,
                      selectedDip,
                      (val) => setState(() => selectedDip = val),
                    ),
                    _buildRadioSection(
                      "Stuffed Crust Option",
                      stuffedPrices,
                      selectedStuffed,
                      (val) => setState(() => selectedStuffed = val),
                    ),
                  ],

                  // PASTA / RICE OPTIONS
                  if (type == 'pasta' || type == 'rice') ...[
                    Text(
                      "Addons",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                    ...getCurrentAddons().entries.map((category) {
                      final selected = type == 'pasta'
                          ? pastaAddonsSelected
                          : riceAddonsSelected;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.key,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ...category.value.entries.map((addon) {
                            final name = addon.key;
                            final price = addon.value;
                            return CheckboxListTile(
                              value: selected.contains(name),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true)
                                    selected.add(name);
                                  else
                                    selected.remove(name);
                                });
                              },
                              title: Text(
                                "$name (+₱${price.toStringAsFixed(2)})",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              activeColor: Colors.orangeAccent,
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ],

                  const Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total:",
                        style: GoogleFonts.poppins(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "₱${totalPrice.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  final cartItem = {
                    'menu_id': item['id'],
                    'name': item['name'],
                    'price': totalPrice,
                    'quantity': 1,
                    'category': type.isNotEmpty
                        ? type[0].toUpperCase() + type.substring(1)
                        : 'Other',
                    'size': type == 'pizza' ? selectedSize : null,
                    'addons': type == 'pizza'
                        ? pizzaAddonsSelected
                        : type == 'pasta'
                        ? pastaAddonsSelected
                        : riceAddonsSelected,
                    'deduction': computeIngredientDeduction(
                      item,
                      size: selectedSize,
                      crust: selectedCrustType,
                      stuffed: selectedStuffed,
                      addons: pizzaAddonsSelected,
                    ),
                  };
                  onAddToCart(cartItem);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Added ${item['name']} to cart.",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text(
                  "Add to Cart",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// --- Radio section helper ---
Widget _buildRadioSection(
  String title,
  Map<String, double> options,
  String groupValue,
  ValueChanged<String> onChanged,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
      ),
      Column(
        children: options.keys.map((key) {
          return RadioListTile<String>(
            value: key,
            groupValue: groupValue,
            onChanged: (value) => onChanged(value!),
            title: Text(
              "$key (+₱${options[key]!.toStringAsFixed(2)})",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            activeColor: Colors.orangeAccent,
            dense: true,
          );
        }).toList(),
      ),
      const SizedBox(height: 10),
    ],
  );
}

// --- Inventory deduction ---
Future<Map<String, dynamic>> deductInventory(
  Map<String, double> deductionMap,
) async {
  if (deductionMap.isEmpty) {
    return {'success': false, 'message': 'No ingredients to deduct'};
  }

  try {
    final apiBase =
        await ApiConfig.getBaseUrl(); // ✅ this goes here (before http.post)

    final res = await http.post(
      Uri.parse('$apiBase/inventory/deduct_inventory.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': deductionMap.keys.toList(),
        'amount': deductionMap.values.toList(),
      }),
    );

    return jsonDecode(res.body);
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

// --- Compute ingredient deduction ---
Map<String, double> computeIngredientDeduction(
  Map<String, dynamic> item, {
  String? size,
  String? crust,
  String? stuffed,
  List<String>? addons,
}) {
  final Map<String, double> deduction = {};
  final type =
      (item['type'] ?? item['category']?.toString().toLowerCase() ?? 'pizza')
          .toString()
          .toLowerCase();

  // --- PIZZA ---
  if (type == 'pizza') {
    deduction['Dough'] = 1.0;
    deduction['Cheese'] = 50.0;
    deduction['Tomato Sauce'] = 30.0;

    if (size != null) {
      double multiplier = 1.0;
      switch (size) {
        case 'Small':
          multiplier = 0.9;
          break;
        case 'Medium':
          multiplier = 1.0;
          break;
        case 'Large':
          multiplier = 1.3;
          break;
        case 'Extra Large':
          multiplier = 1.6;
          break;
      }
      deduction.update('Dough', (v) => v * multiplier);
      deduction.update('Cheese', (v) => v * multiplier);
      deduction.update('Tomato Sauce', (v) => v * multiplier);
    }

    if (crust != null && crust == 'Thick')
      deduction.update('Dough', (v) => v * 1.2);
    if (stuffed != null && stuffed == 'Cheese burst') {
      deduction['Cheese'] = (deduction['Cheese'] ?? 0) + 50.0;
    }

    addons?.forEach((addon) {
      switch (addon) {
        case 'Extra cheese':
          deduction['Cheese'] = (deduction['Cheese'] ?? 0) + 30.0;
          break;
        case 'Double toppings':
          deduction['Tomato Sauce'] = (deduction['Tomato Sauce'] ?? 0) + 40.0;
          break;
        case 'Garlic':
          deduction['Garlic'] = (deduction['Garlic'] ?? 0) + 10.0;
          break;
        case 'Marinara':
          deduction['Marinara'] = (deduction['Marinara'] ?? 0) + 15.0;
          break;
        case 'Olive Oil':
          deduction['Olive Oil'] = (deduction['Olive Oil'] ?? 0) + 10.0;
          break;
      }
    });
  }

  // --- PASTA ---
  if (type == 'pasta') {
    deduction['Tomato Sauce'] = 30.0;
    deduction['Olive Oil'] = 10.0;

    addons?.forEach((addon) {
      switch (addon) {
        case 'Extra parmesan':
        case 'Mozzarella':
        case 'Ricotta':
          deduction['Cheese'] = (deduction['Cheese'] ?? 0) + 20.0;
          break;
        case 'Extra tomato or cream sauce':
          deduction['Tomato Sauce'] = (deduction['Tomato Sauce'] ?? 0) + 20.0;
          break;
        case 'Garlic bread':
        case 'Breadsticks':
          deduction['Dough'] = (deduction['Dough'] ?? 0) + 1.0;
          deduction['Cheese'] = (deduction['Cheese'] ?? 0) + 20.0;
          break;
        case 'Side salad':
          deduction['Carrot'] = (deduction['Carrot'] ?? 0) + 20.0;
          deduction['Cabbage'] = (deduction['Cabbage'] ?? 0) + 20.0;
          break;
      }
    });
  }

  // --- RICE ---
  if (type == 'rice') {
    deduction['Rice'] = 100.0;
    deduction['Soy Sauce'] = 10.0;

    addons?.forEach((addon) {
      switch (addon) {
        case 'Extra rice':
          deduction['Rice'] = (deduction['Rice'] ?? 0) + 100.0;
          break;
        case 'Fried egg':
          deduction['Egg'] = (deduction['Egg'] ?? 0) + 1.0;
          break;
        case 'Spring rolls':
          deduction['Dough'] = (deduction['Dough'] ?? 0) + 0.5;
          deduction['Carrot'] = (deduction['Carrot'] ?? 0) + 10.0;
          deduction['Cabbage'] = (deduction['Cabbage'] ?? 0) + 10.0;
          break;
      }
    });
  }

  return deduction;
}