import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:odoo_crm_management/initilisation.dart';

import 'package:odoo_crm_management/opportunity/opportunity_form_provider.dart';
import 'package:odoo_crm_management/opportunity/opportunity_list_provider.dart';
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

  @override
  void initState() {
    super.initState();
    Provider.of<OpportunityListProvider>(context, listen: false)
        .initializeOdooClient(context);
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
        appBar: AppBar(
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
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.89,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Filter By: ',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownSearch<Map<String, dynamic>>(
                                    items: provider.salesPersonDetails,
                                    dropdownDecoratorProps:
                                        const DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Select Salesperson',
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: true,
                                      searchFieldProps: const TextFieldProps(
                                        decoration: InputDecoration(
                                          labelText: 'Search Salesperson',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      itemBuilder: (context, item, isSelected) {
                                        return ListTile(
                                          title: Text(item['name']),
                                        );
                                      },
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        provider.selectedSalesperson = value;
                                      });
                                    },
                                    selectedItem: provider.selectedSalesperson,
                                    compareFn: (item1, item2) =>
                                        item1['id'] == item2['id'],
                                    filterFn: (item, query) => item['name']
                                        .toLowerCase()
                                        .contains(query.toLowerCase()),
                                    dropdownBuilder: (context, selectedItem) {
                                      if (selectedItem != null) {
                                        return Text(selectedItem['name']);
                                      } else {
                                        return const Text('Select Salesperson');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownSearch<Map<String, dynamic>>(
                                    items: provider.salesTeamDetails,
                                    dropdownDecoratorProps:
                                        const DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Select Sales Team',
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: true,
                                      searchFieldProps: const TextFieldProps(
                                        decoration: InputDecoration(
                                          labelText: 'Search Sales Team',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      itemBuilder: (context, item, isSelected) {
                                        return ListTile(
                                          title: Text(item['name']),
                                        );
                                      },
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        provider.selectedSalesTeam = value;
                                      });
                                      print('Selected Sales Team: $value');
                                    },
                                    selectedItem: provider.selectedSalesTeam,
                                    compareFn: (item1, item2) =>
                                        item1['id'] == item2['id'],
                                    filterFn: (item, query) => item['name']
                                        .toLowerCase()
                                        .contains(query.toLowerCase()),
                                    dropdownBuilder: (context, selectedItem) {
                                      if (selectedItem != null) {
                                        return Text(selectedItem['name']);
                                      } else {
                                        return const Text('Select Sales Team');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownSearch<int>(
                                    dropdownDecoratorProps:
                                        const DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'Priorities',
                                      ),
                                    ),
                                    popupProps: PopupProps.menu(
                                      showSearchBox: false,
                                      itemBuilder: (context, item, isSelected) {
                                        return ListTile(
                                          leading: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(
                                              item,
                                              (index) => Icon(Icons.star,
                                                  color: Colors.yellow[900]),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    items: [1, 2, 3],
                                    selectedItem: provider.selectedPriority,
                                    dropdownBuilder: (context, selectedItem) {
                                      if (selectedItem != null) {
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                            selectedItem,
                                            (index) => Icon(Icons.star,
                                                color: Colors.yellow[900]),
                                          ),
                                        );
                                      } else {
                                        return const Text('Select Priority');
                                      }
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        provider.selectedPriority = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  MultiSelectDropdown.simpleList(
                                    list: provider.crmTagDetails
                                        .map((e) => e['name'])
                                        .toList(),
                                    initiallySelected: provider.selectedCRMTags
                                        .map((e) => e['name'])
                                        .toList(),
                                    onChange: (selectedItems) {
                                      List<Map<String, dynamic>>
                                          selectedMapItems = [];
                                      for (var item in selectedItems) {
                                        var matchingItem =
                                            provider.crmTagDetails.firstWhere(
                                          (tag) => tag['name'] == item,
                                          orElse: () => {},
                                        );
                                        if (matchingItem.isNotEmpty) {
                                          selectedMapItems.add(matchingItem);
                                        }
                                      }

                                      setState(() {
                                        provider.selectedCRMTags.clear();
                                        provider.selectedCRMTags
                                            .addAll(selectedMapItems);
                                      });
                                    },
                                    includeSearch: true,
                                    includeSelectAll: true,
                                    isLarge: false,
                                    numberOfItemsLabelToShow: 3,
                                    checkboxFillColor: Colors.grey,
                                    // boxDecoration: BoxDecoration(
                                    //   border: Border.all(),
                                    //   borderRadius: BorderRadius.circular(10),
                                    // ),
                                  ),
                                  const SizedBox(height: 30),
                                  ElevatedButton(
                                    onPressed: () {
                                      provider.getOpportunities();
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                    ),
                                    child: const Text(
                                      'Apply Filters',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
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
                    provider.getOpportunities();
                  });
                },
              )
          ],
        ),
        drawer: const CustomDrawer(),
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
            : provider.opportunities.isEmpty
                ? Expanded(
                    child: Center(
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
                                leading: CircleAvatar(
                                  backgroundImage: opportunity['user_image'] !=
                                          null
                                      ? MemoryImage(base64Decode(
                                          opportunity['user_image']))
                                      : AssetImage('assets/profile.jpg')
                                          as ImageProvider,
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
                              top: 5,
                              right: 9,
                              child: SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: SvgPicture.asset(
                                    "assets/lost.svg",
                                    color: Colors.red,
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
