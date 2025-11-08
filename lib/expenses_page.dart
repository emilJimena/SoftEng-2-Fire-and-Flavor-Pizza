import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/widgets/sidebar.dart';
import 'manager_page.dart';
import 'inventory_page.dart';
import 'task_page.dart';
import 'menu_management_page.dart';
import 'sales_page.dart';
import 'dash.dart';
import 'dashboard_page.dart';

class ExpensesContent extends StatefulWidget {
  final String userId;
  final String username;
  final String role;
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final VoidCallback onHome;
  final VoidCallback onDashboard;
  final VoidCallback onLogout;

  const ExpensesContent({
    super.key,
    required this.userId,
    required this.username,
    required this.role,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.onHome,
    required this.onDashboard,
    required this.onLogout,
  });

  @override
  State<ExpensesContent> createState() => _ExpensesContentState();
}

class _ExpensesContentState extends State<ExpensesContent> {
  late bool _isSidebarOpen;

  @override
  void initState() {
    super.initState();
    _isSidebarOpen = widget.isSidebarOpen;
  }

  void _showAccessDeniedDialog(String page) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Access Denied"),
        content: Text(
          "You don’t have permission to access the $page page. This page is only available to Managers.",
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

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
    widget.toggleSidebar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar wrapped in Material
          // Sidebar row for Expenses page
          Material(
            elevation: 2,
            child: Sidebar(
              isSidebarOpen: _isSidebarOpen, // use local state
              toggleSidebar: _toggleSidebar, // toggle local state
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
              onMaterials: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManagerPage(
                      username: widget.username,
                      role: widget.role,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              onInventory: () {
                if (widget.role.toLowerCase() == "manager") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryManagementPage(
                        userId: widget.userId,
                        username: widget.username,
                        role: widget.role,
                        isSidebarOpen: widget.isSidebarOpen,
                        toggleSidebar: widget.toggleSidebar,
                        onHome: widget.onHome,
                        onDashboard: widget.onDashboard,
                        onLogout: widget.onLogout,
                      ),
                    ),
                  );
                } else {
                  _showAccessDeniedDialog("Inventory");
                }
              },
              onExpenses: () {
                if (widget.role.toLowerCase() == "manager") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpensesContent(
                        userId: widget.userId,
                        username: widget.username,
                        role: widget.role,
                        isSidebarOpen: widget.isSidebarOpen,
                        toggleSidebar: widget.toggleSidebar,
                        onHome: widget.onHome,
                        onDashboard: widget.onDashboard,
                        onLogout: widget.onLogout,
                      ),
                    ),
                  );
                } else {
                  _showAccessDeniedDialog("Expenses");
                }
              },
              onMenu: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuManagementPage(
                      username: widget.username,
                      role: widget.role,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
              onSales: () {
                if (widget.role.toLowerCase() == "manager") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalesContent(
                        userId: widget.userId,
                        username: widget.username,
                        role: widget.role,
                        isSidebarOpen: widget.isSidebarOpen,
                        toggleSidebar: widget.toggleSidebar,
                        onHome: () => widget.onHome,
                        onDashboard: () => widget.onDashboard,
                        onLogout: widget.onLogout,
                      ),
                    ),
                  );
                } else {
                  _showAccessDeniedDialog("Sales");
                }
              },
              username: widget.username,
              role: widget.role,
              userId: widget.userId,
              onLogout: widget.onLogout,
              activePage: 'expenses',
            ),
          ),

          // Main Expenses Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with toggle button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSidebarOpen ? Icons.arrow_back_ios : Icons.menu,
                          color: Colors.orange,
                        ),
                        onPressed: _toggleSidebar,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Expenses",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Category",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Date",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Amount",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Sample Expense List
                  Expanded(
                    child: ListView(
                      children: [
                        _buildExpenseRow("Ingredients", "2025-10-18", 3500.00),
                        _buildExpenseRow("Electricity", "2025-10-15", 1800.00),
                        _buildExpenseRow(
                          "Employee Salary",
                          "2025-10-10",
                          12000.00,
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
    );
  }

  // Helper for each row
  Widget _buildExpenseRow(String category, String date, double amount) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(category, style: GoogleFonts.poppins(fontSize: 16)),
          ),
          Expanded(
            flex: 2,
            child: Text(date, style: GoogleFonts.poppins(fontSize: 16)),
          ),
          Expanded(
            child: Text(
              "₱${amount.toStringAsFixed(2)}",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
