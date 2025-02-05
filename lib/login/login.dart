import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

import '../dashboard/dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _urlController =
      TextEditingController(text: "http://10.0.2.2:8018/");
  final TextEditingController _usernameController =
      TextEditingController(text: "1");
  final TextEditingController _passwordController =
      TextEditingController(text: "1");
  final _formKey = GlobalKey<FormState>();
  bool _isUrlValid = false;
  bool _isLoading = false;
  List<DropdownMenuItem<String>> _dropdownItems = [];
  String? _selectedDatabase;
  String? _errorMessage;
  OdooClient? client;
  MemoryImage? _logo;
  String? companyLogo;

  @override
  void initState() {
    print("4444444444444444dddddddddddddddd");
    super.initState();

    // _urlController.addListener(() {
    print("9999999999999999999999999dddddddd");
    setState(() {
      _isUrlValid = _urlController.text.isNotEmpty;
      print(_isUrlValid);
      _dropdownItems.clear();
      _selectedDatabase = null;
      _errorMessage = null;
    });

    if (_isUrlValid) {
      _fetchDatabaseList();
    }
    // });
  }

  Future<void> _fetchDatabaseList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final baseUrl = _urlController.text.trim();
      print(baseUrl);
      client = OdooClient(baseUrl);
      final response = await client!.callRPC('/web/database/list', 'call', {});
      final dbList = response as List<dynamic>;

      setState(() {
        _dropdownItems = dbList
            .map((db) => DropdownMenuItem<String>(
                  value: db,
                  child: Text(db),
                ))
            .toList();
        _errorMessage = null;
      });

      if (dbList.isNotEmpty) {
        await _fetchDatabaseContent(_selectedDatabase!);
        // await _fetchDatabaseContent("dec_31");
        print(_selectedDatabase);
        print("_selectedDatabase_selectedDatabase");
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching database list: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDatabaseContent(String dbName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("Fetching company logo for database: $dbName");

      client = OdooClient(_urlController.text.trim());
      var session = await client!.authenticate(
        _selectedDatabase!,
        // 'dec_31',
        '1',
        '1',
      );
      print("$session/vvvvvvvvvvvvvvvvvvvvvvv");

      final response = await client?.callKw({
        'model': 'res.company',
        'method': 'read',
        'args': [
          [1]
        ],
        'kwargs': {
          'fields': ['logo']
        },
      });
      print(response);
      print("responseresponseresponse");
      if (response != null) {
        companyLogo = response[0]['logo'];
        Uint8List? imageData;
        final logoBase64 = response[0]['logo'];
        if (logoBase64 != null && logoBase64 != 'false') {
          imageData = base64Decode(logoBase64);
          setState(() {
            _logo = MemoryImage(imageData!);
          });
        }
      } else {
        print('No logo found or error in response: $response');
      }
    } catch (e) {
      setState(() {
        print(e);
        _errorMessage = 'Error fetching database content: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        client = OdooClient(_urlController.text.trim());
        var session = await client!.authenticate(
          // _selectedDatabase!,
          'odoo_18',
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

        print("Login successful: $session");
        if (session != null) {
          await _saveSession(session);
          await addShared();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        } else {
          setState(() {
            _errorMessage = 'Authentication failed: No session returned.';
          });
        }
      } on OdooException {
        setState(() {
          _errorMessage = 'Invalid username or password.';
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Network error: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> addShared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('selectedDatabase', 'odoo_18');
    // await prefs.setString('selectedDatabase', _selectedItem!);
    await prefs.setString('url', _urlController.text.trim());
  }

  Future<void> _saveSession(OdooSession session) async {
    final prefs = await SharedPreferences.getInstance();
    print(companyLogo);
    print("companyLogocompanyLogocompanyLogo");
    await prefs.setString('userName', session.userName ?? '');
    await prefs.setString('userLogin', session.userLogin?.toString() ?? '');
    await prefs.setInt('userId', session.userId ?? 0);
    await prefs.setString('sessionId', session.id);
    await prefs.setString('pass', _passwordController.text.trim());
    await prefs.setString('company_logo', companyLogo!);

    await prefs.setString('serverVersion', session.serverVersion ?? '');
    await prefs.setString('userLang', session.userLang ?? '');
    await prefs.setInt('partnerId', session.partnerId ?? 0);
    await prefs.setInt('companyId', session.companyId ?? 0);
    await prefs.setBool('isSystem', session.isSystem ?? false);
    await prefs.setString('userTimezone', session.userTz);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[200]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 100.0,
                    backgroundColor: Colors.transparent,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _logo != null
                              ? Image(
                                  image: _logo!,
                                  // fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context,
                                      Object exception,
                                      StackTrace? stackTrace) {
                                    return Icon(
                                      Icons.home_work,
                                      size: 100,
                                      color: Colors.purple[700],
                                    );
                                  },
                                )
                              : Icon(Icons.home_work,
                                  size: 100, color: Colors.purple[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Odoo Server URL',
                      labelStyle: TextStyle(
                        color: Colors.purple[700],
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple[700]!),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple[700]!),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    style: TextStyle(color: Colors.purple[700]),
                  ),
                  const SizedBox(height: 20),
                  if (_dropdownItems.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedDatabase,
                      onChanged: (value) async {
                        setState(() {
                          _selectedDatabase = value;
                        });
                        await _fetchDatabaseContent(_selectedDatabase!);
                      },
                      items: _dropdownItems,
                      decoration: InputDecoration(
                        labelStyle: TextStyle(
                          color: Colors.purple[700],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[700]!),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple[700]!),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        prefixIcon:
                            Icon(Icons.storage, color: Colors.purple[700]),
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      iconEnabledColor: Colors.purple[700],
                      dropdownColor: Colors.black,
                      style: TextStyle(color: Colors.purple[700]),
                      // ),
                    ),
                  if (_dropdownItems.isEmpty && !_isLoading)
                    const Text(
                      'No databases found. Enter a valid URL.',
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _usernameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your username';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      prefixIcon: Icon(Icons.email, color: Colors.teal),
                      contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    style: TextStyle(color: Colors.teal),
                  ),

                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        color: Colors.teal,
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                      prefixIcon: Icon(Icons.lock, color: Colors.teal),
                      contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    style: TextStyle(color: Colors.teal),
                  ),

                  const SizedBox(height: 20),
                  // Error Message
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text(""),
                      ),
                      TextButton(
                        onPressed: () async {
                          // final url =
                          //     '${_urlController.text.trim()}/web/reset_password?';
                          // launch(url);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResetPasswordPage(
                                url: _urlController.text.trim(),
                                db: 'odoo_18',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Reset Password',
                          style: TextStyle(color: Colors.teal),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.teal, // Primary color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Log In',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),

                  const SizedBox(height: 50),
                  // TextButton(
                  //   onPressed: () {},
                  //   child: const Text('Manage Databases'),
                  // ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/odoo.png',
                        height: 25.0,
                      ),
                      const SizedBox(height: 10.0),
                      const Text(
                        'Powered by Odoo',
                        style: TextStyle(color: Colors.purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  final String url;
  final String db;
  // const ResetPasswordPage({Key? key}) : super(key: key);
  const ResetPasswordPage({
    Key? key,
    required this.url,
    required this.db,
  }) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isResetComplete = false;
  OdooClient? client;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${widget.url}/web/reset_password?';
      launch(url);
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reset Password",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[200]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    text: "Ensure that you are login with odoo",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text:
                            " if Login already click on continue to reset otherwise please login with following link",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: "\n${widget.url}",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final Uri _url = Uri.parse(widget.url);
                            await launch(_url.toString());
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
