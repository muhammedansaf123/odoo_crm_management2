import 'package:flutter/material.dart';
import 'package:odoo_crm_management/profile/profile.dart';
import 'package:odoo_crm_management/sales/sales_team.dart';

import 'calendar/calendar.dart';
import 'dashboard/dashboard.dart';
import 'discuss/discuss.dart';
import 'discuss/discuss_channel.dart';
import 'lead/lead_list.dart';
import 'login/login.dart';
import 'opportunity/opportunity_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Dashboard(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const Dashboard(),
        '/profile': (context) => const Profile(),
        '/lead': (context) => const Lead(),
        '/opportunity': (context) => const Opportunity(),
        '/sales_team': (context) => const SalesTeam(),
        '/calendar': (context) => Calendar(),
        '/discuss': (context) => const Discuss(),
        '/discuss_channel': (context) => const DiscussChannel(),
      },
    );
  }
}
