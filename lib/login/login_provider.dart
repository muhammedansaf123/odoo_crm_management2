// import 'package:flutter/material.dart';

// class LoginProvider extends ChangeNotifier {

//   Future<void> _fetchDatabaseList() async {
//     Provider.of<OdooClientManager>(context, listen: false).getStoredAccounts();
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       if (_dropdownItems.isEmpty) {
//         _selectedDatabase = null;
//       }
//     });
//     print("dropdown $_dropdownItems");
//     print("database $_selectedDatabase");
//     try {
//       final baseUrl = _urlController.text.trim();
//       if (!Uri.tryParse(baseUrl)!.hasAbsolutePath) {
//         throw Exception("Invalid URL");
//       }

//       print("baseUrl: $baseUrl");
//       client = OdooClient(baseUrl);

//       final testResponse =
//           await client!.callRPC('/web/webclient/version_info', 'call', {});
//       if (testResponse == null) {
//         throw Exception("Server is unreachable");
//       }

//       final response = await client!.callRPC('/web/database/list', 'call', {});

//       if (response is! List) {
//         throw Exception("Invalid response format");
//       }

//       final dbList = response;

//       setState(() {
//         _dropdownItems = dbList
//             .map((db) => DropdownMenuItem<String>(
//                   value: db,
//                   child: Text(db),
//                 ))
//             .toList();

//         _errorMessage = null;
//       });

//       if (dbList.isNotEmpty && _selectedDatabase != null) {
//         await _fetchDatabaseContent(_selectedDatabase!);
//       }
//     } catch (e) {
//       setState(() {
//         _dropdownItems = []; // Clear dropdown if URL is incorrect
//         _selectedDatabase = null;
//         _logo = null;
//         // _errorMessage = "Failed to fetch database list. Check your URL.";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _fetchDatabaseContent(String dbName) async {
//     if (dbName != "Select a Database") {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         print("Fetching company logo for database: $dbName");

//         await client!.authenticate(
//           _selectedDatabase!,
//           '1',
//           '1',
//         );
//         final response = await client?.callKw({
//           'model': 'res.company',
//           'method': 'read',
//           'args': [
//             [1]
//           ],
//           'kwargs': {
//             'fields': ['logo']
//           },
//         });

//         if (response != null) {
//           print('responseis$response');
//           companyLogo = response[0]['logo'];
//           Uint8List? imageData;
//           final logoBase64 = response[0]['logo'];
//           if (logoBase64 != null && logoBase64 != 'false') {
//             imageData = base64Decode(logoBase64);
//             setState(() {
//               _logo = MemoryImage(imageData!);
//             });
//           }
//         } else {
//           print('No logo found or error in response: $response');
//         }
//       } catch (e) {
//         setState(() {
//           print(e);
//           _errorMessage = 'Error fetching database content: $e';
//         });
//       } finally {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = null;
//         });
//       }
//     }
//   }

//   Future<void> _login() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });

//       try {
//         final baseUrl = _urlController.text.trim();

//         if (!Uri.tryParse(baseUrl)!.hasAbsolutePath) {
//           throw Exception("Please Enter a Valid URL");
//         }

//         print("Base URL: $baseUrl");

//         // Access the provider instead of creating a new instance
//         final odooClientProvider =
//             Provider.of<OdooClientManager>(context, listen: false);

//         // Initialize OdooClient in the provider
//         await odooClientProvider.initializeOdooClientWithUrl(baseUrl);

//         final client = odooClientProvider.client;
//         if (client == null) {
//           throw Exception("OdooClient not initialized properly.");
//         }

//         // Check if the server is reachable
//         final testResponse =
//             await client.callRPC('/web/webclient/version_info', 'call', {});
//         if (testResponse == null) {
//           throw Exception("Server is unreachable");
//         }

//         // Fetch database list
//         final response = await client.callRPC('/web/database/list', 'call', {});

//         if (_selectedDatabase != null) {
//           var session = await client.authenticate(
//             _selectedDatabase!,
//             _usernameController.text.trim(),
//             _passwordController.text.trim(),
//           );

//           if (session != null) {
//             await odooClientProvider.clear();
//             // Update provider with new session
//             await odooClientProvider.updateSession(session);
//             print("ansaf is ${odooClientProvider.storedaccounts} ");
//             if (odooClientProvider.storedaccounts.isEmpty) {
//               print("ansaf added");
//               odooClientProvider.storeUserSession(session, baseUrl,
//                   _passwordController.text, _usernameController.text, context,false);
//             }

//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => const Dashboard()),
//             );
//           }
//         }
//       } on OdooException {
//         setState(() {
//           _errorMessage = 'Invalid username or password.';
//         });
//       } on SocketException {
//         setState(() {
//           _errorMessage = 'URL not found. Please check the server address.';
//         });
//       } on HttpException {
//         setState(() {
//           _errorMessage = 'Unable to connect to the server. Please try again.';
//         });
//       } on FormatException {
//         setState(() {
//           _errorMessage = 'URL not found. Please check the server address.';
//         });
//       } catch (e) {
//         setState(() {
//           _errorMessage = '$e'.replaceFirst('Exception: ', '');
//         });
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> addShared() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('isLoggedIn', true);
//     await prefs.setString('selectedDatabase', _selectedDatabase!);
//     // await prefs.setString('selectedDatabase', _selectedItem!);
//     await prefs.setString('url', _urlController.text.trim());
//   }

//   String? urlValidator(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Enter a URL';
//     }

//     final RegExp urlRegExp = RegExp(
//       r'^(https?:\/\/)'
//       r'(([a-zA-Z0-9-_]+\.)+[a-zA-Z]{2,}'
//       r'|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))'
//       r'(:\d{1,5})?'
//       r'(\/[^\s]*)?$',
//       caseSensitive: false,
//     );

//     if (!urlRegExp.hasMatch(value)) {
//       return 'Enter a valid HTTP or HTTPS URL';
//     }

//     return null;
//   }
// }
