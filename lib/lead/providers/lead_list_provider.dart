import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadListProvider extends ChangeNotifier {
  // Private variables with public getters
  int? _userId;

  String _url = "";
  List<Map<dynamic, dynamic>> _leads = [];
  bool _isSearching = false;
  bool _isLoading = false;
  final TextEditingController searchController = TextEditingController();
  String _searchText = '';
  String _selectedOption = '';
  String _valueStatus = '';
  int? _selectedSalespersonId;
  List<Map<String, dynamic>> _salesPersonDetails = [];
  List<Map<String, dynamic>> _salesTeamDetails = [];
  List<Map<String, dynamic>> _crmTagDetails = [];
  Map<String, dynamic>? _selectedSalesperson;
  Map<String, dynamic>? _selectedSalesTeam;
  List<Map<String, dynamic>> _selectedCRMTags = [];
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
  int? get selectedSalespersonId => _selectedSalespersonId;
  List<Map<String, dynamic>> get salesPersonDetails => _salesPersonDetails;
  List<Map<String, dynamic>> get salesTeamDetails => _salesTeamDetails;
  List<Map<String, dynamic>> get crmTagDetails => _crmTagDetails;
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
    print("print1");
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
      print("Reached the bottom, should load more if available");
      // Optionally call getLeads(fromScroll: true) here
      // getLeads(fromScroll: true);
    }
  }

  Future<void> getSalesPerson(OdooClient client) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? 0;

    try {
      final response = await client?.callKw({
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
      final response = await client?.callKw({
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
      final response = await client?.callKw({
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
    if (selectedCRMTags != null && selectedCRMTags.isNotEmpty) {
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

    log("print8");

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
            final userId = lead['user_id'][0];
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
            if (userDetails != null &&
                userDetails is List &&
                userDetails.isNotEmpty) {
              lead['user_image'] = userDetails[0]['image_1920'];
            } else {
              lead['user_image'] = null;
            }
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
}
