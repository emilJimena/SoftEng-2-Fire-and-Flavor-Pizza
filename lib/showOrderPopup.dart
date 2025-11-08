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
        return input.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
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

// --- Fetch Addons from API ---
Future<Addons> fetchAddons() async {
  final apiBase = await ApiConfig.getBaseUrl();
  final url = '$apiBase/addons/get_addons.php';

  final res = await http.get(Uri.parse(url));
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return Addons.fromJson(data);
  } else {
    throw Exception('Failed to load addons');
  }
}

// --- Show Order Popup ---
void showOrderPopup(
  BuildContext context,
  Map<String, dynamic> item,
  void Function(Map<String, dynamic>) onAddToCart,
) async {
  late Addons addons;
  try {
    addons = await fetchAddons();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load addons: $e')),
    );
    return;
  }

  double basePrice = (item['price'] is num)
      ? (item['price'] as num).toDouble()
      : double.tryParse(item['price'].toString()) ?? 0.0;

  String type = (item['type'] ?? item['category']?.toString().toLowerCase() ?? 'pizza').toString().toLowerCase();

  // --- Selected Options ---
String selectedSize = addons.sizes.containsKey("Medium") ? "Medium" : addons.sizes.keys.firstOrNull ?? '';
String selectedCrust = addons.crusts.keys.firstOrNull ?? '';
String selectedDip = addons.dips.keys.firstOrNull ?? '';
String selectedStuffed = addons.stuffed.containsKey("None") ? "None" : addons.stuffed.keys.firstOrNull ?? '';


  List<String> selectedPizzaAddons = [];
  List<String> selectedPastaAddons = [];
  List<String> selectedRiceAddons = [];

  Map<String, Map<String, double>> getCurrentAddons() {
    if (type == 'pasta') return addons.pastaAddons;
    if (type == 'rice') return addons.riceAddons;
    return {};
  }

  double computeTotal() {
    double total = basePrice;
    if (type == 'pizza') {
      total *= addons.sizes[selectedSize] ?? 1.0;
      total += addons.crusts[selectedCrust] ?? 0.0;
      total += addons.dips[selectedDip] ?? 0.0;
      total += addons.stuffed[selectedStuffed] ?? 0.0;
      for (var addon in selectedPizzaAddons) {
        total += addons.pizzaAddons[addon] ?? 0.0;
      }
    } else {
      final selected = type == 'pasta' ? selectedPastaAddons : selectedRiceAddons;
      final addonMap = getCurrentAddons();
      for (var category in addonMap.values) {
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
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        double totalPrice = computeTotal();

        return AlertDialog(
          backgroundColor: Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            "Customize ${item['name'] ?? 'Meal'}",
            style: GoogleFonts.poppins(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Base Price: ₱${basePrice.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                SizedBox(height: 12),

                // --- Pizza Options ---
                if (type == 'pizza') ...[
                  _buildRadioSection("Sizes", addons.sizes, selectedSize, (val) => setState(() => selectedSize = val)),
                  _buildRadioSection("Crust Type", addons.crusts, selectedCrust, (val) => setState(() => selectedCrust = val)),
                  _buildRadioSection("Side Dips", addons.dips, selectedDip, (val) => setState(() => selectedDip = val)),
                  _buildRadioSection("Stuffed Crust Option", addons.stuffed, selectedStuffed, (val) => setState(() => selectedStuffed = val)),
                  _buildCheckboxSection("Pizza Addons", addons.pizzaAddons, selectedPizzaAddons, setState),
                ],

                // --- Pasta / Rice Options ---
                if (type == 'pasta' || type == 'rice') ...[
                  ...getCurrentAddons().entries.map((category) {
                    final selected = type == 'pasta' ? selectedPastaAddons : selectedRiceAddons;
                    return _buildCheckboxSection(category.key, category.value, selected, setState);
                  }).toList(),
                ],

                Divider(color: Colors.white24, thickness: 1),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total:", style: GoogleFonts.poppins(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("₱${totalPrice.toStringAsFixed(2)}", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);

                final selectedAddons = type == 'pizza'
                    ? selectedPizzaAddons
                    : type == 'pasta'
                        ? selectedPastaAddons
                        : selectedRiceAddons;

                final cartItem = {
                  'menu_id': item['id'],
                  'name': item['name'],
                  'price': totalPrice,
                  'quantity': 1,
                  'category': type[0].toUpperCase() + type.substring(1),
                  'size': type == 'pizza' ? selectedSize : null,
                  'addons': selectedAddons,
                  'deduction': computeIngredientDeduction(
                    item,
                    size: selectedSize,
                    crust: selectedCrust,
                    stuffed: selectedStuffed,
                    addons: selectedAddons,
                    allAddons: addons, // Pass full addons object
                  ),
                };

                onAddToCart(cartItem);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Added ${item['name']} to cart.", style: GoogleFonts.poppins()),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text("Add to Cart", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      });
    },
  );
}

// --- Helper: Radio Section ---
Widget _buildRadioSection(String title, Map<String, double> options, String groupValue, ValueChanged<String> onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15)),
      Column(
        children: options.entries.map((e) {
          return RadioListTile<String>(
            value: e.key,
            groupValue: groupValue,
            onChanged: (v) => onChanged(v!),
            title: Text("${e.key} (+₱${e.value.toStringAsFixed(2)})", style: GoogleFonts.poppins(color: Colors.white)),
            activeColor: Colors.orangeAccent,
            dense: true,
          );
        }).toList(),
      ),
      SizedBox(height: 10),
    ],
  );
}

