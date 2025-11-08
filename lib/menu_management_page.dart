import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dash.dart';
import 'dashboard_page.dart';
import 'task_page.dart';
import 'ui/menu_management_page_ui.dart';

class MenuManagementPage extends StatefulWidget {
  final String username;
  final String role;
  final String userId;

  const MenuManagementPage({
    super.key,
    required this.username,
    required this.role,
    required this.userId,
  });

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage> {
  late String apiBase;

  bool isSidebarOpen = false;
  bool isLoading = false;
  bool showHidden = false;
  int? sortColumnIndex;
  bool sortAscending = true;

  List menuItems = [];
  List rawMaterials = [];
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _setApiBase();
  }

  void addToCart(Map menuItem, {String? size, int quantity = 1}) {
    List<Map<String, dynamic>> mainIngredients =
        (menuItem['mainIngredients'] ?? []).map((ing) {
      return {
        'id': ing['id'] ?? ing['raw_material_id'],
        'name': ing['name'],
        'quantity': double.tryParse(ing['quantity'].toString()) ?? 0,
      };
    }).toList();

    Map<String, dynamic> cartItem = {
      'id': menuItem['id'],
      'name': menuItem['name'],
      'price': menuItem['price'],
      'quantity': quantity,
      'size': size,
      'mainIngredients': mainIngredients,
      'deduction': menuItem['deduction'] ?? {},
      'category': menuItem['category'],
    };

    setState(() => cartItems.add(cartItem));
    _showSnackBar("${menuItem['name']} added to cart.");
  }

