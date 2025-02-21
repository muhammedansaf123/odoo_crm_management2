import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/lead/components/bottomsheet_lost.dart';

import 'package:odoo_crm_management/opportunity/providers/opportunity_list_provider.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:provider/provider.dart';

class OpportunityFormProvider with ChangeNotifier {
  // Private variables
  bool? _active;
  int? _stageid;
  double? _probability;
  final Map<String, dynamic> _data = {};
  List<dynamic> leadTags = [];
  // Public getters
  bool? get active => _active;
  int? get stageId => _stageid;
  double? get probability => _probability;
  Map<String, dynamic> get data => _data;

  /// Clears all the fields and notifies listeners.
  void clear() {
    _active = null;
    _probability = null;
    _data.clear();
    notifyListeners();
  }

  Future<void> init(OdooClient client, dynamic lead) async {
    fetchStatus(client, lead);

    await getLeadTags(client, lead);
  }

  Future<void> getLeadTags(OdooClient client, dynamic lead) async {
    try {
      final response = await client.callKw({
        'model': 'crm.tag',
        'method': 'search_read',
        'args': [
          [
            ['id', 'in', lead['tag_ids']]
          ]
        ],
        'kwargs': {
          'fields': ['name'],
        },
      });
      log("aaaaaaaaaaaaaaaaaaaaaaaaaaa$response");
      if (response != null && response is List) {
        leadTags = response.map((tag) => tag['name'] as String).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching tags: $e');
    }
  }

  /// Fetches the status from the remote service and updates the variables.
  Future<void> fetchStatus(OdooClient client, dynamic lead) async {
    print("working \${lead['id']}");

    final response = await client.callKw({
      'model': 'crm.lead',
      'method': 'search_read',
      'args': [
        [
          ['type', '=', 'opportunity'],
          [
            "active",
            "=",
            [true, false]
          ],
          ['id', '=', lead['id']],
        ]
      ],
      'kwargs': {
        'fields': [
          'active',
          'probability',
          'name',
          'phone',
          'mobile',
          'email_from',
          'city',
          'country_id',
          'team_id',
          'user_id',
          'partner_id',
          'priority',
          'tag_ids',
          'date_open',
          'date_closed',
          'description',
          'contact_name',
          'stage_id',
        ],
      },
    });
    log("Response: \$response");

    if (response.isNotEmpty) {
      final result = response[0];

      _active = result['active'];
      _stageid = result['stage_id'][0];
      _probability = result['probability'] != null
          ? (result['probability'] as num).toDouble()
          : null;

      // Store all other fields in the map
      _data.clear();
      _data.addAll({
        'name': result['name'],
        'phone': result['phone'],
        'mobile': result['mobile'],
        'emailFrom': result['email_from'],
        'city': result['city'],
        'countryId': result['country_id'],
        'teamId': result['team_id'],
        'userId': result['user_id'],
        'partnerId': result['partner_id'],
        'priority': result['priority'],
        'tagIds': result['tag_ids'],
        'dateOpen': result['date_open'],
        'dateClosed': result['date_closed'],
        'description': result['description'],
        'contactName': result['contact_name'],
      });
    }

    print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa$data");

    notifyListeners();
  }

  Future<void> markLeadAsWon(
      int leadId, BuildContext context, dynamic lead) async {
    try {
      // Fetch the "Won" stage_id dynamically

      final client =
          Provider.of<OdooClientManager>(context, listen: false).client;
      var result = await client!.callKw({
        'model': 'crm.stage',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'domain': [
            ['name', '=', 'Won']
          ],
          'fields': ['id'],
          'limit': 1,
        }
      });

      if (result.isNotEmpty) {
        int wonStageId = result[0]['id'];

        // Update the lead/opportunity stage_id to "Won"
        await client.callKw({
          'model': 'crm.lead',
          'method': 'write',
          'args': [
            [leadId], // The ID of the lead to update
            {'stage_id': wonStageId} // Set the new stage_id
          ],
          'kwargs': {}
        });

        log("Lead marked as Won successfully.");
        await fetchStatus(client, lead);
        Provider.of<OpportunityListProvider>(context, listen: false)
            .initializeopportunitylist(context);
      } else {
        log("Won stage not found.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void restore(OdooClient client, dynamic lead, BuildContext context) async {
    final response = await client.callKw({
      'model': 'crm.lead',
      'method': 'toggle_active',
      'args': [
        [lead['id']]
      ],
      'kwargs': {},
    });
    print(response);

    await fetchStatus(client, lead);
    Provider.of<OpportunityListProvider>(context, listen: false)
        .initializeopportunitylist(context);
  }

  String? selectedValue;
  TextEditingController searchController = TextEditingController();
  bool isCustomInput = false;

  void showBottomSheet(
    BuildContext context,
    dynamic lead,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: 500,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SearchableDropdown(
                  isLead: false,
                  lead: lead,
                );
              },
            ),
          ),
        );
      },
    ).then((selected) {
      if (selected != null) {
        selectedValue = selected;
        notifyListeners();
      }
    });
  }
}
