import 'package:flutter/material.dart';
import 'package:odoo_crm_management/auth.dart';
import 'package:odoo_crm_management/dashboard/provider/dashboard_provider.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/lead/providers/lead_form_provider.dart';
import 'package:odoo_crm_management/lead/providers/lead_list_provider.dart';
import 'package:odoo_crm_management/loading_screen.dart';
import 'package:odoo_crm_management/opportunity/opportunity_form_provider.dart';
import 'package:odoo_crm_management/opportunity/opportunity_list_provider.dart';
import 'package:odoo_crm_management/profile/switch_account.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences package
import 'package:odoo_crm_management/profile/profile.dart';
import 'package:odoo_crm_management/sales/sales_team.dart';
import 'calendar/calendar.dart';
import 'dashboard/dashboard.dart';
import 'discuss/discuss.dart';
import 'discuss/discuss_channel.dart';
import 'lead/lead_list.dart';
import 'login/login.dart';
import 'opportunity/opportunity_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  print("login $isLoggedIn");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => OdooClientManager()),
        ChangeNotifierProvider(create: (context) => LeadFormProvider()),
        ChangeNotifierProvider(create: (context) => DashboardProvider()),
        ChangeNotifierProvider(create: (context) => LeadListProvider()),
        ChangeNotifierProvider(create: (context) => OpportunityFormProvider()),
        ChangeNotifierProvider(create: (context) => OpportunityListProvider()),
      ],
      child: MyApp(
        isLoggedIn: isLoggedIn,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Page',
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Use the isLoggedIn flag to set the initial route
      routes: {
        '/': (context) => const AuthCheck(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const Dashboard(),
        '/profile': (context) => const Profile(),
        '/lead': (context) => const Lead(),
        '/opportunity': (context) => const Opportunity(),
        '/sales_team': (context) => const SalesTeam(),
        '/calendar': (context) => Calendar(),
        '/discuss': (context) => const Discuss(),
        '/discuss_channel': (context) => const DiscussChannel(),
        '/switch_account': (context) => const SwitchAccountLogin(),
        '/loading_screen': (context) => LoadingScreen(),
      },
    );
  }
}
