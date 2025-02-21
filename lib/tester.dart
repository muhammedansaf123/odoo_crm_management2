import 'package:flutter/material.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:provider/provider.dart';

class SomeWidget extends StatefulWidget {
  @override
  _SomeWidgetState createState() => _SomeWidgetState();
}

class _SomeWidgetState extends State<SomeWidget> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<OdooClientManager>(context, listen: false);
    _future = provider.initializeOdooClient();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final provider = Provider.of<OdooClientManager>(context);
        if (provider.currentsession == null) {
          return const Center(child: Text('Failed to initialize session'));
        }

        return Scaffold(
          body: Center(
              child: Text('Logged in as ${provider.currentsession!.userName}')),
        );
      },
    );
  }
}
