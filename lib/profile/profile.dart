import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  int? userId;
  OdooClient? client;
  String url = "";
  MemoryImage? profilePicUrl;
  MemoryImage? companyPicUrl;
  List<Map<String, String>> userDetailsList = [];
  String? companyLogo;
  bool isLoading = true;

  @override
  void initState() {
    print("4444444444444444dddddddddddddddd");
    super.initState();
    _initializeOdooClient();
  }

  Future<void> profileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      userId = prefs.getInt('userId') ?? 0;
      print(prefs.getString("company_logo"));
      print("companyLogocompanyLogocompanyLogo");
      companyLogo = prefs.getString("company_logo");
      if (companyLogo != null && companyLogo != 'false') {
        final imageData = base64Decode(companyLogo!);
        setState(() {
          companyPicUrl = MemoryImage(Uint8List.fromList(imageData));
        });
      }
      final userDetails = await client?.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', userId]
          ]
        ],
        'kwargs': {
          'fields': [
            'name',
            'phone',
            'contact_address_complete',
            'email',
            'image_1920'
          ],
        },
      });
      if (userDetails != null && userDetails.isNotEmpty) {
        final user = userDetails[0];
        final imageBase64 =
            user['image_1920'] is String ? user['image_1920'] : null;
        if (imageBase64 != null && imageBase64 != 'false') {
          final imageData = base64Decode(imageBase64);
          setState(() {
            profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
          });
        }
        List<Map<String, String>> userInfo = [
          {'Name': user['name'] ?? 'N/A'},
          {'Email': user['email'] ?? 'N/A'},
          {'Phone': user['phone'] ?? 'N/A'},
          {'Address': user['contact_address_complete'] ?? 'N/A'},
        ];

        setState(() {
          userDetailsList = userInfo;
          isLoading = false;
        });
        print(userDetailsList);
        print("userDetailsuserDetails");
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }



  Future<void> _initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    url = prefs.getString('url') ?? '';
    final db = prefs.getString('selectedDatabase') ?? '';
    final sessionId = prefs.getString('sessionId') ?? '';
    final serverVersion = prefs.getString('serverVersion') ?? '';
    final userLang = prefs.getString('userLang') ?? '';
    final companyId = prefs.getInt('companyId');
    final allowedCompaniesStringList =
        prefs.getStringList('allowedCompanies') ?? [];
    List<Company> allowedCompanies = [];

    if (allowedCompaniesStringList.isNotEmpty) {
      allowedCompanies = allowedCompaniesStringList
          .map((jsonString) => Company.fromJson(jsonDecode(jsonString)))
          .toList();
    }
    if (url == null || db.isEmpty || sessionId.isEmpty) {
      throw Exception('URL, database, or session details not set');
    }

    final session = OdooSession(
      id: sessionId,
      userId: prefs.getInt('userId') ?? 0,
      partnerId: prefs.getInt('partnerId') ?? 0,
      userLogin: prefs.getString('userLogin') ?? '',
      userName: prefs.getString('userName') ?? '',
      userLang: userLang,
      userTz: '',
      isSystem: prefs.getBool('isSystem') ?? false,
      dbName: db,
      serverVersion: serverVersion,
      companyId: companyId ?? 1,
      allowedCompanies: allowedCompanies,
    );

    client = OdooClient(url!, session);
    profileData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: double.infinity,
                        height: 300,
                        color: Colors.white,
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: profilePicUrl != null
                              ? profilePicUrl!
                              : AssetImage('assets/profile.jpg')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
              const SizedBox(height: 40),
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 150,
                        height: 20,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      userDetailsList.isNotEmpty
                          ? userDetailsList[0]['Name'] ?? 'No Name'
                          : 'No Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              const SizedBox(height: 20),
              // Shimmer effect for user email
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 200,
                        height: 20,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      userDetailsList.isNotEmpty
                          ? userDetailsList[1]['Email'] ?? 'No Email'
                          : 'No Email',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
              const SizedBox(height: 10),
              isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 150,
                        height: 20,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      userDetailsList.isNotEmpty
                          ? userDetailsList[2]['Phone'] ?? 'No Phone'
                          : 'No Phone',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                child: isLoading
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: double.infinity,
                          height: 20,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        userDetailsList.isNotEmpty
                            ? userDetailsList[3].containsKey('Address')
                                ? userDetailsList[3]['Address'] ?? 'No Address'
                                : 'No Address'
                            : 'No Address',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[600],
                        ),
                      ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 80.0, horizontal: 32.0),
                child: Column(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatsItem extends StatelessWidget {
  final String label;
  final String count;

  const StatsItem({super.key, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