// --- Helper: Checkbox Section ---
Widget _buildCheckboxSection(String title, Map<String, double> options, List<String> selected, StateSetter setState) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
      ...options.entries.map((e) {
        return CheckboxListTile(
          value: selected.contains(e.key),
          onChanged: (v) {
            setState(() {
              if (v == true) selected.add(e.key);
              else selected.remove(e.key);
            });
          },
          title: Text("${e.key} (+₱${e.value.toStringAsFixed(2)})", style: GoogleFonts.poppins(color: Colors.white)),
          activeColor: Colors.orangeAccent,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        );
      }).toList(),
      SizedBox(height: 8),
    ],
  );
}

// --- Dynamic Deduction ---
Map<String, double> computeIngredientDeduction(
  Map<String, dynamic> item, {
  String? size,
  String? crust,
  String? stuffed,
  List<String>? addons,
  Addons? allAddons,
}) {
  final Map<String, double> deduction = {};
  final type = (item['type'] ?? item['category']?.toString().toLowerCase() ?? 'pizza').toString().toLowerCase();

  // Base ingredients
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

    if (crust == 'Thick') deduction.update('Dough', (v) => v * 1.2);
    if (stuffed == 'Cheese burst') deduction['Cheese'] = (deduction['Cheese'] ?? 0) + 50.0;
  }

  if (type == 'pasta') {
    deduction['Tomato Sauce'] = 30.0;
    deduction['Olive Oil'] = 10.0;
  }

  if (type == 'rice') {
    deduction['Rice'] = 100.0;
    deduction['Soy Sauce'] = 10.0;
  }

  // Addons deduction dynamically
  if (addons != null && allAddons != null) {
    Map<String, double> addonPrices = {};

    if (type == 'pizza') addonPrices = allAddons.pizzaAddons;
    if (type == 'pasta') allAddons.pastaAddons.forEach((_, map) => addonPrices.addAll(map));
    if (type == 'rice') allAddons.riceAddons.forEach((_, map) => addonPrices.addAll(map));

    for (var addon in addons) {
      if (addonPrices.containsKey(addon)) {
        double amount = (addonPrices[addon]! / 10).ceilToDouble(); // 1 unit per 10 pesos
        deduction[addon] = (deduction[addon] ?? 0) + amount;
      }
    }
  }

  return deduction;
}

// Extension: firstOrNull helper
extension FirstOrNull<K> on Iterable<K> {
  K? get firstOrNull => isEmpty ? null : first;
}
