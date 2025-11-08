import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';
import '../manager_page.dart';
import '../menu_management_page.dart';
import '../inventory_page.dart';
import '../sales_page.dart';
import '../expenses_page.dart';
import 'package:google_fonts/google_fonts.dart';


class ManagerPageUI extends StatelessWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final List materials;
  final bool isLoading;
  final int? sortColumnIndex;
  final bool sortAscending;
  final bool showHidden;
  final VoidCallback onShowHiddenToggle;
  final VoidCallback onAddEntry;
  final Function(Map) onEditMaterial;
  final Function(int, String) onToggleMaterial;
  final void Function(Comparable Function(Map), int, bool) onSort;
  final String username;
  final String role;
  final String userId;
  final VoidCallback onHome;
  final VoidCallback onDashboard;
  final VoidCallback onTaskPage;
  final Future<void> Function() onLogout;

  const ManagerPageUI({
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.materials,
    required this.isLoading,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.showHidden,
    required this.onShowHiddenToggle,
    required this.onAddEntry,
    required this.onEditMaterial,
    required this.onToggleMaterial,
    required this.onSort,
    required this.username,
    required this.role,
    required this.userId,
    required this.onHome,
    required this.onDashboard,
    required this.onTaskPage,
    required this.onLogout,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Row(
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
                _showAccessDeniedDialog(context, "Inventory");
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
            activePage: "materials",
          ),

          // === MAIN CONTENT ===
          Expanded(
            child: Column(
              children: [
                // Top bar
                // Top bar styled like Sales Report header (floating container with soft shadow)
// Top bar styled like Sales Report (same font + floating container)
Padding(
  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
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
        Text(
          "Manager - Raw Materials",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onShowHiddenToggle,
          icon: Icon(
            showHidden ? Icons.visibility : Icons.visibility_off,
            color: Colors.white,
          ),
          label: Text(
            showHidden ? "Visible Items" : "Hidden Items",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: showHidden ? Colors.green : Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: onAddEntry,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            "Add Entry",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    ),
  ),
),
                // === AUTO-EXPANDING TABLE ===
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth - 48,
                                    ),
                                    child: DataTable(
                                      sortColumnIndex: sortColumnIndex,
                                      sortAscending: sortAscending,
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                        Colors.orange.shade100,
                                      ),
                                      headingTextStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      dataTextStyle: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 15,
                                      ),
                                      dividerThickness: 1,
                                      horizontalMargin: 24,
                                      columnSpacing: 80,
                                      border: TableBorder(
                                        horizontalInside: BorderSide(
                                          width: 0.5,
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      columns: [
                                        DataColumn(
                                          label: const Text("Name"),
                                          onSort: (col, asc) => onSort(
                                              (m) => m['name'] ?? '', col, asc),
                                        ),
                                        DataColumn(
                                          label: const Text("Type"),
                                          onSort: (col, asc) => onSort(
                                              (m) => m['type'] ?? '', col, asc),
                                        ),
                                        DataColumn(
                                          label: const Text("Unit"),
                                          onSort: (col, asc) => onSort(
                                              (m) => m['unit'] ?? '', col, asc),
                                        ),
                                        DataColumn(
                                          label: const Text("Status"),
                                          onSort: (col, asc) => onSort(
                                              (m) => m['status'] ?? '', col, asc),
                                        ),
                                        const DataColumn(label: Text("Actions")),
                                      ],
                                      rows: materials
                                          .where((m) => showHidden
                                              ? m['status'] == "hidden"
                                              : m['status'] == "visible")
                                          .map<DataRow>((material) {
                                        return DataRow(
                                          color: MaterialStateProperty.resolveWith<Color?>(
                                            (states) => materials.indexOf(material).isEven
                                                ? Colors.grey[50]
                                                : Colors.white,
                                          ),
                                          cells: [
                                            DataCell(Text(material['name'] ?? "")),
                                            DataCell(Text(material['type'] ?? "")),
                                            DataCell(Text(material['unit'] ?? "")),
                                            DataCell(Text(material['status'] ?? "")),
                                            DataCell(Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blueAccent),
                                                  onPressed: () =>
                                                      onEditMaterial(material),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    material['status'] == "visible"
                                                        ? Icons.visibility
                                                        : Icons.visibility_off,
                                                    color: material['status'] == "visible"
                                                        ? Colors.green
                                                        : Colors.redAccent,
                                                  ),
                                                  onPressed: () => onToggleMaterial(
                                                    int.parse(material['id'].toString()),
                                                    material['status'],
                                                  ),
                                                ),
                                              ],
                                            )),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),

                // === Currently Viewing Label ===
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 30),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
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
                        borderRadius: BorderRadius.circular(20),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
