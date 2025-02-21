import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/lead/providers/lead_form_provider.dart';
import 'package:odoo_crm_management/models/models.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final controller = MultiSelectController<LeadItem>();

  /// ✅ List to store manually selected items
  List<LeadItem> _selectedLeads = [];

  @override
  Widget build(BuildContext context) {
    return Consumer<OdooClientManager>(builder: (context, provider, child) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 4),
                 

                  /// ✅ MultiDropdown without built-in selection
                  MultiDropdown<LeadItem>(
                    items: provider.dropdownItems,
                    itemBuilder: (item, index, onTap) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLeads.add(item.value);
                          });
                          print(_selectedLeads);
                        },
                        child: OpportunityTile(
                          close: false,
                          onPressed: () {},
                          createdOn: item.value.createdon ?? "N/a",
                          opportunity: item.value.name ?? "N/a",
                          contactName: item.value.contactname ?? "N/a",
                          email: item.value.email ?? "N/a",
                          stage: item.value.stage ?? "N/a",
                          salesperson: item.value.salesperson ?? "N/a",
                        ),
                      );
                    },
                    selectedItemBuilder: (item) {
                      return SizedBox(
                        child: Text(
                            "number of item selected ${_selectedLeads.length}"),
                      );
                    },
                    controller: controller,
                    searchEnabled: true,
                    dropdownDecoration: const DropdownDecoration(
                    
                      maxHeight: 600, // Increased height to show more items
                      header: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Select Leads',
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// ✅ Show Selected Items Separately
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class MyHomePagee extends StatefulWidget {
  const MyHomePagee({Key? key}) : super(key: key);

  @override
  State<MyHomePagee> createState() => _MyHomePageeState();
}

class User {
  final String name;
  final int id;

  User({required this.name, required this.id});

  @override
  String toString() {
    return 'User(name: $name, id: $id)';
  }
}

class _MyHomePageeState extends State<MyHomePagee> {
  final _formKey = GlobalKey<FormState>();

  final controller = MultiSelectController<LeadItem>();

  @override
  Widget build(BuildContext context) {
    return Consumer<OdooClientManager>(builder: (context, provider, child) {
      return Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 500,
              child: Center(
                child: MultiDropdown<LeadItem>(
                  items: provider.dropdownItems,
                  itemBuilder: (item, index, onTap) {
                    return GestureDetector(
                      onTap: onTap,
                      child: OpportunityTile(
                        close: false,
                        onPressed: () {},
                        createdOn: item.value.createdon ?? "N/a",
                        opportunity: item.value.name ?? "N/a",
                        contactName: item.value.contactname ?? "N/a",
                        email: item.value.email ?? "N/a",
                        stage: item.value.stage ?? "N/a",
                        salesperson: item.value.salesperson ?? "N/a",
                      ),
                    );
                  },
                  controller: controller,
                  enabled: true,
                  searchEnabled: true,
                  selectedItemBuilder: (item) {
                    return SizedBox();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a country';
                    }
                    return null;
                  },
                  onSelectionChange: (selectedItems) {
                    debugPrint("OnSelectionChange: $selectedItems");
                  },
                ),
              ),
            ),
          ));
    });
  }
}
