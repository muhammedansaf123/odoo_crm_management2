import 'dart:async';
import 'dart:developer';

import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/lead/components/bottomsheet_lost.dart';
import 'package:odoo_crm_management/lead/providers/lead_list_provider.dart';
import 'package:odoo_crm_management/models/models.dart';

import 'package:odoo_crm_management/opportunity/opportunity_form.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:provider/provider.dart';

class LeadFormProvider extends ChangeNotifier {
  int? _userId;

  final String _url = "";
  List<dynamic> _leadTags = [];
  String _conversionAction = "convert";
  String _customerOption = "create";

  final List<String> _availableLeadNames = [];
  final List<int> _availableLeadIds = [];

  final List<int> _customerIds = [];
  bool? _active;
  double? _probablity;
  int? _personValue;
  int? _teamValue;
  String? _teamname;
  String? _selectedCustomer;
  int? _selectedCustomerId;

  List<LeadItem> selectedLeads = [];

  int? get userId => _userId;
  double? get probablity => _probablity;
  String get url => _url;
  List<dynamic> get leadTags => _leadTags;
  String get conversionAction => _conversionAction;
  String get customerOption => _customerOption;
  bool? get active => _active;
  List<String> get availableLeadNames => _availableLeadNames;
  List<int> get availableLeadIds => _availableLeadIds;
  List<int> get customerIds => _customerIds;
  int get personValue => _personValue!;
  int get teamValue => _teamValue!;
  String? get selectedCustomer => _selectedCustomer;
  final GlobalKey _dropdownKey = GlobalKey();
  final TextEditingController searchcontroller = TextEditingController();

  Future<void> init(dynamic lead, BuildContext context) async {
    final client =
        Provider.of<OdooClientManager>(context, listen: false).client;
    await getLeadTags(lead, client!);
    if (context.mounted) {
      Provider.of<OdooClientManager>(context, listen: false).getCrmLead();
      Provider.of<OdooClientManager>(context, listen: false)
          .getSalesTeamsAndSalesperson();
    }
  }

  Future<void> getLeadTags(dynamic lead, OdooClient client) async {
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

    if (response != null && response is List) {
      _leadTags = response.map((tag) => tag['name'] as String).toList();
    }
    print("topppppp$_leadTags");
  }

  Future<void> fetchStatus(OdooClient client, dynamic lead) async {
    print("working ${lead['id']}");

    final response = await client.callKw({
      'model': 'crm.lead',
      'method': 'search_read',
      'args': [
        [
          ['type', '=', 'lead'],
          [
            "active",
            "=",
            [true, false]
          ],
          ['id', '=', lead['id']],
        ]
      ],
      'kwargs': {
        'fields': ['active', 'probability'],
      },
    });

    _active = response[0]['active'];
    _probablity = response[0]['probability'];
    notifyListeners();
  }

  void clear() {
    _active = null;
    notifyListeners();
  }

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? '';
  }