  Future<void> fetchRawMaterials() async {
    try {
      final response =
          await http.get(Uri.parse("$apiBase/menu/get_raw_materials.php"));
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() => rawMaterials = data['data']);
      } else {
        _showSnackBar(data['message']);
      }
    } catch (e) {
      _showSnackBar("Error fetching raw materials: $e");
    }
  }

  Future<void> fetchMenuItems() async {
    setState(() => isLoading = true);
    try {
      final response =
          await http.get(Uri.parse("$apiBase/menu/get_menu_items.php"));
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() => menuItems = data['data']);
      } else {
        _showSnackBar(data['message']);
      }
    } catch (e) {
      _showSnackBar("Error fetching menu: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> onViewIngredientsAndShow(int menuId) async {
    try {
      final response = await http
          .get(Uri.parse("$apiBase/menu/get_menu_ingredients.php?menu_id=$menuId"));
      final data = jsonDecode(response.body);
      if (data['success']) {
        List<Map> ingredients = List<Map>.from(data['data']);
        _showIngredientsPopup(menuId, ingredients);
      } else {
        _showSnackBar(data['message']);
      }
    } catch (e) {
      _showSnackBar("Error fetching ingredients: $e");
    }
  }

  void _showIngredientsPopup(int menuId, List<Map> ingredients) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            Future<void> refreshIngredients() async {
              try {
                final response = await http.get(Uri.parse(
                    "$apiBase/menu/get_menu_ingredients.php?menu_id=$menuId"));
                final data = jsonDecode(response.body);
                if (data['success']) {
                  setPopupState(() {
                    ingredients = List<Map>.from(data['data']);
                  });
                } else {
                  _showSnackBar(data['message']);
                }
              } catch (e) {
                _showSnackBar("Error fetching ingredients: $e");
              }
            }

            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 37, 37, 37),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ingredients",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: DataTable(
                    columnSpacing: 30,
                    headingRowHeight: 50,
                    dataRowHeight: 50,
                    columns: const [
                      DataColumn(
                          label: Text("Raw Material",
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text("Quantity",
                              style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label:
                              Text("Unit", style: TextStyle(color: Colors.white))),
                      DataColumn(
                          label: Text("Actions",
                              style: TextStyle(color: Colors.white))),
                    ],
                    rows: ingredients.map((ingredient) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            ingredient['name'] ?? "",
                            style: const TextStyle(color: Colors.white70),
                          )),
                          DataCell(Text(
                            ingredient['quantity']?.toString() ?? "",
                            style: const TextStyle(color: Colors.white70),
                          )),
                          DataCell(Text(
                            ingredient['unit']?.toString() ?? "",
                            style: const TextStyle(color: Colors.white70),
                          )),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await onDeleteIngredient(
                                    menuId, int.parse(ingredient['id'].toString()));
                                await refreshIngredients();
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.add, color: Colors.orange),
                  label: const Text("Add Ingredient",
                      style: TextStyle(color: Colors.orangeAccent)),
                  onPressed: () async {
                    Navigator.pop(context);
                    await onAddIngredient(menuId);
                    await onViewIngredientsAndShow(menuId);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> onAddIngredient(int menuId) async {
    final result = await showDialog<Map>(
      context: context,
      builder: (context) => IngredientFormDialog(rawMaterials: rawMaterials),
    );
    if (result != null) {
      try {
        double quantity = double.tryParse(result['quantity'].toString()) ?? 0.0;
        final response = await http.post(
          Uri.parse("$apiBase/menu/add_menu_ingredient.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "menu_id": menuId,
            "raw_material_id": result['raw_material_id'],
            "quantity": quantity,
          }),
        );
        final data = jsonDecode(response.body);
        _showSnackBar(data['message']);
      } catch (e) {
        _showSnackBar("Error adding ingredient: $e");
      }
    }
  }

  Future<void> onDeleteIngredient(int menuId, int ingredientId) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/menu/delete_menu_ingredient.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"menu_id": menuId, "ingredient_id": ingredientId}),
      );
      final data = jsonDecode(response.body);
      _showSnackBar(data['message']);
    } catch (e) {
      _showSnackBar("Error deleting ingredient: $e");
    }
  }

  Future<String?> _getHostIP() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback)
            return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  void _setApiBase() async {
    if (kIsWeb) {
      apiBase =
          "http://localhost/SoftEng-2-Fire-and-Flavor-Pizza-Place-main/my_php_api";
    } else if (Platform.isAndroid) {
      apiBase =
          "http://10.0.2.2/SoftEng-2-Fire-and-Flavor-Pizza-Place-main/my_php_api";
    } else {
      final ip = await _getHostIP();
      apiBase =
          "http://${ip ?? '127.0.0.1'}/SoftEng-2-Fire-and-Flavor-Pizza-Place-main/my_php_api";
    }
    if (mounted) {
      await fetchMenuItems();
      await fetchRawMaterials();
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void onSort<T>(Comparable<T> Function(Map item) getField, int columnIndex,
      bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
      menuItems.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  Future<void> onAddEntry() async {
    final result = await showDialog<Map>(
      context: context,
      builder: (context) => ProductFormDialog(),
    );
    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse("$apiBase/menu/create_menu_item.php"),
          body: result.map((key, value) => MapEntry(key, value.toString())),
        );
        final data = jsonDecode(response.body);
        _showSnackBar(data['message']);
        if (data['success']) fetchMenuItems();
      } catch (e) {
        _showSnackBar("Error: $e");
      }
    }
  }

  Future<void> onEditMenu(Map item) async {
    final result = await showDialog<Map>(
      context: context,
      builder: (context) => ProductFormDialog(existingItem: item),
    );
    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse("$apiBase/menu/update_menu_item.php"),
          body: result.map((key, value) => MapEntry(key, value.toString())),
        );
        final data = jsonDecode(response.body);
        _showSnackBar(data['message']);
        if (data['success']) fetchMenuItems();
      } catch (e) {
        _showSnackBar("Error: $e");
      }
    }
  }

  Future<void> onToggleMenu(int id, String currentStatus) async {
    try {
      final response = await http.post(
        Uri.parse("$apiBase/menu/toggle_menu_item.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id, "status": currentStatus}),
      );
      final data = jsonDecode(response.body);
      _showSnackBar(data['message']);
      if (data['success']) fetchMenuItems();
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuManagementPageUI(
      isSidebarOpen: isSidebarOpen,
      toggleSidebar: () => setState(() => isSidebarOpen = !isSidebarOpen),
      menuItems: menuItems,
      isLoading: isLoading,
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      showHidden: showHidden,
      onShowHiddenToggle: () => setState(() => showHidden = !showHidden),
      onAddEntry: onAddEntry,
      onEditMenu: onEditMenu,
      onToggleMenu: onToggleMenu,
      onSort: onSort,
      username: widget.username,
      role: widget.role,
      userId: widget.userId,
      onHome: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => dash()),
          (route) => false,
        );
      },
      onDashboard: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              username: widget.username,
              role: widget.role,
              userId: widget.userId,
            ),
          ),
        );
      },
      onTaskPage: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskPage(
              userId: widget.userId,
              username: widget.username,
              role: widget.role,
            ),
          ),
        );
      },
      onLogout: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => dash()),
          (route) => false,
        );
      },
      selectedMenuId: null,
      selectedMenuIngredients: [],
      onAddIngredient: onAddIngredient,
      onDeleteIngredient: onDeleteIngredient,
      onViewIngredients: onViewIngredientsAndShow,
    );
  }
}

