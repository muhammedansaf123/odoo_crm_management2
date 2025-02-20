import 'package:flutter/material.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:provider/provider.dart';

class DashboardDrawer extends StatelessWidget {
  const DashboardDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.purple[300]),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 80,
                height: 80,
                child: Consumer<OdooClientManager>(
                    builder: (context, provider, child) {
                  return Container(
                    decoration: BoxDecoration(
                      image: provider.companyPicUrl != null
                          ? DecorationImage(
                              image: provider.companyPicUrl!,
                              // fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: provider.companyPicUrl == null
                        ? const Center(
                            child: Icon(
                              Icons.business,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  );
                }),
              ),
            ),
          ),
          ListTile(
            title: const Text('Leads',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            onTap: () {
              
              Navigator.pushNamed(context, '/lead');
            },
          ),
          ListTile(
            title: const Text('Opportunity',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            onTap: () {
              Navigator.pushNamed(context, '/opportunity');
            },
          ),
          ListTile(
            title: const Text('Sales Team',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            onTap: () {
              Navigator.pushNamed(context, '/sales_team');
            },
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 500.0, horizontal: 32.0),
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
    );
  }
}
