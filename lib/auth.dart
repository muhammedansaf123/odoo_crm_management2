import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (loggedIn == false) {
      print("loggedin is null $loggedIn");
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == false) {
          Future.microtask(() {
            print("login is working");
            Navigator.pushReplacementNamed(context, '/login');
          });
        } else {
          Future.microtask(() {
            print("dashboard is working");
            Navigator.pushReplacementNamed(context, '/dashboard');
          });
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
