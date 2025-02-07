import 'package:flutter/material.dart';
import 'package:odoo_crm_management/initilisation.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.purple.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const DrawerHeader(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.purple),
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
            CustomDrawerTile(
              icon: Icons.switch_account,
              title: "Switch Account",
              onTap: () {
                // Handle Switch Account
              },
            ),
            CustomDrawerTile(
              icon: Icons.person_add,
              title: "Add Account",
              onTap: () {
                // Handle Add Account
              },
            ),
            const Spacer(),
            // const Padding(
            //   padding: EdgeInsets.only(bottom: 16.0),
            //   child: Text(
            //     "App Version 1.0.0",
            //     style: TextStyle(color: Colors.white70),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class CustomDrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final void Function()? onTap;
  const CustomDrawerTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      hoverColor: Colors.blue.shade300,
      onTap: onTap,
    );
  }
}
