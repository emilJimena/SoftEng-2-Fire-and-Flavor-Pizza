import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'admin_dashboard_page.dart';
import 'dash.dart';
import 'sales_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SalesData().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fire and Flavor Pizza',
      theme: ThemeData(
        fontFamily:
            'NotoSans', // ensures ₱ and other characters display correctly
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      ),
      home: dash(),
      routes: {
        '/login': (context) => SplashDecider(),
        '/dashboard': (context) =>
            DashboardPage(username: "Guest", role: "user", userId: "0"),
        '/admin': (context) {
          return FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final prefs = snapshot.data!;
              final username = prefs.getString('username') ?? 'guest';
              final role = prefs.getString('role') ?? 'user';
              final userId = prefs.getString('userId') ?? '0';
              return AdminDashboardPage(
                loggedInUsername: username,
                loggedInRole: role,
                userId: userId,
              );
            },
          );
        },
      },
    );
  }
}

class SplashDecider extends StatefulWidget {
  @override
  _SplashDeciderState createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  String? username;
  String? role;
  String? userId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString("username");
      role = prefs.getString("role");
      userId = prefs.getString("userId");
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (username == null || role == null || userId == null) {
      return LoginPage();
    }

    if (role == "root_admin" || (role == "admin" && username != "admin")) {
      return AdminDashboardPage(
        loggedInUsername: username!,
        loggedInRole: role!,
        userId: userId!,
      );
    } else {
      return DashboardPage(username: username!, role: role!, userId: userId!);
    }
  }
}
