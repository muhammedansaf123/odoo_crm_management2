import 'dart:async';
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:typed_data';

import 'opportunity_form.dart';

class Opportunity extends StatefulWidget {
  const Opportunity({super.key});

  @override
  State<Opportunity> createState() => _OpportunityState();
}

class _OpportunityState extends State<Opportunity> {
  int? userId;
  OdooClient? client;
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
  ScrollController _scrollController = ScrollController();
  final int limit = 20;
  bool hasMoreData = true;
  int offset = 0;
  Timer? _debounce;
  MemoryImage? companyPicUrl;
  String? companyLogo;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initializeOdooClient();
  }

  Future<void> _initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    url = prefs.getString('url') ?? '';
    final db = prefs.getString('selectedDatabase') ?? '';
    final sessionId = prefs.getString('sessionId') ?? '';
    final serverVersion = prefs.getString('serverVersion') ?? '';
    final userLang = prefs.getString('userLang') ?? '';
    final companyId = prefs.getInt('companyId');
    final allowedCompaniesStringList =
        prefs.getStringList('allowedCompanies') ?? [];
    List<Company> allowedCompanies = [];

    if (allowedCompaniesStringList.isNotEmpty) {
      allowedCompanies = allowedCompaniesStringList
          .map((jsonString) => Company.fromJson(jsonDecode(jsonString)))
          .toList();
    }
    if (url.isEmpty || db.isEmpty || sessionId.isEmpty) {
      throw Exception('URL, database, or session details not set');
    }

    final session = OdooSession(
      id: sessionId,
      userId: prefs.getInt('userId') ?? 0,
      partnerId: prefs.getInt('partnerId') ?? 0,
      userLogin: prefs.getString('userLogin') ?? '',
      userName: prefs.getString('userName') ?? '',
      userLang: userLang,
      userTz: '',
      isSystem: prefs.getBool('isSystem') ?? false,
      dbName: db,
      serverVersion: serverVersion,
      companyId: companyId ?? 1,
      allowedCompanies: allowedCompanies,
    );

    client = OdooClient(url, session);
    companyLogo = prefs.getString("company_logo");
    if (companyLogo != null && companyLogo != 'false') {
      final imageData = base64Decode(companyLogo!);
      setState(() {
        companyPicUrl = MemoryImage(Uint8List.fromList(imageData));
      });
    }
    await getOpportunities();
    await getSalesPerson();
    await getSalesTeam();
    await getTags();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !isLoading &&
        hasMoreData) {
      print("isLoading = false;isLoading = false;");
      getOpportunities(fromScroll: true);
    }
  }

  Future<void> getSalesPerson() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    try {
      final response = await client?.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      setState(() {
        salesPersonDetails = List<Map<String, dynamic>>.from(response ?? []);
      });
    } catch (e) {
      print('Error fetching salespersons: $e');
    }
  }

  Future<void> getSalesTeam() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    try {
      final response = await client?.callKw({
        'model': 'crm.team',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      setState(() {
        salesTeamDetails = List<Map<String, dynamic>>.from(response ?? []);
      });
    } catch (e) {
      print('Error fetching salespersons: $e');
    }
  }

  Future<void> getTags() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;

    try {
      final response = await client?.callKw({
        'model': 'crm.tag',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      setState(() {
        crmTagDetails = List<Map<String, dynamic>>.from(response ?? []);
      });
    } catch (e) {
      print('Error fetching salespersons: $e');
    }
  }

  Future<void> getOpportunities({bool fromScroll = false}) async {
    if (!fromScroll) {
      setState(() {
        isLoading = true;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 0;
    final args = ModalRoute.of(context)!.settings.arguments as Map?;

    try {
      final List<dynamic> filters = [
        ['type', '=', 'opportunity']
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

      final opportunityDetails = await client?.callKw({
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
            'priority',
            'tag_ids',
            'date_open',
            'date_closed',
            'description'
          ],
          if (searchText.isEmpty) 'limit': limit,
          if (searchText.isEmpty) 'offset': offset,
        },
      });

      if (opportunityDetails != null && opportunityDetails is List) {
        List<Map<String, dynamic>> updatedOpportunities = [];
        for (var opportunity in opportunityDetails) {
          if (opportunity['user_id'] is List &&
              opportunity['user_id'].isNotEmpty) {
            final userId = opportunity['user_id'][0];
            final userDetails = await client?.callKw({
              'model': 'res.users',
              'method': 'read',
              'args': [
                [userId],
              ],
              'kwargs': {
                'fields': ['image_1920'],
              },
            });
            opportunity['user_image'] = userDetails?[0]['image_1920'];
          } else {
            opportunity['user_image'] = null;
          }
          updatedOpportunities.add(opportunity as Map<String, dynamic>);
        }

        setState(() {
          if (offset == 0 || searchText.isNotEmpty) {
            opportunities = updatedOpportunities;
          } else {
            opportunities.addAll(updatedOpportunities);
          }

          opportunities = opportunities.toSet().toList();
          isLoading = false;
        });

        if (searchText.isEmpty) {
          offset += limit;
        }
      } else {
        setState(() {
          hasMoreData = false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching leads: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
          ),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: isSearching
            ? TextField(
                controller: searchController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white),
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(Duration(milliseconds: 500), () {
                    setState(() {
                      searchText = query;
                      offset = 0;
                      hasMoreData = true;
                      searchText = query;
                      getOpportunities();
                    });
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
          if (!isSearching)
            IconButton(
              icon: Icon(
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
                                  items: salesPersonDetails,
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
                                      selectedSalesperson = value;
                                    });
                                  },
                                  selectedItem: selectedSalesperson,
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
                                  items: salesTeamDetails,
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
                                      selectedSalesTeam = value;
                                    });
                                    print('Selected Sales Team: $value');
                                  },
                                  selectedItem: selectedSalesTeam,
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
                                  selectedItem: selectedPriority,
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
                                      selectedPriority = value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                MultiSelectDropdown.simpleList(
                                  list: crmTagDetails
                                      .map((e) => e['name'])
                                      .toList(),
                                  initiallySelected: selectedCRMTags
                                      .map((e) => e['name'])
                                      .toList(),
                                  onChange: (selectedItems) {
                                    List<Map<String, dynamic>>
                                        selectedMapItems = [];
                                    for (var item in selectedItems) {
                                      var matchingItem =
                                          crmTagDetails.firstWhere(
                                        (tag) => tag['name'] == item,
                                        orElse: () => {},
                                      );
                                      if (matchingItem.isNotEmpty) {
                                        selectedMapItems.add(matchingItem);
                                      }
                                    }

                                    setState(() {
                                      selectedCRMTags.clear();
                                      selectedCRMTags.addAll(selectedMapItems);
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
                                    getOpportunities();
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
          if (!isSearching)
            IconButton(
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  isSearching = true;
                });
              },
            )
          else
            IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  isSearching = false;
                  searchController.clear();
                  searchText = '';
                  getOpportunities();
                });
              },
            )
        ],
      ),
      drawer: Drawer(
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
                  child: Container(
                    decoration: BoxDecoration(
                      image: companyPicUrl != null
                          ? DecorationImage(
                        image: companyPicUrl!,
                        // fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: companyPicUrl == null
                        ? const Center(
                      child: Icon(
                        Icons.business,
                        size: 40,
                        color: Colors.grey,
                      ),
                    )
                        : null,
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('Dashboard',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              onTap: () {
                Navigator.pushNamed(context, '/dashboard');
              },
            ),
            ListTile(
              title: const Text('Leads',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              onTap: () {
                Navigator.pushNamed(context, '/lead');
              },
            ),
            ListTile(
              title: const Text('Sales Team',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              onTap: () {
                Navigator.pushNamed(context, '/sales_team');
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 500.0, horizontal: 32.0),
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
      ),
      body: isLoading
          ? Expanded(
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
                        leading: CircleAvatar(
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
            )
          : opportunities.isEmpty
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
                          SizedBox(height: 20),
                          Text(
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
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: opportunities.length,
                  itemBuilder: (context, index) {
                    final opportunity = opportunities[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: opportunity['user_image'] != null
                              ? MemoryImage(
                                  base64Decode(opportunity['user_image']))
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OpportunityFormView(opportunity: opportunity),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
