import 'package:flutter/material.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/profile/components/custom_drawer.dart';

import 'package:provider/provider.dart';

import 'package:shimmer/shimmer.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  int? userId;

  String url = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      endDrawer: const CustomDrawer(),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
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
          child:
              Consumer<OdooClientManager>(builder: (context, provider, child) {
            return Column(
              children: [
                provider.isLoading!
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
                            image: provider.profilePicUrl != null
                                ? provider.profilePicUrl!
                                : const AssetImage('assets/profile.jpg')
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                const SizedBox(height: 40),
                provider.isLoading!
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
                        provider.userInfo.isNotEmpty
                            ? provider.userInfo['name'] ?? 'No Name'
                            : 'No Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                const SizedBox(height: 20),
                // Shimmer effect for user email
                provider.isLoading!
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
                        provider.userInfo.isNotEmpty
                            ? provider.userInfo['email'] ?? 'No Email'
                            : 'No Email',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                const SizedBox(height: 10),
                provider.isLoading!
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
                        provider.userInfo.isNotEmpty
                            ? provider.userInfo['phone'] ?? 'No Phone'
                            : 'No Phone',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 32.0),
                  child: provider.isLoading!
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
                          provider.userInfo.isNotEmpty
                              ? provider.userInfo.containsKey('Address')
                                  ? provider.userInfo['Address'] ?? 'No Address'
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 80.0, horizontal: 32.0),
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
            );
          }),
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
