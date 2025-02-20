import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
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

  Future<void> initializeOdooClient(BuildContext context) async {
    scrollController.addListener(_scrollListener);
    final clinetprovider =
        Provider.of<OdooClientManager>(context, listen: false);

    await getOpportunities(context: context);
    await getSalesPerson(clinetprovider.client!);
    await getSalesTeam(clinetprovider.client!);
    await getTags(clinetprovider.client!,context);
  }

  void _scrollListener() {
    if (scrollController.offset >=
            scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange &&
        !isLoading &&
        hasMoreData) {
      print("isLoading = false;isLoading = false;");
      getOpportunities(fromScroll: true);
    }
  }

  void controllerdispose(){
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

  Future<void> getTags(OdooClient client,BuildContext) async {
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
    BuildContext? context
  }) async {
    
      log("print1");
        isLoading = true;
   
      final clientprovider =
          Provider.of<OdooClientManager>(context!, listen: false);
      final client = clientprovider.client;

      try {log("print2");
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
              'active'
            ],
          },
        });

        print(opportunityDetails);
        if (opportunityDetails != null && opportunityDetails is List) {
          List<Map<String, dynamic>> updatedOpportunities = [];
log("print4");
          for (var opportunity in opportunityDetails) {
            log("print5");
            if (opportunity['user_id'] is List &&
                opportunity['user_id'].isNotEmpty) {log("print6");
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
              log("print7");
            }
            updatedOpportunities.add(opportunity as Map<String, dynamic>);
          }

          
            if (offset != 0 || searchText.isEmpty) {
              log("print8");
              opportunities = updatedOpportunities;
            } else {log("print9");
             opportunities = updatedOpportunities;
            }
            log("print10");
            opportunities = opportunities.toSet().toList();
            isLoading = false;
        notifyListeners();

          if (searchText.isEmpty) {log("print11");
            offset += limit;
          }
        } else {log("print12");
          hasMoreData = false;
          isLoading = false;
          notifyListeners();
        }
      } catch (e) {}
    }
  }

