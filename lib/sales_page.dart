import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'sales_data.dart';
import 'ui/widgets/sidebar.dart';
import 'task_page.dart';
import 'manager_page.dart';
import 'expenses_page.dart';
import 'menu_management_page.dart';
import 'inventory_page.dart';
import 'dash.dart';
import 'dashboard_page.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class SalesContent extends StatefulWidget {
  final String userId;
  final String username;
  final String role;
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final VoidCallback onHome;
  final VoidCallback onDashboard;
  final VoidCallback onLogout;

  const SalesContent({
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
  State<SalesContent> createState() => _SalesContentState();
}

class _SalesContentState extends State<SalesContent> {
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true;
  List<Map<String, dynamic>> _allOrders = [];
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _isSidebarOpen = widget.isSidebarOpen;
    _loadSales();
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
    widget.toggleSidebar();
  }

  Future<void> _loadSales() async {
    setState(() => isLoading = true);
    await SalesData().init();
    await _fetchAndMapOrders();
    setState(() => isLoading = false);
  }

  Future<void> _fetchAndMapOrders() async {
    await SalesData().loadOrders();
    final allOrders = <Map<String, dynamic>>[];

    for (var order in SalesData().orders) {
      final items =
          (order['items'] as List<dynamic>?)?.map((item) {
            return {
              'menuItem': item['menu_item'] ?? '',
              'category': item['category'] ?? '',
              'quantity': item['quantity']?.toString() ?? '1',
              'size': item['size'] ?? '',
              'price': item['price']?.toString() ?? '0.00',
              'addons': (item['addons'] as List<dynamic>?) ?? [],
            };
          }).toList() ?? [];

      allOrders.add({
        'orderName': order['order_name'] ?? 'Order',
        'orderDate': order['order_date'] ?? '--',
        'orderTime': order['order_time'] ?? '--',
        'purchaseMethod': order['payment_method'] ?? 'Cash',
        'items': items,
      });
    }

    allOrders.sort((a, b) {
      try {
        final dateA = DateFormat('MMM dd, yyyy').parse(a['orderDate']);
        final dateB = DateFormat('MMM dd, yyyy').parse(b['orderDate']);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    _allOrders = allOrders;

    final today = DateTime.now();
    final todayOrders = allOrders.where((order) {
      try {
        final orderDate = DateFormat('MMM dd, yyyy').parse(order['orderDate']);
        return orderDate.year == today.year &&
            orderDate.month == today.month &&
            orderDate.day == today.day;
      } catch (_) {
        return false;
      }
    }).toList();

    SalesData().orders
      ..clear()
      ..addAll(todayOrders);
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  double _calculateOrderTotal(Map<String, dynamic> order) {
    double total = 0;
    if (order['items'] is List) {
      for (var item in order['items'] as List) {
        total += double.tryParse(item['price']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  double _calculateTotalSales(List<Map<String, dynamic>> orders) {
    double total = 0;
    for (var order in orders) {
      total += _calculateOrderTotal(order);
    }
    return total;
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

Future<void> _printSalesReport() async {
  final pdf = pw.Document();
  final dateFormat = DateFormat('MMM dd, yyyy');

  // Load Roboto font from assets
  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final robotoFont = pw.Font.ttf(fontData);

  final filteredOrders = (startDate != null || endDate != null)
      ? _allOrders.where((order) {
          DateTime? orderDate;
          try {
            orderDate = dateFormat.parse(order['orderDate']);
          } catch (_) {
            orderDate = null;
          }
          if (orderDate == null) return false;
          if (startDate != null && orderDate.isBefore(startDate!)) return false;
          if (endDate != null && orderDate.isAfter(endDate!)) return false;
          return true;
        }).toList()
      : List<Map<String, dynamic>>.from(SalesData().orders);

  if (filteredOrders.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No sales to print for the selected date.")),
    );
    return;
  }

  final grandTotal = _calculateTotalSales(filteredOrders);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  "Sales Report",
                  style: pw.TextStyle(
                    font: robotoFont,        // <-- Use Roboto here
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  "Generated on: ${dateFormat.format(DateTime.now())}",
                  style: pw.TextStyle(
                    font: robotoFont,        // <-- And here
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Date Range: "
                "${startDate != null ? dateFormat.format(startDate!) : 'All'} - "
                "${endDate != null ? dateFormat.format(endDate!) : 'All'}",
                style: pw.TextStyle(font: robotoFont, fontSize: 12),
              ),
              pw.Text(
                "Total Sales: ₱${grandTotal.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  font: robotoFont,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          ...filteredOrders.map((order) {
            final items = order['items'] as List<dynamic>? ?? [];
            final orderTotal = _calculateOrderTotal(order);

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        order['orderName'] ?? "Order",
                        style: pw.TextStyle(
                          font: robotoFont,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "₱${orderTotal.toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          font: robotoFont,
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "Date: ${order['orderDate']} | Time: ${order['orderTime']} | Payment: ${order['purchaseMethod']}",
                    style: pw.TextStyle(
                      font: robotoFont,
                      fontSize: 11,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Table.fromTextArray(
                    headers: ["Menu Item", "Category", "Qty", "Size", "Price", "Add-ons"],
                    data: items.map((item) {
                      final addons = (item['addons'] as List<dynamic>?)?.join(", ") ?? '';
                      return [
                        item['menuItem'] ?? '',
                        item['category'] ?? '',
                        item['quantity']?.toString() ?? '1',
                        item['size'] ?? '',
                        "₱${item['price']?.toString() ?? '0.00'}",
                        addons,
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      font: robotoFont,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                    cellStyle: pw.TextStyle(
                      font: robotoFont,
                      fontSize: 10,
                    ),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                    cellAlignment: pw.Alignment.centerLeft,
                    headerAlignment: pw.Alignment.centerLeft,
                    border: pw.TableBorder.symmetric(
                      inside: pw.BorderSide(color: PdfColors.grey400, width: 0.3),
                      outside: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.Divider(thickness: 1),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Grand Total: ₱${grandTotal.toStringAsFixed(2)}",
              style: pw.TextStyle(
                font: robotoFont,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ];
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}


  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    final filteredOrders = (startDate == null && endDate == null)
        ? _allOrders.where((order) {
            try {
              final orderDate = dateFormat.parse(order['orderDate']);
              final today = DateTime.now();
              return orderDate.year == today.year &&
                  orderDate.month == today.month &&
                  orderDate.day == today.day;
            } catch (_) {
              return false;
            }
          }).toList()
        : _allOrders.where((order) {
            DateTime? orderDate;
            try {
              orderDate = dateFormat.parse(order['orderDate']);
            } catch (_) {
              orderDate = null;
            }
            if (orderDate == null) return false;
            if (startDate != null && orderDate.isBefore(startDate!)) return false;
            if (endDate != null && orderDate.isAfter(endDate!)) return false;
            return true;
          }).toList();

    final Map<String, List<Map<String, dynamic>>> groupedOrders = {};
    for (var order in filteredOrders) {
      groupedOrders.putIfAbsent(order['orderDate'], () => []).add(order);
    }

    final sortedDates = groupedOrders.keys.toList()
      ..sort((a, b) {
        try {
          final dateA = dateFormat.parse(a);
          final dateB = dateFormat.parse(b);
          return dateB.compareTo(dateA);
        } catch (_) {
          return 0;
        }
      });

    return Scaffold(
      body: Row(
        children: [
          Material(
            elevation: 2,
            child: Sidebar(
              isSidebarOpen: _isSidebarOpen,
              toggleSidebar: _toggleSidebar,
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
              onSales: () {},
              username: widget.username,
              role: widget.role,
              userId: widget.userId,
              onLogout: widget.onLogout,
              activePage: 'sales',
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isSidebarOpen ? Icons.arrow_back_ios : Icons.menu,
                            color: Colors.orange,
                          ),
                          onPressed: _toggleSidebar,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Sales Report",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon:
                              const Icon(Icons.refresh, color: Colors.orange),
                          onPressed: _loadSales,
                          tooltip: "Refresh",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date range selector (no print here)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
  startDate == null && endDate == null
      ? DateFormat('MMM d, yyyy').format(DateTime.now()) // show today by default
      : startDate != null && endDate != null
          ? "${DateFormat('MMM d, yyyy').format(startDate!)} - ${DateFormat('MMM d, yyyy').format(endDate!)}"
          : startDate != null
              ? DateFormat('MMM d, yyyy').format(startDate!)
              : endDate != null
                  ? DateFormat('MMM d, yyyy').format(endDate!)
                  : DateFormat('MMM d, yyyy').format(DateTime.now()),
  style: GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  ),
),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _pickDate(context, true),
                              icon: const Icon(Icons.calendar_today,
                                  color: Colors.orange, size: 18),
                              label: Text(
                                "From",
                                style: GoogleFonts.poppins(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _pickDate(context, false),
                              icon: const Icon(Icons.calendar_today,
                                  color: Colors.orange, size: 18),
                              label: Text(
                                "To",
                                style: GoogleFonts.poppins(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total Sales
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          "Total Sales: ",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₱${_calculateTotalSales(filteredOrders).toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Orders List + Floating Print Button
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 70),
                          child: isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : filteredOrders.isEmpty
                                  ? Center(
                                      child: Text(
                                        "No sales recorded for this date.",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: sortedDates.length,
                                      itemBuilder: (context, dateIndex) {
                                        final dateKey =
                                            sortedDates[dateIndex];
                                        final orders =
                                            groupedOrders[dateKey]!;
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.15),
                                                  blurRadius: 6,
                                                  offset:
                                                      const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dateKey,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                                const Divider(),
                                                ...orders.map((order) {
                                                  final items = order['items']
                                                          as List<dynamic>? ??
                                                      [];
                                                  final orderTotal =
                                                      _calculateOrderTotal(
                                                          order);
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 12),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "${order['orderName']} - ₱${orderTotal.toStringAsFixed(2)}",
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          "Time: ${order['orderTime']} | Payment: ${order['purchaseMethod']}",
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 13,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        ...items.map((item) {
                                                          final addons =
                                                              (item['addons']
                                                                          as List<
                                                                              dynamic>?)
                                                                      ?.join(
                                                                          ", ") ??
                                                                  '';
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom:
                                                                        4),
                                                            child: Text(
                                                              "• ${item['menuItem']} (${item['category']}) - Qty: ${item['quantity']}, "
                                                              "Size: ${item['size']}, ₱${item['price']} ${addons.isNotEmpty ? '($addons)' : ''}",
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          );
                                                        }),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),

                        // Floating print button
Positioned(
  bottom: 10,
  right: 10,
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          spreadRadius: 2,
          offset: Offset(2, 4),
        ),
      ],
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: _printSalesReport,
      child: Row(
        mainAxisSize: MainAxisSize.min, // hug content
        children: [
          Image.asset(
            'assets/images/downloads.png', // path to your image
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            "Print Report",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
            ),
          ),
        ],
      ),
    );
  }
}
