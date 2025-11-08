import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'dashboard_page.dart';
import 'edit_profile_page.dart';
import 'ui/dash_page_ui.dart';

class dash extends StatefulWidget {
  @override
  _dashState createState() => _dashState();
}

class _dashState extends State<dash> {
  String? username;
  String? role;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
      role = prefs.getString("role");
      userId = prefs.getString("id");
    });
  }

  /// 🔹 Unified logout confirmation dialog
  Future<bool> _showLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            title: Text(
              "Confirm Logout",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "Are you sure you want to log out?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  "Logout",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return DashPageUI(
      username: username,
      role: role,
      userId: userId,
      onLogin: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        ).then((_) => _loadUser());
      },
      onRegister: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RegisterPage()),
        );
      },
      onDashboard: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              username: username ?? "",
              role: role ?? "",
              userId: userId ?? "",
            ),
          ),
        );
      },
      onMenuSelected: (value) async {
        if (value == "profile") {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProfilePage(currentUsername: username ?? ""),
            ),
          );
          _loadUser();
        } else if (value == "logout") {
          final shouldLogout = await _showLogoutDialog(context);

          if (shouldLogout) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            setState(() {
              username = null;
              role = null;
              userId = null;
            });

            // Optional: show snackbar after logout
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Logged out successfully")));
          }
        }
      },
    );
  }
}
