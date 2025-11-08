import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_application/task_page.dart';
import 'widgets/sidebar.dart';
import '../menu_management_page.dart';
import '../manager_page.dart';
import '../inventory_page.dart';
import '../cart_page.dart';
import '../sales_page.dart';
import '../expenses_page.dart';
import '../showOrderPopup.dart';

// ===================== PIZZA DASHBOARD PAGE =====================
class PizzaDashboardPage extends StatefulWidget {
  final bool isSidebarOpen;
  final VoidCallback toggleSidebar;
  final VoidCallback? onHome;
  final VoidCallback? onDashboard;
  final VoidCallback? onAdminDashboard;
  final VoidCallback? onManagerPage;
  final VoidCallback? onMaterials;
  final VoidCallback? onMenu;
  final VoidCallback? onSales;
  final VoidCallback? onExpenses;
  final VoidCallback? onTaskPage;
  final VoidCallback? onInventory;
  final String currentUsername;
  final String currentRole;
  final String userId;
  final VoidCallback onLogout;
  final String activePage;
  final List<dynamic> menuItems;
  final Future<void> Function()? onRefreshMenu;
  final bool isLoading;
  final VoidCallback onEditProfile;
  final String apiBase;

  const PizzaDashboardPage({
    super.key,
    required this.isSidebarOpen,
    required this.toggleSidebar,
    required this.currentUsername,
    required this.currentRole,
    required this.userId,
    required this.onLogout,
    required this.activePage,
    required this.menuItems,
    required this.isLoading,
    required this.onEditProfile,
    required this.apiBase,
    required this.onHome,
    this.onDashboard,
    this.onAdminDashboard,
    this.onManagerPage,
    this.onMaterials,
    this.onMenu,
    this.onSales,
    this.onExpenses,
    this.onTaskPage,
    this.onInventory,
    this.onRefreshMenu,
  });

  @override
  State<PizzaDashboardPage> createState() => _PizzaDashboardPageState();
}

class _PizzaDashboardPageState extends State<PizzaDashboardPage> {
  String currentModule = "dashboard";
  String selectedCategory = "All";
  late List<dynamic> filteredMenuItems;

  bool showCart = false;
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    currentModule = widget.activePage;
    _applyCategoryFilter(selectedCategory);
  }

  void _applyCategoryFilter(String category) {
    List<dynamic> visibleItems = widget.menuItems.where((item) {
      if (item['status'] != "visible") return false;
      if (category == "All") return true;
      return (item['category']?.toString().toLowerCase() ==
          category.toLowerCase());
    }).toList();

    setState(() {
      filteredMenuItems = visibleItems;
      selectedCategory = category;
    });
  }

  void _refreshMenu() async {
    if (widget.onRefreshMenu != null) {
      await widget.onRefreshMenu!();
      _applyCategoryFilter(selectedCategory);
    }
  }

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

  void _switchModule(String module) {
    setState(() {
      currentModule = module;
    });
  }

  void _toggleCart() {
    setState(() {
      showCart = !showCart;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Row(
            children: [
              Sidebar(
                isSidebarOpen: widget.isSidebarOpen,
                toggleSidebar: widget.toggleSidebar,
                onHome: widget.onHome ?? () => _switchModule("dashboard"),
                onDashboard: () {
                  Navigator.pop(context);
                },
                onTaskPage: widget.onTaskPage ?? () => _switchModule("tasks"),
                onAdminDashboard: widget.onAdminDashboard,
                onMaterials: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManagerPage(
                        username: widget.currentUsername,
                        role: widget.currentRole,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                onInventory: () {
                  if (widget.currentRole.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InventoryManagementPage(
                          userId: widget.userId,
                          username: widget.currentUsername,
                          role: widget.currentRole,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onHome: widget.onHome ?? () {},
                          onDashboard: widget.onDashboard ?? () {},
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Inventory");
                  }
                },
                onMenu: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuManagementPage(
                        username: widget.currentUsername,
                        role: widget.currentRole,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                onSales: () {
                  if (widget.currentRole.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalesContent(
                          userId: widget.userId,
                          username: widget.currentUsername,
                          role: widget.currentRole,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onHome: widget.onHome ?? () {},
                          onDashboard: widget.onDashboard ?? () {},
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Sales");
                  }
                },
                onExpenses: () {
                  if (widget.currentRole.toLowerCase() == "manager") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpensesContent(
                          userId: widget.userId,
                          username: widget.currentUsername,
                          role: widget.currentRole,
                          isSidebarOpen: widget.isSidebarOpen,
                          toggleSidebar: widget.toggleSidebar,
                          onHome: widget.onHome ?? () {},
                          onDashboard: widget.onDashboard ?? () {},
                          onLogout: widget.onLogout,
                        ),
                      ),
                    );
                  } else {
                    _showAccessDeniedDialog(context, "Expenses");
                  }
                },
                username: widget.currentUsername,
                role: widget.currentRole,
                userId: widget.userId,
                onLogout: widget.onLogout,
                activePage: currentModule,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildContent(),
                ),
              ),
            ],
          ),

          if (showCart)
            GestureDetector(
              onTap: _toggleCart,
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),

          if (showCart)
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: MediaQuery.of(context).size.width * 0.3,
                color: Colors.white,
                child: CartPage(
                  cartItems: cartItems,
                  rawMaterials: widget.menuItems,
                  apiBase: widget.apiBase,
                  onClose: _toggleCart,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (currentModule) {
      case "dashboard":
        return _buildDashboardPage();
      case "sales":
        return SalesContent(
          userId: widget.userId,
          username: widget.currentUsername,
          role: widget.currentRole,
          isSidebarOpen: widget.isSidebarOpen,
          toggleSidebar: widget.toggleSidebar,
          onHome: widget.onHome ?? () {},
          onDashboard: widget.onDashboard ?? () {},
          onLogout: widget.onLogout,
        );
      case "expenses":
        return ExpensesContent(
          userId: widget.userId,
          username: widget.currentUsername,
          role: widget.currentRole,
          isSidebarOpen: widget.isSidebarOpen,
          toggleSidebar: widget.toggleSidebar,
          onHome: widget.onHome ?? () {},
          onDashboard: widget.onDashboard ?? () {},
          onLogout: widget.onLogout,
        );
      case "tasks":
        return TaskPage(
          userId: widget.userId,
          username: widget.currentUsername,
          role: widget.currentRole,
        );
      default:
        return Center(
          child: Text(
            "Module not found.",
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.red),
          ),
        );
    }
  }

  Widget _buildDashboardPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          toggleSidebar: widget.toggleSidebar,
          currentUsername: widget.currentUsername,
          onEditProfile: widget.onEditProfile,
          onLogout: widget.onLogout,
        ),
        const SizedBox(height: 20),
        _CategoryChips(
          menuItems: widget.menuItems,
          selectedCategory: selectedCategory,
          onFilter: _applyCategoryFilter,
          onCartPressed: _toggleCart,
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text("Loading menu...", style: GoogleFonts.poppins(fontSize: 13)),
            ],
            IconButton(
              onPressed: _refreshMenu,
              icon: const Icon(Icons.refresh, color: Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ✅ Added menu grid here
        Expanded(
          child: _MenuGrid(
            menuItems: filteredMenuItems,
            onAddToCart: (item) {
              showOrderPopup(context, item, (cartItem) {
                setState(() {
                  cartItems.add(cartItem);
                });
              });
            },
            apiBase: widget.apiBase,
          ),
        ),
      ],
    );
  }
}

