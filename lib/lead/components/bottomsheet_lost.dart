import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/lead/components/custom_button.dart';
import 'package:odoo_crm_management/lead/providers/lead_form_provider.dart';
import 'package:odoo_crm_management/lead/providers/lead_list_provider.dart';
import 'package:odoo_crm_management/opportunity/opportunity_form_provider.dart';
import 'package:odoo_crm_management/opportunity/opportunity_list_provider.dart';
import 'dart:developer';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:provider/provider.dart';

class SearchableDropdown extends StatefulWidget {
  final dynamic lead;
  final bool isLead;
  const SearchableDropdown(
      {super.key, required this.lead, required this.isLead});

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

TextEditingController searchController = TextEditingController();
TextEditingController feedbackcontroller = TextEditingController();

class _SearchableDropdownState extends State<SearchableDropdown> {
  List<Lostdetails> lostReasonsList = [];
  List<Lostdetails> filteredList = [];

  bool isDropdownOpen = false;
  Lostdetails? selectedValue;
  int? defaultindex = 0;
  List<Map<String, dynamic>> lostReasons = [];
  @override
  void initState() {
    super.initState();

    fetchLostReasons();
  }

  void selectLostReason(String selectedName) {
    setState(() {
      final index =
          lostReasonsList.indexWhere((reason) => reason.name == selectedName);
      if (index != -1) {
        defaultindex = index + 1;
        selectedValue =
            lostReasonsList[index]; // Store selected reason (ID & Name)
        searchController.text = selectedValue!.name; // Update text field
        toggleDropdown(false);
        log("Selected Lost Reason: ID=${selectedValue!.id}, Name=${selectedValue!.name}");
      }
    });
  }

  Future<void> fetchLostReasons() async {
    final provider = Provider.of<OdooClientManager>(context, listen: false);
    try {
      final response = await provider.client!.callKw({
        'model': 'crm.lost.reason',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'fields': ['id', 'name'],
        },
      });

      lostReasons = List<Map<String, dynamic>>.from(response);
      log("lost$lostReasons");
      setState(() {
        lostReasonsList = lostReasons
            .map((reason) => Lostdetails(reason['name'], reason['id']))
            .toList();
        filteredList = List.from(lostReasonsList);
      });
    } catch (e) {
      log("Error fetching lost reasons: $e");
    }
  }

  Future<void> createLostReason(String reason) async {
    final provider = Provider.of<OdooClientManager>(context, listen: false);
    try {
      final response = await provider.client!.callKw({
        'model': 'crm.lost.reason',
        'method': 'create',
        'args': [
          {
            'name': reason, // This is the lost reason name field
          }
        ],
        'kwargs': {},
      });

      log("Lost Reason Created with ID: $response");

      // Wait for the list to update before selecting the new reason
      await fetchLostReasons();
      selectLostReason(reason);
    } catch (e) {
      log("Error creating lost reason: $e");
    }
  }

