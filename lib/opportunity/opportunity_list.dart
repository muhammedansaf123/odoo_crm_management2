import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:odoo_crm_management/dashboard/dashboard_drawer.dart';

import 'package:odoo_crm_management/initilisation.dart';

import 'package:odoo_crm_management/opportunity/providers/opportunity_form_provider.dart';
import 'package:odoo_crm_management/opportunity/providers/opportunity_list_provider.dart';
import 'package:odoo_crm_management/profile/components/custom_drawer.dart';

import 'package:provider/provider.dart';

import 'package:shimmer/shimmer.dart';

import 'opportunity_form.dart';

class Opportunity extends StatefulWidget {
  const Opportunity({super.key});

  @override
  State<Opportunity> createState() => _OpportunityState();
}

class _OpportunityState extends State<Opportunity> {
  int? userId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    Provider.of<OpportunityListProvider>(context, listen: false)
        .initializeopportunitylist(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OpportunityListProvider>(
        builder: (context, provider, child) {
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
                    setState(() {
                      provider.searchText = query;
                      provider.offset = 0;
                      provider.hasMoreData = true;
                      provider.searchText = query;
                      provider.getOpportunities(context: context);
                    });

                    // setState(() {
                    //
                    //   offset = 0;
                    //   hasMoreData = true;
                    //   opportunities = [];
                    //   searchText = query;
                    //   getOpportunities();
                    // });
                  },
                )
              : const Text(
                  'Opportunity',
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
                  setState(() {
                    provider.isSearching = true;
                  });
                },
              )
            else
              IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    provider.isSearching = false;
                    provider.searchController.clear();
                    provider.searchText = '';
                    provider.getOpportunities(context: context);
                  });
                },
              )
          ],
        ),
        drawer: const DashboardDrawer(
          currentroute: 'opportunity',
        ),
        body: provider.isLoading
            ? Shimmer.fromColors(
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
              )
            : provider.opportunities.isEmpty
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
                            style: const TextStyle(
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
                    itemCount: provider.opportunities.length,
                    itemBuilder: (context, index) {
                      final opportunity = provider.opportunities[index];
                      return Stack(
                        children: [
                          Consumer2<OpportunityFormProvider, OdooClientManager>(
                              builder:
                                  (context, provider, odooinitprovider, child) {
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: ListTile(
                                leading: ClipOval(
                                  // Make the image circular
                                  child: (opportunity['user_id'] == null ||
                                          opportunity['user_id'] == false)
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
                                          "${odooinitprovider.url}web/image/res.users/${opportunity['user_id'][0]}/avatar_1920",
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
                                  opportunity['name'] ?? 'No Name',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                    'Email: ${opportunity['email_from'] ?? 'N/A'}\nCity: ${opportunity['city'] ?? 'N/A'}'),
                                trailing: Text(
                                  (opportunity['team_id'] is List &&
                                          opportunity['team_id'].length > 1)
                                      ? opportunity['team_id'][1]
                                      : '',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal),
                                ),
                                onTap: () {
                                  provider.clear();
                                  provider.fetchStatus(
                                      odooinitprovider.client!, opportunity);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OpportunityFormView(
                                        opportunity: opportunity,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                          if (opportunity['active'] == null ||
                              opportunity['active'] == false)
                            Positioned(
                                                          top: -5
                              ,
                              right: -2,
                              child: SizedBox(
                                  height: 90,
                                  width: 90,
                                  child: SvgPicture.asset(
                                    "assets/lost.svg",
                                  )),
                            ),
                          if (opportunity['stage_id'][0] == 4 &&
                              opportunity['active'] == true)
                            Positioned(
                              top: 5,
                              right: 8,
                              child: SizedBox(
                                  height: 70,
                                  width: 70,
                                  child: SvgPicture.asset(
                                    "assets/won.svg",
                                  )),
                            )
                        ],
                      );
                    },
                  ),
      );
    });
  }
}
