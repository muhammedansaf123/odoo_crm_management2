import 'dart:async';
import 'dart:developer';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:provider/provider.dart';

class OpportunityListProvider extends ChangeNotifier {
  String url = "";
  List<Map<String, dynamic>> opportunities = [];
  bool isSearching = false;
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  String searchText = '';
  String selectedOption = '';
  String valueStatus = '';
  int? selectedSalespersonId;
  List<Map<String, dynamic>> salesPersonDetails = [];
  List<Map<String, dynamic>> salesTeamDetails = [];
  List<Map<String, dynamic>> crmTagDetails = [];
  Map<String, dynamic>? selectedSalesperson;
  Map<String, dynamic>? selectedSalesTeam;
  List<Map<String, dynamic>> selectedCRMTags = [];
  int? selectedPriority;
  final int limit = 20;
  bool hasMoreData = true;
  int offset = 0;
  Timer? _debounce;

  ScrollController scrollController = ScrollController();

  Future<void> initializeopportunitylist(BuildContext context) async {
    scrollController.addListener(_scrollListener);
    final clinetprovider =
        Provider.of<OdooClientManager>(context, listen: false);

    await getOpportunities(context: context);
    await getSalesPerson(clinetprovider.client!);
    await getSalesTeam(clinetprovider.client!);
    await getTags(clinetprovider.client!, context);
  }

  void _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange &&
        !isLoading &&
        hasMoreData) {
      print("isLoading = false;isLoading = false;");
      //   getOpportunities(fromScroll: true);
    }
  }

  void controllerdispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
  }

  Future<void> getSalesPerson(OdooClient client) async {
    try {
      final response = await client?.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      salesPersonDetails = List<Map<String, dynamic>>.from(response ?? []);
      notifyListeners();
    } catch (e) {
      print('Error fetching salespersons: $e');
    }
  }

  Future<void> getSalesTeam(OdooClient client) async {
    try {
      final response = await client?.callKw({
        'model': 'crm.team',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      salesTeamDetails = List<Map<String, dynamic>>.from(response ?? []);
      notifyListeners();
    } catch (e) {
      print('Error fetching salespersons: $e');
    }
  }

  Future<void> getTags(OdooClient client, BuildContext) async {
    try {
      final response = await client?.callKw({
        'model': 'crm.tag',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      crmTagDetails = List<Map<String, dynamic>>.from(response ?? []);
      notifyListeners();
    } catch (e) {
      print('Error fetching salespersons: $e');
    }
  }

  Future<void> getOpportunities({
    bool fromScroll = false,
    BuildContext? context,
  }) async {
    log("print1");
    isLoading = true;

    final clientprovider =
        Provider.of<OdooClientManager>(context!, listen: false);
    final client = clientprovider.client;

    try {
      log("print2");

      final List<dynamic> filters = [
        ['type', '=', 'opportunity'],
        [
          'active',
          '=',
          [true, false]
        ]
      ];

      if (selectedSalesperson != null) {
        filters.add(['user_id', '=', selectedSalesperson!['id']]);
      }
      if (selectedSalesTeam != null) {
        filters.add(['team_id', '=', selectedSalesTeam!['id']]);
      }
      if (selectedPriority != null) {
        filters.add(['priority', '=', selectedPriority]);
      }
      if (selectedCRMTags.isNotEmpty) {
        List<int> selectedIds =
            selectedCRMTags.map((tag) => tag['id'] as int).toList();
        filters.add(['tag_ids', 'in', selectedIds]);
      }
      if (searchText.isNotEmpty) {
        filters.add('|');
        filters.add(['name', 'ilike', searchText]);
        filters.add(['team_id', 'ilike', searchText]);
      }

      log("print3");

      final opportunityDetails = await client?.callKw({
        'model': 'crm.lead',
        'method': 'search_read',
        'args': [filters],
        'kwargs': {
          'fields': [
            'name',
            'phone',
            'mobile',
            'email_from',
            'city',
            'country_id',
            'team_id',
            'user_id',
            'probability',
            'partner_id',
            'priority',
            'tag_ids',
            'date_open',
            'date_closed',
            'description',
            'contact_name',
            'active',
            'stage_id'
          ],
        },
      });

      if (opportunityDetails != null && opportunityDetails is List) {
        log("print4");

        /// ✅ **Call Separate Mapping Function**
        List<Map<String, dynamic>> updatedOpportunities =
            mapOpportunitiesimagesnull(opportunityDetails);

        if (offset != 0 || searchText.isEmpty) {
          log("print8");
          opportunities = updatedOpportunities;
        } else {
          log("print9");
          opportunities = updatedOpportunities;
        }

        log("print10");
        opportunities = opportunities.toSet().toList();
        isLoading = false;
        notifyListeners();

        if (searchText.isEmpty) {
          log("print11");
          offset += limit;
        }
      } else {
        log("print12");
        hasMoreData = false;
        isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      log("Error fetching opportunities: $e");
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ **Extracted Function for Mapping Opportunities**
  List<Map<String, dynamic>> mapOpportunitiesimagesnull(
      List<dynamic> opportunityDetails) {
    List<Map<String, dynamic>> updatedOpportunities = [];

    for (var opportunity in opportunityDetails) {
      log("print5");

      // Placeholder for user image, can be updated later if needed
      opportunity['user_image'] = null;

      updatedOpportunities.add(opportunity as Map<String, dynamic>);
    }

    return updatedOpportunities;
  }

  void showfilterbottom(BuildContext context) {
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
                      items: salesPersonDetails,
                      dropdownDecoratorProps: const DropDownDecoratorProps(
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
                        selectedSalesperson = value;
                        notifyListeners();
                      },
                      selectedItem: selectedSalesperson,
                      compareFn: (item1, item2) => item1['id'] == item2['id'],
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
                      items: salesTeamDetails,
                      dropdownDecoratorProps: const DropDownDecoratorProps(
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
                        selectedSalesTeam = value;
                        notifyListeners();
                        print('Selected Sales Team: $value');
                      },
                      selectedItem: selectedSalesTeam,
                      compareFn: (item1, item2) => item1['id'] == item2['id'],
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
                      dropdownDecoratorProps: const DropDownDecoratorProps(
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
                                (index) =>
                                    Icon(Icons.star, color: Colors.yellow[900]),
                              ),
                            ),
                          );
                        },
                      ),
                      items: [1, 2, 3],
                      selectedItem: selectedPriority,
                      dropdownBuilder: (context, selectedItem) {
                        if (selectedItem != null) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              selectedItem,
                              (index) =>
                                  Icon(Icons.star, color: Colors.yellow[900]),
                            ),
                          );
                        } else {
                          return const Text('Select Priority');
                        }
                      },
                      onChanged: (value) {
                        selectedPriority = value;
                        notifyListeners();
                      },
                    ),
                    const SizedBox(height: 20),
                    MultiSelectDropdown.simpleList(
                      list: crmTagDetails.map((e) => e['name']).toList(),
                      initiallySelected:
                          selectedCRMTags.map((e) => e['name']).toList(),
                      onChange: (selectedItems) {
                        List<Map<String, dynamic>> selectedMapItems = [];
                        for (var item in selectedItems) {
                          var matchingItem = crmTagDetails.firstWhere(
                            (tag) => tag['name'] == item,
                            orElse: () => {},
                          );
                          if (matchingItem.isNotEmpty) {
                            selectedMapItems.add(matchingItem);
                          }
                        }

                        selectedCRMTags.clear();
                        selectedCRMTags.addAll(selectedMapItems);
                        notifyListeners();
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
                        getOpportunities(context: context);
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
  }
}
