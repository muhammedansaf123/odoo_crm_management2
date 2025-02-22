import 'dart:async';
import 'dart:developer';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadListProvider extends ChangeNotifier {
  // Private variables with public getters
  int? _userId;

 final String _url = "";
  List<Map<dynamic, dynamic>> _leads = [];
  bool _isSearching = false;
  bool _isLoading = false;
  final TextEditingController searchController = TextEditingController();
  String _searchText = '';
 final String _selectedOption = '';
 final String _valueStatus = ''; List<Map<String, dynamic>> _crmTagDetails = [];
  int? _selectedSalespersonId;
  List<Map<String, dynamic>> _salesPersonDetails = [];
  List<Map<String, dynamic>> _salesTeamDetails = [];
 
  Map<String, dynamic>? _selectedSalesperson;
  Map<String, dynamic>? _selectedSalesTeam;
 final List<Map<String, dynamic>> _selectedCRMTags = [];
  int? _selectedPriority;
  final ScrollController _scrollController = ScrollController();
  final int _limit = 20;
  bool _hasMoreData = true;
  int _offset = 0;

  // Getters
  int? get userId => _userId;

  String get url => _url;
  List<Map<dynamic, dynamic>> get leads => _leads;

  bool get isLoading => _isLoading;

  String get selectedOption => _selectedOption;
  bool get isSearching => _isSearching;
  String get searchText => _searchText;
  String get valueStatus => _valueStatus;
  List<Map<String, dynamic>> get crmTagDetails => _crmTagDetails;
  int? get selectedSalespersonId => _selectedSalespersonId;
  List<Map<String, dynamic>> get salesPersonDetails => _salesPersonDetails;
  List<Map<String, dynamic>> get salesTeamDetails => _salesTeamDetails;
  Map<String, dynamic>? get selectedSalesperson => _selectedSalesperson;
  Map<String, dynamic>? get selectedSalesTeam => _selectedSalesTeam;
  List<Map<String, dynamic>> get selectedCRMTags => _selectedCRMTags;
  int? get selectedPriority => _selectedPriority;
  ScrollController get scrollController => _scrollController;
  int get limit => _limit;
  bool get hasMoreData => _hasMoreData;
  int get offset => _offset;

  /// Initialize the provider by fetching leads, salespersons, teams and tags.
  Future<void> init(BuildContext context) async {
    final client =
        Provider.of<OdooClientManager>(context, listen: false).client;
  
    await getLeads(context: context);
    await getSalesPerson(client!);
    await getSalesTeam(client);
    await getTags(client);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void clear() {
    leads.clear();
    notifyListeners();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !_isLoading &&
        _hasMoreData) {
      
      // Optionally call getLeads(fromScroll: true) here
      // getLeads(fromScroll: true);
    }
  }

  Future<void> getSalesPerson(OdooClient client) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    try {
      final response = await client.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      _salesPersonDetails = List<Map<String, dynamic>>.from(response ?? []);
      notifyListeners();
    } catch (e) {
      print('Error fetching salespersons: $e');
    }
  }

  void clearText(BuildContext context) {
    _isSearching = false;
    searchController.clear();
    _searchText = '';
    getLeads(context: context);
    notifyListeners();
  }

  void setIsearch() {
    _isSearching = true;
    notifyListeners();
  }

  void timer(String query, BuildContext context) {
    _searchText = query;
    _offset = 0;
    _hasMoreData = true;
    _searchText = query;
    getLeads(context: context);
    notifyListeners();
  }

  void salespersonSelect(dynamic value, String type) {
    if (type == "person") {
      _selectedSalesperson = value;
    } else if (type == "team") {
      _selectedSalesTeam = value;
    }

    notifyListeners();
  }

  Future<void> getSalesTeam(OdooClient client) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    try {
      final response = await client.callKw({
        'model': 'crm.team',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      _salesTeamDetails = List<Map<String, dynamic>>.from(response ?? []);
      notifyListeners();
    } catch (e) {
      print('Error fetching sales teams: $e');
    }
  }

  Future<void> getTags(OdooClient client) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    try {
      final response = await client.callKw({
        'model': 'crm.tag',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      _crmTagDetails = List<Map<String, dynamic>>.from(response ?? []);
      notifyListeners();
    } catch (e) {
      print('Error fetching tags: $e');
    }
  }

  Future<void> getLeads(
      {bool fromScroll = false, BuildContext? context}) async {
    if (!fromScroll) {
      _isLoading = true;
    }

    final clientprovider =
        Provider.of<OdooClientManager>(context!, listen: false);
    final client = clientprovider.client;
    _leads.clear();
    log("print1");

    final List<dynamic> filters = [
      ['type', '=', 'lead'],
      [
        'active',
        '=',
        [true, false],
      ],
    ];
    if (_selectedSalesperson != null) {
      log("print2");
      filters.add(['user_id', '=', _selectedSalesperson!['id']]);
    }
    if (_selectedSalesTeam != null) {
      log("print3");
      filters.add(['team_id', '=', _selectedSalesTeam!['id']]);
    }
    if (_selectedPriority != null) {
      log("print4");
      filters.add(['priority', '=', _selectedPriority]);
    }
    if (selectedCRMTags.isNotEmpty) {
      log("print5");
      List<int> selectedIds =
          selectedCRMTags.map((tag) => tag['id'] as int).toList();

      filters.add(['tag_ids', 'in', selectedIds]);
    }

    if (searchText.isNotEmpty) {
      log("print6");

      filters.add('|');
      filters.add(['name', 'ilike', searchText]);
      filters.add(['team_id', 'ilike', searchText]);
    }
    print(filters);
    log("print7");
    final leadDetailsraw = await client?.callKw({
      'model': 'crm.lead',
      'method': 'search_read',
      'args': [filters],
      'kwargs': {
        'fields': [
          'name',
          'email_from',
          'city',
          'country_id',
          'team_id',
          'user_id',
          'probability',
          'partner_id',
          'partner_name',
          'street',
          'contact_name',
          'email_cc',
          'function',
          'phone',
          'mobile',
          'priority',
          'tag_ids',
          'campaign_id',
          'medium_id',
          'source_id',
          'referred',
          'date_open',
          'date_closed',
          'message_bounce',
          'description',
          'duplicate_lead_ids',
          'active',
        ],
      },
    });

    log("print8$leadDetailsraw");

    if (leadDetailsraw != null && leadDetailsraw is List) {
      log("print9");
      final leadDetails = leadDetailsraw.map((lead) {
        // Convert false values to null
        return lead.map((key, value) {
          return MapEntry(key, value == false ? null : value);
        });
      }).toList();

      if (leadDetails.isNotEmpty) {
        log("print10");
        List<Map<dynamic, dynamic>> updatedLeads = [];
        for (var lead in leadDetails) {
          log("print11");
          if (lead['user_id'] is List && lead['user_id'].isNotEmpty) {
            lead['user_image'] = null;
          } else {
            log("print12");
            lead['user_image'] = null;
          }
          log("print13");
          updatedLeads.add(lead);
        }
        if (_offset == 0 || searchText.isNotEmpty) {
          log("print14");
          _leads = updatedLeads;
        } else {
          log("print15");
          _leads.addAll(updatedLeads);
        }

        _isLoading = false;
        notifyListeners();

        if (searchText.isEmpty) {
          log("print17");
          _offset += _limit;
        }
        print(_leads.length);
      } else {
        log("print18$leads");
        _hasMoreData = false;
        _isLoading = false;

        notifyListeners();
      }
    }
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
                      items: _salesPersonDetails,
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
                        salespersonSelect(value, "person");
                      },
                      selectedItem: _selectedSalesperson,
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
                      items: _salesTeamDetails,
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
                        salespersonSelect(value, "team");
                        print('Selected Sales Team: $value');
                      },
                      selectedItem: _selectedSalesTeam,
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
                      selectedItem: _selectedPriority,
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
                        salespersonSelect(value, "priority");
                      },
                    ),
                    const SizedBox(height: 20),
                    MultiSelectDropdown.simpleList(
                      list: _crmTagDetails.map((e) => e['name']).toList(),
                      initiallySelected:
                          _selectedCRMTags.map((e) => e['name']).toList(),
                      onChange: (selectedItems) {
                        List<Map<String, dynamic>> selectedMapItems = [];
                        for (var item in selectedItems) {
                          var matchingItem = _crmTagDetails.firstWhere(
                            (tag) => tag['name'] == item,
                            orElse: () => {},
                          );
                          if (matchingItem.isNotEmpty) {
                            selectedMapItems.add(matchingItem);
                          }
                        }

                        _selectedCRMTags.clear();
                        _selectedCRMTags.addAll(selectedMapItems);
                        notifyListeners();
                      },
                      includeSearch: true,
                      includeSelectAll: true,
                      isLarge: false,
                      numberOfItemsLabelToShow: 3,
                      checkboxFillColor: Colors.grey,
                      // boxDecoration: BoxDecoration(
                      //   border: Border.all(color: Colors.redAccent),
                      //   borderRadius: BorderRadius.circular(10),
                      // ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        getLeads(context: context);
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
