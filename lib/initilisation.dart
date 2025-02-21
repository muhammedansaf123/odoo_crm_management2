import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:odoo_crm_management/models/models.dart';

import 'package:odoo_rpc/odoo_rpc.dart';

import 'package:shared_preferences/shared_preferences.dart';

class OdooClientManager extends ChangeNotifier {
  OdooClient? _client;
  String? _url;
  List<LeadItem> _leadItems = [];
  List<CustomerItem> _customerItems = [];
  List<SalesPersonItem> _salesPersonItems = [];
  MemoryImage? _profilePicUrl;
  MemoryImage? get profilePicUrl => _profilePicUrl;
  MemoryImage? companyPicUrl;
  OdooSession? _currentsession;
  OdooClient? get client => _client;
  dynamic _userdetails;
  OdooSession? get currentsession => _currentsession;
  List<LeadItem> get leadItems => _leadItems;
  List<CustomerItem> get customerItems => _customerItems;
  List<SalesPersonItem> get salesPersonItem => _salesPersonItems;
  dynamic get userDetails => _userdetails;
  Map<String, dynamic> _userInfo = {};
  Map<String, dynamic> get userInfo => _userInfo;
  String? get url => _url;
  bool? isLoading = true;
  List<Map<String, dynamic>> storedaccounts = [];

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

    // Convert allowedCompanies list to JSON
    List<Map<String, dynamic>> allowedCompaniesJson =
        session.allowedCompanies.map((company) => company.toJson()).toList();

    await prefs.setString('allowedCompanies', jsonEncode(allowedCompaniesJson));
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
    String? jsonString = prefs.getString('allowedCompanies');
    List<dynamic> jsonList = jsonDecode(jsonString!);
    List<Company> allowedCompanies =
        jsonList.map((json) => Company.fromJson(json)).toList();

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
    _url = url;

    getUserProfile();
    getInstalledModules();
  }

  void odooSwitchAccount(int index, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String url = prefs.getString('url') ?? '';
    _client = OdooClient(url);
    final logindata = storedaccounts[index];
    var session = await _client!.authenticate(
      logindata['dbName'],
      logindata['user'],
      logindata['password'],
    );

    await clear();

    await updateSession(session);

    _currentsession = session;
    _client = OdooClient(url, session);
  }

  /// Stores session details for multiple logged-in users
  Future<void> storeUserSession(
      OdooSession session,
      String url,
      String password,
      String username,
      BuildContext context,
      bool login) async {
    final prefs = await SharedPreferences.getInstance();
    final client = _client;

    if (client == null) {
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
    log(response);
    int userId = prefs.getInt('userId') ?? 0;

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
        // Retrieve existing accounts
        List<String> accounts = prefs.getStringList('accounts') ?? [];

        // Decode stored accounts into a list of maps
        List<Map<String, dynamic>> storedAccounts = accounts
            .map((account) => jsonDecode(account) as Map<String, dynamic>)
            .toList();

        // Check if the user already exists in stored accounts
        bool userExists = storedAccounts
            .any((account) => account['userId'] == session.userId);

        if (!userExists) {
          // Create user session data

          Map<String, dynamic> userData = {
            'url': url,
            'dbName': session.dbName,
            'imageurl': imageBase64,
            'password': password,
            'userName': session.userName,
            'user': username,
            'userId': session.userId
          };

          // Convert userData to JSON string and store it
          String userJson = jsonEncode(userData);
          accounts.add(userJson);
          await prefs.setStringList('accounts', accounts);

          if (login == true) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/loading_screen', (Route<dynamic> route) => false);
          }
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("User Already exists")));
        }
      }
    }
  }

  void setstoreddata() async {
    storedaccounts = await getStoredAccounts();

    notifyListeners();
  }

  /// Retrieves all stored user sessions
  Future<List<Map<String, dynamic>>> getStoredAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> accounts = prefs.getStringList('accounts') ?? [];

    return accounts
        .map((account) => jsonDecode(account) as Map<String, dynamic>)
        .toList();
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
    storedaccounts = [];
  }

  Future<void> getCrmLead() async {
    _leadItems.clear();

    final leadDetails = await client!.callKw({
      'model': 'crm.lead',
      'method': 'search_read',
      'args': [[]],
      'kwargs': {
        'fields': [
          'name',
          'user_id',
          'email_from',
          'create_date',
          'stage_id',
          'partner_id'
        ],
      },
    });

    // log(leadDetails.toString());

    if (leadDetails != null && leadDetails is List) {
      for (var item in leadDetails) {
        _leadItems.add(
          LeadItem(
              contactname:
                  item['partner_id'] == false ? null : item['partner_id'][1],
              id: item['id'],
              name: item['name'],
              email: item['email_from'] == false ? null : item['email_from'],
              createdon: item['create_date'],
              salesperson: item['user_id'] == false ? null : item['user_id'][1],
              stage: item['stage_id'][1]),
        );
      }
    }

    //log(_leadItems[0].toString());

    final customerDetails = await client!.callKw({
      'model': 'res.partner',
      'method': 'search_read',
      'args': [[]],
      'kwargs': {
        'fields': ['name'],
      },
    });

    if (customerDetails != null && customerDetails is List) {
      for (var item in customerDetails) {
        _customerItems.add(
          CustomerItem(
            id: item['id'],
            name: item['name'],
          ),
        );
      }
    }
    log("ansaf$leadItems");
    log("ansaf$customerItems");
  }
Future<void> getSalesTeamsAndSalesperson() async {
    try {
      _salesPersonItems.clear();
      // Fetch Salespersons
      final salesPersonResponse = await client!.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'fields': ['name', 'sale_team_id'],
        },
      });

      if (salesPersonResponse != null && salesPersonResponse is List) {
        for (var item in salesPersonResponse) {
          if (item['sale_team_id'] != false && item['sale_team_id'] is List) {
            _salesPersonItems.add(
              SalesPersonItem(
                teamName: item['sale_team_id'][1],
                teamid: item['sale_team_id'][0], // Fixed key name
                id: item['id'],
                name: item['name'],
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching sales teams or salesperson: $e');
    }
  }
  /// Logs out the user
  Future<void> signOut(BuildContext context) async {
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (Route<dynamic> route) => false);

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('sessionId');
    await prefs.remove('serverVersion');
    await prefs.remove('userLang');
    await prefs.remove('userId');
    await prefs.remove('companyId');
    await prefs.remove('isLoggedIn');
    await prefs.remove('accounts');
    //  prefs.clear();
    _client = null;

    _currentsession = null;
    _userdetails = null;
    _userInfo = {};
    _profilePicUrl = null;
    companyPicUrl = null;
    isLoading = true;

    notifyListeners();
  }

  Future<void> getInstalledModules() async {
    try {
      final res = await _client!.callKw({
        'model': 'ir.module.module',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            ['state', '=', 'installed']
          ],
          'fields': ['name', 'shortdesc', 'application'],
          'limit': 50, // Adjust as needed
        },
      });

      log(res.toString()); // List of installed modules
    } catch (e) {
      print('Error: $e');
    }
  }
}
