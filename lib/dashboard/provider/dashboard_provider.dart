import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:odoo_crm_management/dashboard/model/crm_model.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardProvider extends ChangeNotifier {
  int selectedTabIndex = 0;
  int selectedIndexlead = 0;
  int selectedindexpipeline = 0;
  bool isloading = true;
  int? userId;
  String url = "";

  List<Map<String, dynamic>> _stageData = [];
  List<Map<String, dynamic>>? get stageData => _stageData;
  List<Map<String, dynamic>> _stageOpportunityData = [];
  List<Map<String, dynamic>>? get stageOpportunityData => _stageOpportunityData;

  String selectedFilter = 'Count';

  Future<void> init(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isLoggedIn') ?? false) {
      final odooClientManager =
          Provider.of<OdooClientManager>(context, listen: false);

      await odooClientManager.initializeOdooClient();
      getLeadCrmReport(odooClientManager.client!);
      getPipelineCrmReport(odooClientManager.client!);
    }
  }

  Future<void> getLeadCrmReport(OdooClient client) async {
    print("Fetching lead details...");

    final leadDetails = await client?.callKw({
      'model': 'crm.lead',
      'method': 'search_read',
      'args': [
        [
          ['type', '=', 'lead'],
        ]
      ],
      'kwargs': {
        'fields': [
          'id',
          'create_date',
          'stage_id',
          'day_close',
          'expected_revenue',
          'recurring_revenue_monthly',
          'probability',
          'recurring_revenue_monthly_prorated',
          'recurring_revenue_prorated',
          'prorated_revenue',
          'recurring_revenue',
          'city',
        ],
      },
    });

    if (leadDetails != null && leadDetails.isNotEmpty) {
      print("Success: Lead details fetched");

      List<LeadCrmModel> leads = leadDetails.map<LeadCrmModel>((lead) {
        return LeadCrmModel.fromJson(Map<String, dynamic>.from(lead));
      }).toList();

     
      Map<String, int> stageCounts = {};
      Map<String, num> stageDayCloseTotal = {};
      Map<String, num> stageExpectedRevenue = {};
      Map<String, num> stageRecurringRevenueMonthly = {};
      Map<String, num> stageProbability = {};
      Map<String, num> stageRecurringRevenueMonthlyProrated = {};
      Map<String, num> stageRecurringRevenueProrated = {};
      Map<String, num> stageProratedRevenue = {};
      Map<String, num> stageRecurringRevenue = {};

      for (var lead in leads) {
        String stageName = lead.stageName;
       

        stageCounts[stageName] = (stageCounts[stageName] ?? 0) + 1;

        stageDayCloseTotal[stageName] =
            (stageDayCloseTotal[stageName] ?? 0) + lead.dayClose;
        stageExpectedRevenue[stageName] =
            (stageExpectedRevenue[stageName] ?? 0) + lead.expectedRevenue;
        stageRecurringRevenueMonthly[stageName] =
            (stageRecurringRevenueMonthly[stageName] ?? 0) +
                lead.recurringRevenueMonthly;
        stageProbability[stageName] =
            (stageProbability[stageName] ?? 0) + lead.probability;
        stageRecurringRevenueMonthlyProrated[stageName] =
            (stageRecurringRevenueMonthlyProrated[stageName] ?? 0) +
                lead.recurringRevenueMonthlyProrated;
        stageRecurringRevenueProrated[stageName] =
            (stageRecurringRevenueProrated[stageName] ?? 0) +
                lead.recurringRevenueProrated;
        stageProratedRevenue[stageName] =
            (stageProratedRevenue[stageName] ?? 0) + lead.proratedRevenue;
        stageRecurringRevenue[stageName] =
            (stageRecurringRevenue[stageName] ?? 0) + lead.recurringRevenue;
      }

      _stageData = stageCounts.entries.map((e) {
        return {
          'stage': e.key,
          'count': e.value,
          'total_day_close': stageDayCloseTotal[e.key] ?? 0,
          'total_expected_revenue': stageExpectedRevenue[e.key] ?? 0,
          'recurring_revenue_monthly': stageRecurringRevenueMonthly[e.key] ?? 0,
          'probability': stageProbability[e.key] ?? 0,
          'recurring_revenue_monthly_prorated':
              stageRecurringRevenueMonthlyProrated[e.key] ?? 0,
          'recurring_revenue_prorated':
              stageRecurringRevenueProrated[e.key] ?? 0,
          'prorated_revenue': stageProratedRevenue[e.key] ?? 0,
          'recurring_revenue': stageRecurringRevenue[e.key] ?? 0,
        };
      }).toList();
      updateStageData();
      isloading = false;
      notifyListeners();
    } else {
      print("No leads found.");
    }
  }

  Future<void> getPipelineCrmReport(OdooClient client) async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;

    try {
      final opportunityDetails = await client.callKw({
        'model': 'crm.lead',
        'method': 'search_read',
        'args': [
          [
            ['type', '=', 'opportunity'],
            ['user_id', '!=', ""]
          ]
        ],
        'kwargs': {
          'fields': [
            'user_id',
            'id',
            'create_date',
            'stage_id',
            'day_close',
            'expected_revenue',
            'recurring_revenue_monthly',
            'probability',
            'recurring_revenue_monthly_prorated',
            'recurring_revenue_prorated',
            'prorated_revenue',
            'recurring_revenue',
            'date_deadline',
          ],
        },
      });

      if (opportunityDetails != null && opportunityDetails.isNotEmpty) {
      

        // Convert JSON data to Opportunity list
        List<OpportunityModel> opportunities = opportunityDetails
            .map<OpportunityModel>((data) => OpportunityModel.fromJson(data))
            .toList();

        // Aggregated data maps
        Map<String, int> stageCounts = {};

        Map<String, double> stageDayCloseTotal = {};
        Map<String, double> stageExpectedRevenue = {};
        Map<String, double> stageRecurringRevenueMonthly = {};
        Map<String, double> stageProbability = {};
        Map<String, double> stageRecurringRevenueMonthlyProrated = {};
        Map<String, double> stageRecurringRevenueProrated = {};
        Map<String, double> stageProratedRevenue = {};
        Map<String, double> stageRecurringRevenue = {};

        for (var opportunity in opportunities) {
          String stageName = opportunity.stageName;

          stageCounts[stageName] = (stageCounts[stageName] ?? 0) + 1;

          stageDayCloseTotal[stageName] =
              (stageDayCloseTotal[stageName] ?? 0) + opportunity.dayClose;
          stageExpectedRevenue[stageName] =
              (stageExpectedRevenue[stageName] ?? 0) +
                  opportunity.expectedRevenue;
          stageRecurringRevenueMonthly[stageName] =
              (stageRecurringRevenueMonthly[stageName] ?? 0) +
                  opportunity.recurringRevenueMonthly;
          stageProbability[stageName] =
              (stageProbability[stageName] ?? 0) + opportunity.probability;
          stageRecurringRevenueMonthlyProrated[stageName] =
              (stageRecurringRevenueMonthlyProrated[stageName] ?? 0) +
                  opportunity.recurringRevenueMonthlyProrated;
          stageRecurringRevenueProrated[stageName] =
              (stageRecurringRevenueProrated[stageName] ?? 0) +
                  opportunity.recurringRevenueProrated;
          stageProratedRevenue[stageName] =
              (stageProratedRevenue[stageName] ?? 0) +
                  opportunity.proratedRevenue;
          stageRecurringRevenue[stageName] =
              (stageRecurringRevenue[stageName] ?? 0) +
                  opportunity.recurringRevenue;
        }

        // Update UI state

        _stageOpportunityData = stageCounts.entries.map((e) {
          String stage = e.key;
          return {
            'stage': stage,
            'count': e.value,
            'total_day_close': stageDayCloseTotal[stage] ?? 0,
            'total_expected_revenue': stageExpectedRevenue[stage] ?? 0,
            'recurring_revenue_monthly':
                stageRecurringRevenueMonthly[stage] ?? 0,
            'probability': stageProbability[stage] ?? 0,
            'recurring_revenue_monthly_prorated':
                stageRecurringRevenueMonthlyProrated[stage] ?? 0,
            'recurring_revenue_prorated':
                stageRecurringRevenueProrated[stage] ?? 0,
            'prorated_revenue': stageProratedRevenue[stage] ?? 0,
            'recurring_revenue': stageRecurringRevenue[stage] ?? 0,
          };
        }).toList();
        updateStageData();
        isloading = false;
        notifyListeners();
        print("hello${stageOpportunityData!.length}");
        print("hello${stageData!.length}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void applyFilter(String filter) {
    selectedFilter = filter;
    updateStageData();
    notifyListeners();
  }

  void updateStageData() {
    // Define a map that associates each filter to its corresponding data key
    Map<String, String> filterKeyMap = {
      'Count': "count",
      'Days to Close': 'total_day_close',
      'Days to Convert': 'days_to_convert',
      'Expected Revenue': 'expected_revenue',
      'Expected MRR': 'recurring_revenue_monthly',
      'Probability': 'probability',
      'Prorated MRR': 'recurring_revenue_monthly_prorated',
      'Prorated Recurring Revenue': 'recurring_revenue_prorated',
      'Prorated Revenue': 'prorated_revenue',
      'Recurring Revenue': 'recurring_revenue',
    };

    // Get the correct data key based on the selected filter
    String dataKey = filterKeyMap[selectedFilter] ?? '';

    // Define the list to be sorted depending on the tab index
    List<Map<String, dynamic>> stageDataToSort =
        selectedTabIndex == 0 ? _stageData : _stageOpportunityData;

    if (dataKey.isNotEmpty) {
      stageDataToSort.sort((a, b) {
        var valueA = a[dataKey] ?? 0;
        var valueB = b[dataKey] ?? 0;
        return valueA.compareTo(valueB);
      });
    }

    print('filtereddata$stageDataToSort');
  }

  void clear() {
    _stageData = [];
    _stageOpportunityData = [];
    url = "";
    userId = null;
    selectedTabIndex = 0;
    notifyListeners();
  }
}