// ----------------- Dialogs -----------------
class ProductFormDialog extends StatefulWidget {
  final Map? existingItem;
  const ProductFormDialog({super.key, this.existingItem});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  String? selectedCategory;

  final List<String> categoryOptions = [
    "Rice Meals",
    "Pasta",
    "Pinoy All Time Fave Meals",
    "Pizza",
  ];

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.existingItem?['name']?.toString() ?? '');
    priceController =
        TextEditingController(text: widget.existingItem?['price']?.toString() ?? '');
    descriptionController =
        TextEditingController(text: widget.existingItem?['description']?.toString() ?? '');
    final existingCategory = widget.existingItem?['category']?.toString();
    selectedCategory = (existingCategory != null &&
            categoryOptions.contains(existingCategory))
        ? existingCategory
        : categoryOptions[0];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 41, 41, 41).withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existingItem == null ? "Add Product" : "Edit Product",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Product Name",
                  labelStyle: const TextStyle(color: Colors.orangeAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orangeAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Price",
                  labelStyle: const TextStyle(color: Colors.orangeAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orangeAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Description",
                  labelStyle: const TextStyle(color: Colors.orangeAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orangeAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: const Color.fromARGB(255, 41, 41, 41),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Category",
                  labelStyle: const TextStyle(color: Colors.orangeAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orangeAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categoryOptions
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: const TextStyle(color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      nameController.clear();
                      priceController.clear();
                      descriptionController.clear();
                      setState(() => selectedCategory = categoryOptions[0]);
                    },
                    child: const Text(
                      "Clear All",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        if (widget.existingItem != null)
                          'id': widget.existingItem!['id'].toString(),
                        'name': nameController.text.trim(),
                        'price': double.tryParse(priceController.text.trim())?.toString() ?? '0',
                        'description': descriptionController.text.trim(),
                        'category': selectedCategory ?? categoryOptions[0],
                        'ingredients': '[]',
                        'image': '',
                      });
                    },
                    child: Text(widget.existingItem == null ? "Save" : "Update"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IngredientFormDialog extends StatefulWidget {
  final List rawMaterials;
  const IngredientFormDialog({super.key, required this.rawMaterials});

  @override
  State<IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<IngredientFormDialog> {
  String? selectedRawMaterial;
  TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.rawMaterials.isNotEmpty) {
      selectedRawMaterial = widget.rawMaterials[0]['id'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 41, 41, 41).withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Ingredient",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedRawMaterial,
              dropdownColor: const Color.fromARGB(255, 41, 41, 41),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Raw Material",
                labelStyle: const TextStyle(color: Colors.orangeAccent),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: widget.rawMaterials.map<DropdownMenuItem<String>>((rm) {
                return DropdownMenuItem(
                  value: rm['id'].toString(),
                  child: Text(rm['name'], style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedRawMaterial = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Quantity",
                labelStyle: const TextStyle(color: Colors.orangeAccent),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, {
                  'raw_material_id': selectedRawMaterial,
                  'quantity': quantityController.text.trim(),
                });
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }
}
