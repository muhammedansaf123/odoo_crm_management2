import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OdooClientManager extends ChangeNotifier {
  OdooClient? _client;
  MemoryImage? _profilePicUrl;
  MemoryImage? get profilePicUrl => _profilePicUrl;
  MemoryImage? companyPicUrl;
  OdooSession? _currentsession;
  OdooClient? get client => _client;
  dynamic _userdetails;
  OdooSession? get currentsession => _currentsession;
  dynamic get userDetails => _userdetails;
  Map<String, dynamic> _userInfo = {};
  Map<String, dynamic> get userInfo => _userInfo;
  bool? isLoading = true;

  /// Initializes OdooClient with the provided base URL
  Future<void> initializeOdooClientWithUrl(String url) async {
    _client = OdooClient(url);
    notifyListeners();
  }

  /// Updates session after login
  Future<void> updateSession(OdooSession session) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('url', _client!.baseURL);
    await prefs.setString('sessionId', session.id);
    await prefs.setString('selectedDatabase', session.dbName);
    await prefs.setString('serverVersion', session.serverVersion);
    await prefs.setString('userLang', session.userLang);
    await prefs.setInt('userId', session.userId);
    await prefs.setInt('companyId', session.companyId);
    await prefs.setBool('isLoggedIn', true);

    notifyListeners();
  }

  /// Initializes OdooClient from saved session
  Future<void> initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();

    String url = prefs.getString('url') ?? '';
    String db = prefs.getString('selectedDatabase') ?? '';
    String sessionId = prefs.getString('sessionId') ?? '';
    String serverVersion = prefs.getString('serverVersion') ?? '';
    String userLang = prefs.getString('userLang') ?? '';
    int userId = prefs.getInt('userId') ?? 0;
    int companyId = prefs.getInt('companyId') ?? 0;
    final allowedCompaniesStringList =
        prefs.getStringList('allowedCompanies') ?? [];

    List<Company> allowedCompanies = [];
    if (allowedCompaniesStringList.isNotEmpty) {
      allowedCompanies = allowedCompaniesStringList
          .map((jsonString) => Company.fromJson(jsonDecode(jsonString)))
          .toList();
    }

    final session = OdooSession(
      id: sessionId,
      userId: userId,
      partnerId: prefs.getInt('partnerId') ?? 0,
      userLogin: prefs.getString('userLogin') ?? '',
      userName: prefs.getString('userName') ?? '',
      userLang: userLang,
      userTz: '',
      isSystem: prefs.getBool('isSystem') ?? false,
      dbName: db,
      serverVersion: serverVersion,
      companyId: companyId,
      allowedCompanies: allowedCompanies,
    );
    _currentsession = session;
    _client = OdooClient(url, session);

    getUserProfile();
    notifyListeners();
  }

  /// Stores session details for multiple logged-in users
  Future<void> storeUserSession(OdooSession session, String url) async {
    final prefs = await SharedPreferences.getInstance();
    print("ansaf${1}");
    // Retrieve existing accounts
    List<String> accounts = prefs.getStringList('accounts') ?? [];

    // Decode stored accounts into a list of maps
    List<Map<String, dynamic>> storedAccounts = accounts
        .map((account) => jsonDecode(account) as Map<String, dynamic>)
        .toList();
    print("ansaf${2}");
    // Check if the user already exists in stored accounts
    bool userExists =
        storedAccounts.any((account) => account['userId'] == session.userId);

    if (!userExists) {
      // Create user session data
      Map<String, dynamic> userData = {
        'url': url,
        'sessionId': session.id,
        'dbName': session.dbName,
        'serverVersion': session.serverVersion,
        'userLang': session.userLang,
        'userId': session.userId,
        'companyId': session.companyId,
        'userLogin': session.userLogin,
        'userName': session.userName,
        'partnerId': session.partnerId,
        'isSystem': session.isSystem,
        'allowedCompanies': session.allowedCompanies
            .map((company) => jsonEncode(company.toJson()))
            .toList(),
      };

      // Convert userData to JSON string and store it
      String userJson = jsonEncode(userData);
      accounts.add(userJson);
      await prefs.setStringList('accounts', accounts);
      print("ansaf${3}");
    }

    print("storedAccounts${accounts.length}");
  }

  /// Retrieves all stored user sessions

  Future<List<Map<String, dynamic>>> getStoredAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> accounts = prefs.getStringList('accounts') ?? [];

    return accounts
        .map((account) => jsonDecode(account) as Map<String, dynamic>)
        .toList();
  }

  /// Switches to a different stored account
  Future<void> switchAccount(Map<String, dynamic> accountData) async {
    final prefs = await SharedPreferences.getInstance();

    // Save selected account details as the active session
    await prefs.setString('url', accountData['url']);
    await prefs.setString('sessionId', accountData['sessionId']);
    await prefs.setString('selectedDatabase', accountData['dbName']);
    await prefs.setString('serverVersion', accountData['serverVersion']);
    await prefs.setString('userLang', accountData['userLang']);
    await prefs.setInt('userId', accountData['userId']);
    await prefs.setInt('companyId', accountData['companyId']);
    await prefs.setString('userLogin', accountData['userLogin']);
    await prefs.setString('userName', accountData['userName']);
    await prefs.setInt('partnerId', accountData['partnerId']);
    await prefs.setBool('isSystem', accountData['isSystem']);
    await prefs.setStringList(
        'allowedCompanies', accountData['allowedCompanies'].cast<String>());

    // Reinitialize the client with the new session
    await initializeOdooClient();
  }

  /// Fetches user profile and updates UI
  Future<void> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final client = _client;
    print("profileclient$client");
    if (client == null) {
      print("OdooClient not initialized yet");
      return;
    }
    final response = await client.callKw({
      'model': 'res.company',
      'method': 'read',
      'args': [
        [1]
      ],
      'kwargs': {
        'fields': ['logo']
      },
    });
    int userId = prefs.getInt('userId') ?? 0;
    final companyLogo = response[0]['logo'];

    if (companyLogo != null && companyLogo != 'false') {
      final imageData = base64Decode(companyLogo);
      companyPicUrl = MemoryImage(Uint8List.fromList(imageData));
    }

    try {
      final userDetails = await client.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', userId]
          ]
        ],
        'kwargs': {
          'fields': ['name', 'phone', 'email', 'image_1920'],
        },
      });
      _userdetails = userDetails;

      if (userDetails != null && userDetails.isNotEmpty) {
        final user = userDetails[0];

        _userInfo = user;

        print('profileclientttttt$user');

        final imageBase64 = user['image_1920'].toString();
        if (imageBase64.isNotEmpty && imageBase64 != 'false') {
          final imageData = base64Decode(imageBase64);
          _profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
        }
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> clear() async {
    _userInfo = {};
    _profilePicUrl = null;
    companyPicUrl = null;

    notifyListeners();
  }

  /// Logs out the user
  Future<void> signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('url');
    await prefs.remove('sessionId');
    await prefs.remove('selectedDatabase');
    await prefs.remove('serverVersion');
    await prefs.remove('userLang');
    await prefs.remove('userId');
    await prefs.remove('companyId');
    await prefs.remove('isLoggedIn');
//prefs.clear();
    _client = null;
    _currentsession = null;
    _userdetails = null;
    _userInfo = {};
    _profilePicUrl = null;
    companyPicUrl = null;
    isLoading = true;
    notifyListeners();

    // Delay navigation slightly to ensure UI updates before switching screens
    Future.delayed(Duration(milliseconds: 500), () {
      Navigator.pushNamedAndRemoveUntil(
          context, '/login', (Route<dynamic> route) => false);
    });
  }
}
