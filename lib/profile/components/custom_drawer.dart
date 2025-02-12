import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:provider/provider.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Consumer<OdooClientManager>(builder: (context, provider, child) {
      return Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade800, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              const DrawerHeader(
                child: Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.purple),
                  ),
                ),
              ),
              CustomDrawerTile(
                icon: Icons.logout,
                title: "Sign Out",
                onTap: () {
                  setState(() {
                    OdooClientManager odooClientManager = OdooClientManager();
                    odooClientManager.signOut(context);
                  });
                },
              ),
              if (provider.storedaccounts.length >= 2) ...[
                const CustomExpansiontile(),
              ],
              CustomDrawerTile(
                icon: Icons.person_add,
                title: "Add Account",
                onTap: () {
                  Navigator.pushNamed(context, '/switch_account');
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class CustomDrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final void Function()? onTap;
  const CustomDrawerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero, // Remove default padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomExpansiontile extends StatelessWidget {
  const CustomExpansiontile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OdooClientManager>(builder: (context, provider, child) {
      return Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          childrenPadding: EdgeInsets.zero,
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          leading: const Icon(Icons.switch_account, color: Colors.white),
          title: const Text(
            "Switch Accounts",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Column(
              children: provider.storedaccounts
                  .where((item) =>
                      item["userId"] != provider.currentsession!.userId)
                  .map((item) {
                final imageData = base64Decode(item['imageurl']);

                return Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: ClipOval(
                      child: Image(
                        image: MemoryImage(Uint8List.fromList(imageData)),
                        fit: BoxFit.cover,
                        width: 50.0,
                        height: 50.0,
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 54,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                    title: Text(
                      item['userName'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(context,
                          '/loading_screen', (Route<dynamic> route) => false);
                      provider.odooSwitchAccount(
                          provider.storedaccounts.indexOf(item), context);
                    },
                    hoverColor: Colors.purple.shade400,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}