  void filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = List.from(lostReasonsList);
      } else {
        filteredList = lostReasonsList
            .where(
                (item) => item.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void toggleDropdown(bool open) {
    setState(() {
      isDropdownOpen = open;
    });
  }

  void toggle() {
    setState(() {
      isDropdownOpen = !isDropdownOpen;
    });
  }

  Future<void> markLeadAsLost(
    OdooClient client,
    int leadId,
  ) async {
    print("Selected Lost Reason Index: ${defaultindex!}");

    final responseWrite = await client.callKw({
      'model': 'crm.lead.lost',
      'method': 'create',
      'args': [
        {
          'lead_ids': [leadId],
          'lost_reason_id': defaultindex!, // Pass correct Lost Reason ID
          'lost_feedback': feedbackcontroller.text // Pass feedback
        }
      ],
      'kwargs': {'context': {}},
    });

    final response = await client.callKw(
      {
        'model': 'crm.lead.lost',
        'method': 'action_lost_reason_apply',
        'args': [responseWrite],
        'kwargs': {},
      },
    );

    log(response.toString());
    searchController.clear();
    feedbackcontroller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              const Text(
                "Mark Lost",
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              const Spacer(),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close))
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First Search Field
                  const Text(
                    "Lost Reason",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.01, // Responsive spacing
                  ),
                  TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        if (isDropdownOpen == false) {
                          isDropdownOpen = true;
                        }
                      });
                      filterSearchResults(value);
                    },
                    onTap: () => toggle(),
                    decoration: InputDecoration(
                      hintText: "Type to search...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                searchController.clear();
                                filterSearchResults('');
                                toggleDropdown(false);
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.01, // Responsive spacing
                  ),

                  const Text(
                    "Closing",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.01, // Responsive spacing
                  ),
                  TextField(
                    maxLines: 5,
                    controller: feedbackcontroller,
                    decoration: InputDecoration(
                      hintText: "What Went Wrong",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.04, // Responsive spacing
                  ),
                  if (widget.isLead == true) ...[
                    Consumer2<OdooClientManager, LeadFormProvider>(builder:
                        (context, odooinitprovider, leadprovider, child) {
                      print(odooinitprovider.currentsession!.userId);
                      return CustomButton(
                          text: "Mark as Lost",
                          onPressed: () async {
                            if (widget.isLead == true) {
                              await markLeadAsLost(
                                odooinitprovider.client!,
                                widget.lead['id'],
                              );

                              await leadprovider.fetchStatus(
                                  odooinitprovider.client!, widget.lead);

                              Provider.of<LeadListProvider>(context,
                                      listen: false)
                                  .init(context);
                              Navigator.pop(context);
                            }
                          });
                    }),
                  ],

                  if (widget.isLead == false) ...[
                    Consumer2<OdooClientManager, OpportunityFormProvider>(
                        builder:
                            (context, odooinitprovider, leadprovider, child) {
                      print(odooinitprovider.currentsession!.userId);
                      return CustomButton(
                          text: "Mark as Lost",
                          onPressed: () async {
                            if (widget.isLead == false) {
                              await markLeadAsLost(
                                odooinitprovider.client!,
                                widget.lead['id'],
                              );

                              await leadprovider.fetchStatus(
                                  odooinitprovider.client!, widget.lead);
 Provider.of<OpportunityListProvider>(context,
                                      listen: false)
                                  .initializeOdooClient(context);
                              Navigator.pop(context);
                            }
                          });
                    })
                  ],

                  SizedBox(
                    height: MediaQuery.of(context).size.height *
                        0.01, // Responsive spacing
                  ),
                  CustomButton(
                    text: "Cancel",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    isBorder: true,
                    isBackground: false,
                  )
                ],
              ),
              Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isDropdownOpen
                        ? MediaQuery.of(context).size.height * 0.35
                        : 0,
                    constraints: BoxConstraints(
                      maxHeight: isDropdownOpen
                          ? MediaQuery.of(context).size.height * 0.35
                          : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      boxShadow: isDropdownOpen
                          ? [
                              const BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                spreadRadius: 1,
                                offset: Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: isDropdownOpen
                        ? ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filteredList.length +
                                (searchController.text.isNotEmpty &&
                                        !lostReasonsList.any((reason) =>
                                            reason.name.toLowerCase() ==
                                            searchController.text.toLowerCase())
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index < filteredList.length) {
                                return ListTile(
                                  title: Text(filteredList[index].name),
                                  onTap: () {
                                    selectLostReason(filteredList[index].name);
                                    log('Selected value: ${filteredList[index].name}');
                                    log('id is ${defaultindex!}');
                                  },
                                );
                              } else {
                                return ListTile(
                                  title: Text(
                                    'Create new: "${searchController.text}"',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.blue),
                                  ),
                                  onTap: () {
                                    toggleDropdown(false);
                                    createLostReason(searchController.text);
                                  },
                                );
                              }
                            },
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Lostdetails {
  final String name;
  final int id;
  Lostdetails(this.name, this.id);

  @override
  String toString() {
    return name;
  }
}
