import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:odoo_crm_management/dashboard/dashboard_drawer.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/lead/providers/lead_form_provider.dart';
import 'package:odoo_crm_management/lead/providers/lead_list_provider.dart';

import 'package:provider/provider.dart';

import 'package:shimmer/shimmer.dart';
import 'lead_form.dart';

class Lead extends StatefulWidget {
  const Lead({super.key});

  @override
  State<Lead> createState() => _LeadState();
}

class _LeadState extends State<Lead> {
  @override
  void initState() {
    super.initState();

    Provider.of<LeadListProvider>(context, listen: false).init(context);
  }

  Timer? _debounce;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeadListProvider>(builder: (context, provider, child) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          leading: IconButton(
              onPressed: () {
                _scaffoldKey.currentState!.openDrawer();
              },
              icon: const Icon(Icons.menu)),
          title: provider.isSearching
              ? TextField(
                  controller: provider.searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white),
                    border: InputBorder.none,
                  ),
                  onChanged: (query) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      provider.timer(query, context);
                    });
                    // setState(() {
                    //   searchText = query;
                    // });
                    // getLeads();
                  },
                )
              : const Text(
                  'Leads',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          backgroundColor: Colors.purple,
          automaticallyImplyLeading: false,
          actions: [
            if (!provider.isSearching)
              IconButton(
                icon: const Icon(
                  Icons.tune,
                  color: Colors.white,
                ),
                onPressed: () {
                  provider.showfilterbottom(context);
                },
              ),
            if (!provider.isSearching)
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  provider.setIsearch();
                },
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white,
                ),
                onPressed: () {
                  provider.clearText(context);
                },
              )
          ],
        ),
        drawer: const DashboardDrawer(
          currentroute: 'leads',
        ),
        body: provider.isLoading
            ? Row(
                children: [
                  Expanded(
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 30,
                              ),
                              title: Container(
                                width: 200,
                                height: 15,
                                color: Colors.white,
                              ),
                              subtitle: Container(
                                width: 250,
                                height: 10,
                                color: Colors.white,
                              ),
                              trailing: Container(
                                width: 80,
                                height: 10,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              )
            : provider.leads.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/lead.png',
                            width: 92,
                            height: 92,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "There are no Leads available to display",
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: provider.scrollController,
                    itemCount: provider.leads.length,
                    itemBuilder: (context, index) {
                      final lead = provider.leads[index];
                      return Stack(
                        children: [
                          Consumer2<LeadFormProvider, OdooClientManager>(
                              builder:
                                  (context, provider, odooinitprovider, child) {
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: ListTile(
                                leading: ClipOval(
                                  // Make the image circular
                                  child: (lead['user_id'] == null ||
                                          lead['user_id'] == false)
                                      ? Image.asset(
                                          "assets/profile.jpg",

                                          width: 50, // Customize image size
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.person,
                                                size: 100, color: Colors.grey);
                                          },
                                        )
                                      : Image.network(
                                          "https://muhammed-ansaf1.odoo.com/web/image/res.users/${lead['user_id'][0]}/avatar_1920",
                                          headers: {
                                            "Cookie":
                                                "session_id=${odooinitprovider.currentsession!.id}", // Attach session for auth
                                          },
                                          width: 50, // Customize image size
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.person,
                                                size: 100, color: Colors.grey);
                                          },
                                        ),
                                ),
                                title: Text(
                                  lead['name'] ?? 'No Name',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                    'Email: ${lead['email_from'] ?? 'N/A'}\nCity: ${lead['city'] ?? 'N/A'}'),
                                trailing: Text(
                                  (lead['team_id'] is List &&
                                          lead['team_id'].length > 1)
                                      ? lead['team_id'][1]
                                      : '',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal),
                                ),
                                onTap: () {
                                  provider.clear();
                                  provider.fetchStatus(
                                      odooinitprovider.client!, lead);
                                  print(lead['id']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LeadFormView(
                                        lead: lead,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                          if (lead['active'] == null || lead['active'] == false)
                            Positioned(
                              top: -5,
                              right: -2,
                              child: SizedBox(
                                  height: 90,
                                  width: 90,
                                  child: SvgPicture.asset(
                                    "assets/lost.svg",
                                  )),
                            ),
                        ],
                      );
                    },
                  ),
      );
    });
  }
}
