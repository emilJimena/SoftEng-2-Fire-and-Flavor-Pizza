import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';
import '../manager_page.dart';
import '../menu_management_page.dart';
import '../inventory_page.dart';
import '../sales_page.dart';
import '../expenses_page.dart';

class MenuManagementPageUI extends StatelessWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final List menuItems;
  final bool isLoading;
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool showHidden;
  final VoidCallback onShowHiddenToggle;
  final VoidCallback onAddEntry;
  final Function(Map) onEditMenu;
  final Function(int, String) onToggleMenu;
  final void Function(Comparable Function(Map), int, bool) onSort;
  final String username;
  final String role;
  final String userId;
  final VoidCallback onHome;
  final VoidCallback onDashboard;
  final VoidCallback onTaskPage;
  final Future<void> Function() onLogout;

  final Function(int) onViewIngredients;

  final int? selectedMenuId;
  final List<Map> selectedMenuIngredients;
  final Function(int) onAddIngredient;
  final Function(int, int) onDeleteIngredient;

  const MenuManagementPageUI({
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.menuItems,
    required this.isLoading,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.showHidden,
    required this.onShowHiddenToggle,
    required this.onAddEntry,
    required this.onEditMenu,
    required this.onToggleMenu,
    required this.onSort,
    required this.username,
    required this.role,
    required this.userId,
    required this.onHome,
    required this.onDashboard,
    required this.onTaskPage,
    required this.onLogout,
    required this.onViewIngredients,
    required this.selectedMenuId,
    required this.selectedMenuIngredients,
    required this.onAddIngredient,
    required this.onDeleteIngredient,
    Key? key,
  }) : super(key: key);

  void _showAccessDeniedDialog(BuildContext context, String pageName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text(
          "You don’t have permission to access $pageName. This page is only available to Managers.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter menu items based on visibility
    final filteredMenuItems = menuItems.where((item) {
      final status = item['status']?.toString().toLowerCase() ?? 'visible';
      return showHidden ? status == 'hidden' : status == 'visible';
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.grey[900]!, Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Row(
            children: [
              Sidebar(
                isSidebarOpen: isSidebarOpen,
                onHome: onHome,
                onDashboard: onDashboard,
                onTaskPage: onTaskPage,
                onMaterials: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManagerPage(
                        username: username,
                        role: role,
                        userId: userId,
                      ),
                    ),
                  );
                },
                onInventory: () {
                  if (role.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryManagementPage(
                          userId: userId,
                          username: username,
                          role: role,
                          isSidebarOpen: isSidebarOpen,
                          toggleSidebar: toggleSidebar,
                          onHome: onHome,
                          onDashboard: onDashboard,
                          onLogout: onLogout,
                        ),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Access Denied"),
                        content: const Text(
                          "You don’t have permission to access the Inventory. This page is only available to Managers.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                onMenu: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuManagementPage(
                        username: username,
                        role: role,
                        userId: userId,
                      ),
                    ),
                  );
                },
                onSales: () {
                  if (role.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalesContent(
                          userId: userId,
                          username: username,
                          role: role,
                          isSidebarOpen: isSidebarOpen,
                          toggleSidebar: toggleSidebar,
                          onHome: () => onHome,
                          onDashboard: () => onDashboard,
                          onLogout: onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Sales");
                  }
                },
                onExpenses: () {
                  if (role.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpensesContent(
                          userId: userId,
                          username: username,
                          role: role,
                          isSidebarOpen: isSidebarOpen,
                          toggleSidebar: toggleSidebar,
                          onHome: () => onHome,
                          onDashboard: () => onDashboard,
                          onLogout: onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Expenses");
                  }
                },
                username: username,
                role: role,
                userId: userId,
                onLogout: onLogout,
                activePage: "menu",
              ),

              Expanded(
                child: Column(
                  children: [
                    // Top bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black, Colors.grey[900]!],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isSidebarOpen ? Icons.arrow_back_ios : Icons.menu,
                              color: Colors.orange,
                            ),
                            onPressed: toggleSidebar,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Manager - Menu Management",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 3, color: Colors.orange),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      // Menu DataTable
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.95,
                                        ),
                                        margin: const EdgeInsets.only(top: 100),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            255,
                                            37,
                                            37,
                                            37,
                                          ).withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minWidth: 700,
                                            ),
                                            child: DataTable(
                                              sortColumnIndex: sortColumnIndex,
                                              sortAscending: sortAscending,
                                              columnSpacing: 40,
                                              headingRowHeight: 56,
                                              dataRowHeight: 56,
                                              columns: [
                                                DataColumn(
                                                  label: const Text(
                                                    "Product Name",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  onSort: (col, asc) => onSort(
                                                    (m) => m['name'] ?? '',
                                                    col,
                                                    asc,
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: const Text(
                                                    "Price",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  onSort: (col, asc) => onSort(
                                                    (m) =>
                                                        double.tryParse(
                                                          m['price']
                                                                  ?.toString() ??
                                                              "0",
                                                        ) ??
                                                        0,
                                                    col,
                                                    asc,
                                                  ),
                                                ),
                                                const DataColumn(
                                                  label: Text(
                                                    "Description",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: const Text(
                                                    "Category",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  onSort: (col, asc) => onSort(
                                                    (m) => m['category'] ?? '',
                                                    col,
                                                    asc,
                                                  ),
                                                ),
                                                const DataColumn(
                                                  label: Text(
                                                    "Actions",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              rows: filteredMenuItems.map<DataRow>((
                                                item,
                                              ) {
                                                final isSelected =
                                                    selectedMenuId != null &&
                                                    selectedMenuId ==
                                                        int.parse(
                                                          item['id'].toString(),
                                                        );

                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        "${item['name'] ?? 'Unnamed'}${isSelected ? ' (Selected)' : ''}",
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                      onTap: () =>
                                                          onViewIngredients(
                                                            int.parse(
                                                              item['id']
                                                                  .toString(),
                                                            ),
                                                          ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        "₱${item['price']}",
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width: 200,
                                                        child: Text(
                                                          item['description'] ??
                                                              "No description",
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        item['category'] ?? "",
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.edit,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                            onPressed: () =>
                                                                onEditMenu(
                                                                  item,
                                                                ),
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                              item['status'] ==
                                                                      "visible"
                                                                  ? Icons
                                                                        .visibility
                                                                  : Icons
                                                                        .visibility_off,
                                                              color:
                                                                  item['status'] ==
                                                                      "visible"
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                            ),
                                                            onPressed: () =>
                                                                onToggleMenu(
                                                                  int.parse(
                                                                    item['id']
                                                                        .toString(),
                                                                  ),
                                                                  item['status'],
                                                                ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(
                                                              Icons.add,
                                                              color:
                                                                  Colors.orange,
                                                            ),
                                                            onPressed: () =>
                                                                onAddIngredient(
                                                                  int.parse(
                                                                    item['id']
                                                                        .toString(),
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Floating buttons
                                      Positioned(
                                        right: 20,
                                        top: 35,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              height: 40,
                                              child: InkWell(
                                                onTap: onShowHiddenToggle,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: showHidden
                                                        ? Colors.green
                                                              .withOpacity(0.9)
                                                        : Colors.red
                                                              .withOpacity(0.9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        showHidden
                                                            ? Icons.visibility
                                                            : Icons
                                                                  .visibility_off,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        showHidden
                                                            ? "Visible Menu"
                                                            : "Hidden Menu",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              height: 40,
                                              child: InkWell(
                                                onTap: onAddEntry,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[850]!
                                                        .withOpacity(0.9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: Image.asset(
                                                          "assets/images/add.png",
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Text(
                                                        "Add Menu",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Status banner
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 20,
                                      bottom: 20,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      transitionBuilder: (child, animation) {
                                        final offsetAnimation = Tween<Offset>(
                                          begin: const Offset(0.0, 0.5),
                                          end: Offset.zero,
                                        ).animate(animation);
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                            position: offsetAnimation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        key: ValueKey<bool>(showHidden),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: showHidden
                                              ? Colors.red.withOpacity(0.8)
                                              : Colors.green.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          showHidden
                                              ? "Currently Viewing: Hidden Items"
                                              : "Currently Viewing: Visible Items",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Ingredients Table
                                  if (selectedMenuIngredients.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                        horizontal: 16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 12),
                                          const Text(
                                            "Ingredients for Selected Menu",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orangeAccent,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color.fromARGB(
                                                255,
                                                37,
                                                37,
                                                37,
                                              ).withOpacity(0.85),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: DataTable(
                                              columnSpacing: 30,
                                              headingRowHeight: 50,
                                              dataRowHeight: 50,
                                              columns: const [
                                                DataColumn(
                                                  label: Text(
                                                    "Raw Material",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    "Quantity",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    "Unit",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                DataColumn(
                                                  label: Text(
                                                    "Actions",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              rows: selectedMenuIngredients.map((
                                                ingredient,
                                              ) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Text(
                                                        ingredient['name'] ??
                                                            "",
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        ingredient['quantity']
                                                                ?.toString() ??
                                                            "",
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        ingredient['unit']
                                                                ?.toString() ??
                                                            "",
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.delete,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          if (selectedMenuId !=
                                                              null) {
                                                            onDeleteIngredient(
                                                              selectedMenuId!,
                                                              int.parse(
                                                                ingredient['id']
                                                                    .toString(),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