// ================== HEADER ==================
class _Header extends StatelessWidget {
  final VoidCallback toggleSidebar;
  final String currentUsername;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;

  const _Header({
    required this.toggleSidebar,
    required this.currentUsername,
    required this.onLogout,
    required this.onEditProfile,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: toggleSidebar,
              icon: const Icon(Icons.menu, color: Colors.orange),
            ),
            Text(
              "Fire & Flavor Pizza",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        PopupMenuButton<String>(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'profile') {
              onEditProfile();
            } else if (value == 'logout') {
              onLogout();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'profile', child: Text("Edit Profile")),
            PopupMenuItem(value: 'logout', child: Text("Logout")),
          ],
          child: Row(
            children: [
              Text(
                "Hi, $currentUsername 👋",
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.orange),
            ],
          ),
        ),
      ],
    );
  }
}

// ================== CATEGORY CHIPS ==================
class _CategoryChips extends StatefulWidget {
  final List<dynamic> menuItems;
  final Function(String) onFilter;
  final String selectedCategory;
  final VoidCallback onCartPressed;

  const _CategoryChips({
    required this.menuItems,
    required this.onFilter,
    required this.onCartPressed,
    this.selectedCategory = "All",
    Key? key,
  }) : super(key: key);

  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  final List<String> categories = [
    "All",
    "Pizza",
    "Pasta",
    "Rice Meals",
    "Drinks",
    "Desserts",
  ];
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = categories.indexOf(widget.selectedCategory);
    if (selectedIndex == -1) selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ChoiceChip(
                  label: Text(
                    categories[index],
                    style: GoogleFonts.poppins(
                      color: selectedIndex == index
                          ? Colors.white
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: selectedIndex == index,
                  selectedColor: Colors.orange,
                  backgroundColor: Colors.white,
                  onSelected: (_) {
                    setState(() => selectedIndex = index);
                    widget.onFilter(categories[index]);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: const BorderSide(color: Colors.orange),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: widget.onCartPressed,
          ),
        ),
      ],
    );
  }
}

// ================== MENU GRID ==================
class _MenuGrid extends StatelessWidget {
  final List<dynamic> menuItems;
  final void Function(Map<String, dynamic>) onAddToCart;
  final String apiBase;

  const _MenuGrid({
    required this.menuItems,
    required this.onAddToCart,
    required this.apiBase,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (menuItems.isEmpty) {
      return Center(
        child: Text(
          "No menu items available.",
          style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: menuItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final item = menuItems[index] as Map<String, dynamic>;
        final imageUrl = (item['image'] ?? '').toString().isEmpty
            ? "https://via.placeholder.com/150x120?text=No+Image"
            : item['image'].toString();
        final name = item['name']?.toString() ?? 'Unnamed Item';
        final priceText = item['price']?.toString() ?? '0';
        final description = item['description']?.toString() ?? 'No description';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==== IMAGE ====
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),

              // ==== TEXT DETAILS ====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        "₱$priceText",
                        style: GoogleFonts.poppins(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // ==== ADD TO CART BUTTON ====
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => onAddToCart(item),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: Text(
                            "Add to Cart",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}