//dialog box for changing lead to oportunity
  void showConversionPopup(BuildContext context, lead) {
    _teamValue = lead['team_id'] is List && lead['team_id'].length > 1
        ? lead['team_id'][0]
        : null;

    _personValue = lead['user_id'] is List && lead['user_id'].length > 1
        ? lead['user_id'][0]
        : null;

    SalesPersonItem? initialSalesPersonItem;
    final odoomanagerprovider =
        Provider.of<OdooClientManager>(context, listen: false);

    final allleads = odoomanagerprovider.leadItems;
    final allcustomer = odoomanagerprovider.customerItems;
    final allsalesperson = odoomanagerprovider.salesPersonItem;
    if (_personValue != null) {
      final initialSalesPerson = allsalesperson.firstWhere(
        (item) => item.id == _personValue,
      );
      initialSalesPersonItem = initialSalesPerson;
    }

    _selectedCustomerId =
        lead['partner_id'] is List && lead['partner_id'].length > 1
            ? lead['partner_id'][0]
            : null;

    log(selectedLeads.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void _onLeadSelectionChanged(List<LeadItem> values) {
              setState(() {
                selectedLeads = values;
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Convert Opportunity",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),

                      // Conversion Action
                      const Text("Conversion Action",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ToggleButtons(
                        isSelected: [
                          conversionAction == "convert",
                          conversionAction == "merge"
                        ],
                        onPressed: (index) {
                          setState(() {
                            _conversionAction =
                                index == 0 ? "convert" : "merge";
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: Colors.teal,
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text("Convert"),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text("Merge"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      if (conversionAction == "merge") ...[
                        if (selectedLeads.isNotEmpty)
                          const SizedBox(height: 10),
                        const Text(
                          "Select Leads to Merge",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        DropdownSearch<LeadItem>.multiSelection(
                          dropdownBuilder: (context, selectedItems) {
                            if (selectedItems.isEmpty) {
                              return const Text("Select a Lead");
                            }
                            return Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: selectedItems.map<Widget>((item) {
                                final formatteddate =
                                    item.createdon!.split(" ")[0];

                                return OpportunityTile(
                                  close: true,
                                  onPressed: () {
                                    setState(
                                      () {
                                        selectedItems.remove(item);
                                      },
                                    );
                                  },
                                  createdOn: formatteddate,
                                  opportunity: item.name,
                                  contactName: item.contactname ?? "N/a",
                                  email: item.email ?? 'N/a',
                                  stage: item.stage ?? "N/a",
                                  salesperson: item.salesperson ?? "N/a",
                                );
                              }).toList(),
                            );
                          },
                          key: _dropdownKey,
                          dropdownButtonProps: const DropdownButtonProps(
                              padding: EdgeInsets.all(0),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 20,
                              )),
                          items: allleads,
                          selectedItems: selectedLeads,
                          itemAsString: (LeadItem? item) => item?.name ?? "",
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Select A Lead',
                              hintStyle: const TextStyle(
                                  color: Colors.black, fontSize: 14),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                            ),
                          ),
                          onChanged: _onLeadSelectionChanged,
                          popupProps: PopupPropsMultiSelection.menu(
                            itemBuilder: (context, item, isSelected) {
                              final formatteddate =
                                  item.createdon!.split(" ")[0];

                              return OpportunityTile(
                                close: false,
                                onPressed: () {},
                                createdOn: formatteddate,
                                opportunity: item.name,
                                contactName: item.contactname ?? "N/a",
                                email: item.email ?? 'N/a',
                                stage: item.stage ?? "N/a",
                                salesperson: item.salesperson ?? "N/a",
                              );
                            },
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              controller: searchController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                                hintText: 'Search',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      width: 2, color: Color(0xfff1f1f1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      width: 2, color: Color(0xfff1f1f1)),
                                ),
                                filled: true,
                                fillColor: const Color(0xfffafafa),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 16.0),
                              ),
                            ),
                            menuProps: MenuProps(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              backgroundColor: Colors.white,
                              shadowColor: Colors.grey.withOpacity(0.1),
                              barrierDismissible: true,
                              clipBehavior: Clip.antiAlias,
                              animationDuration:
                                  const Duration(milliseconds: 200),
                            ),
                          ),
                        )
                      ],
                      const SizedBox(height: 15),

                      const Text("Assign to Salesperson",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      CustomDropdown.search(
                        overlayHeight: 300,
                        hintBuilder: (context, hint, enabled) {
                          return const Text(
                            "Select  A Sales person",
                            style: TextStyle(color: Colors.black),
                          );
                        },
                        initialItem: initialSalesPersonItem,
                        items: allsalesperson,
                        listItemBuilder:
                            (context, item, isSelected, onItemSelect) {
                          return GestureDetector(
                            onTap: onItemSelect,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: SizedBox(
                                height: 25,
                                child: Row(
                                  children: [
                                    Text(item.name),
                                    const Spacer(),
                                    if (isSelected)
                                      const Icon(Icons.check,
                                          color: Colors.blue),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        onChanged: (values) {
                          setState(() {
                            _personValue = values!.id;
                            _teamValue = values.teamid;
                            _teamname = values.teamName;
                          });
                        },
                      ),
                      const SizedBox(height: 5),
                      if (_personValue != null && _teamname != null) ...[
                        const Text(
                          "Sales Team",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15),
                          child: Text(
                            _teamname!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),

                      // Customer Selection

                      if (conversionAction == "convert") ...[
                        const Text("Customer",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ToggleButtons(
                          isSelected: [
                            customerOption == "create",
                            customerOption == "exist",
                            customerOption == "nothing"
                          ],
                          onPressed: (index) {
                            setState(() {
                              _customerOption =
                                  ["create", "exist", "nothing"][index];

                              if (_customerOption == "nothing") {
                                _selectedCustomerId = null;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: Colors.teal,
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("New Customer"),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("Existing"),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("None"),
                            ),
                          ],
                        ),
                        if (customerOption == "exist") ...[
                          const SizedBox(height: 10),
                          CustomDropdown.search(
                            hintBuilder: (context, hint, enabled) {
                              return const Text(
                                "Select  A Customer",
                                style: TextStyle(color: Colors.black),
                              );
                            },
                            items: allcustomer, // List<LeadItem>
                            listItemBuilder:
                                (context, item, isSelected, onItemSelect) {
                              // item is a LeadItem, so we can use its properties directly
                              return GestureDetector(
                                onTap: onItemSelect,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3.0),
                                  child: Row(
                                    children: [
                                      Text(item.name),
                                      const Spacer(),
                                      if (isSelected)
                                        const Icon(Icons.check,
                                            color: Colors.blue),
                                    ],
                                  ),
                                ),
                              );
                            },

                            onChanged: (values) {
                              setState(() {
                                _selectedCustomer = values!.name;
                                _selectedCustomerId = values.id;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final duplicatedLeadIds =
                                    selectedLeads.map((item) {
                                  return item.id;
                                }).toList();
                                bool success = await _convertOpportunity(
                                    lead['id'],
                                    {
                                      'partner_id': _selectedCustomerId,
                                      'user_id': _personValue,
                                      'team_id': _teamValue,
                                      'name': conversionAction,
                                      'action': customerOption,
                                      'duplicated_lead_ids': duplicatedLeadIds
                                    },
                                    context);
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  Provider.of<LeadListProvider>(context,
                                          listen: false)
                                      .getLeads(context: context);

                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              OpportunityFormView(
                                                  opportunity: lead)));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                "Create Opportunity",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void restore(OdooClient client, dynamic lead, BuildContext context) async {
    await client.callKw({
      'model': 'crm.lead',
      'method': 'toggle_active',
      'args': [
        [lead['id']]
      ],
      'kwargs': {},
    });

    await fetchStatus(client, lead);
    if (context.mounted) {
      Provider.of<LeadListProvider>(context, listen: false).init(context);
    }
  }

  Future<void> getDuplicatedLeads(int leadId, BuildContext context) async {
    final client =
        Provider.of<OdooClientManager>(context, listen: false).client;

    // Create a record in crm.lead2opportunity.partner to trigger the computation of duplicated_lead_ids
    final responseWrite = await client!.callKw({
      'model': 'crm.lead2opportunity.partner',
      'method': 'create',
      'args': [
        {
          'lead_id': leadId, // The lead to check for duplicates
          'name':
              'merge', // Indicate it's for merging, so duplicated_lead_ids will be computed
        }
      ],
      'kwargs': {},
    });

    // Now fetch the created record to get the duplicated_lead_ids
    final response = await client.callKw({
      'model': 'crm.lead2opportunity.partner',
      'method': 'read',
      'args': [responseWrite],
      'kwargs': {
        'fields': ['duplicated_lead_ids'],
      },
    });

    // Extract the list of duplicated lead IDs
    final duplicatedIds = response[0]['duplicated_lead_ids'];
    final leadDetails = await client.callKw({
      'model': 'crm.lead',
      'method': 'read',
      'args': [duplicatedIds],
      'kwargs': {
        'fields': [
          'name',
          'user_id',
          'email_from',
          'create_date',
          'stage_id',
          'partner_id'
        ],
      },
    });

    selectedLeads = leadDetails.map<LeadItem>((lead) {
      return LeadItem(
          contactname:
              lead['partner_id'] == false ? null : lead['partner_id'][1],
          id: lead['id'],
          name: lead['name'] == false ? null : lead['name'],
          email: lead['email_from'] == false ? null : lead['email_from'],
          createdon: lead['create_date'],
          salesperson: lead['user_id'] == false ? null : lead['user_id'][1],
          stage: lead['stage_id'][1]);
    }).toList();

    log('leeeeeeeeeeeeeeeeeee$selectedLeads');
    notifyListeners();
  }

  Future<bool> _convertOpportunity(int id, Map<String, dynamic> opportunityList,
      BuildContext context) async {
    try {
      final client =
          Provider.of<OdooClientManager>(context, listen: false).client;

      // Prepare the opportunityList for merging
      final responseWrite = await client!.callKw({
        'model': 'crm.lead2opportunity.partner',
        'method': 'create',
        'args': [
          {
            'lead_id': id,
            'action': opportunityList['action'],
            'name': opportunityList['name'],
            'user_id': opportunityList['user_id'],
            'team_id': opportunityList['team_id'],
            'partner_id': opportunityList['partner_id'],
            'duplicated_lead_ids': opportunityList['duplicated_lead_ids']
          }
        ],
        'kwargs': {},
      });

      if (responseWrite == null) {
        return false; // Return failure if response is null
      }

      final response = await client.callKw(
        {
          'model': 'crm.lead2opportunity.partner',
          'method': 'action_apply',
          'args': [responseWrite],
          'kwargs': {
            'context': {
              'active_ids': [
                id
              ] // Assuming this is the current lead to be converted
            }
          },
        },
      );

      if (response != null) {
        return true; // Success
      } else {
        return false; // Failure
      }
    } catch (e) {
      return false; // Handle error case
    }
    // return false;
  }

  final List<String> options = [
    "Too expensive",
    "We don't have people/skills",
    "Not enough stock",
    "Technical reasons",
    "Something else"
  ];
  String? selectedValue;
  TextEditingController searchController = TextEditingController();
  bool isCustomInput = false;

  void showBottomSheet(BuildContext context, dynamic lead) {
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
                  lead: lead,
                  isLead: true,
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

class OpportunityTile extends StatelessWidget {
  final String? createdOn;
  final String? opportunity;
  final String? contactName;
  final String? email;
  final String? stage;
  final String? salesperson;
  final bool close;
  final void Function()? onPressed;
  const OpportunityTile({
    super.key,
    required this.close,
    required this.onPressed,
    required this.createdOn,
    required this.opportunity,
    required this.contactName,
    required this.email,
    required this.stage,
    required this.salesperson,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    opportunity!,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text("Name: $contactName",
                    style: const TextStyle(fontSize: 12)),
                Text("$email", style: const TextStyle(fontSize: 12)),
                Row(
                  children: [
                    Text(
                      "$stage",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stage == "Won" ? Colors.green : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                    const Text(","), // Keeps comma inline
                    Text("Created On: $createdOn",
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
                Text("Salesperson: $salesperson",
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          if (close) ...[
            Positioned(
                top: -11,
                right: -11,
                child: IconButton(
                    onPressed: onPressed, icon: const Icon(Icons.close)))
          ]
        ],
      ),
    );
  }
}
