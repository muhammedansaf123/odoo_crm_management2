import 'package:flutter/material.dart';

import 'package:odoo_crm_management/initilisation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwitchAccountLogin extends StatelessWidget {
  const SwitchAccountLogin({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController _usernamecontroler = TextEditingController();
    TextEditingController _passwordController = TextEditingController();
    return Consumer<OdooClientManager>(builder: (context, provider, child) {
      return Scaffold(
        backgroundColor: Colors.purple,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 180.0),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40.0),
                TextField(
                  controller: _usernamecontroler,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Colors.purple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      String url = prefs.getString('url') ?? '';
                      await provider.initializeOdooClientWithUrl(url);
                      final client = provider.client;

                      var session = await client!.authenticate(
                        provider.currentsession!.dbName,
                        _usernamecontroler.text.trim(),
                        _passwordController.text.trim(),
                      );

                      if (session != null) {
                        await provider.clear();
                        // Update provider with new session
                        await provider.updateSession(session);
                        provider.storeUserSession(
                            session,
                            url,
                            _passwordController.text,
                            _usernamecontroler.text,
                            context,true);
                      }
                    } catch (e) {
                      print("$e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      );
    });
  }
}
