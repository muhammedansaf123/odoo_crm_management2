import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:html/parser.dart';

import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadFormView extends StatefulWidget {
  final Map<String, dynamic> lead;

  const LeadFormView({super.key, required this.lead});

  @override
  State<LeadFormView> createState() => _LeadFormViewState();
}

class _LeadFormViewState extends State<LeadFormView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? userId;
  OdooClient? client;
  String url = "";
  List<dynamic> leadTags = [];
  String conversionAction = "convert";
  String customerOption = "";
  List<String> sales_persons_items = [];
  List<int> sales_persons_ids = [];
  List<String> sales_teams_items = [];
  List<int> sales_teams_ids = [];
  List<String> availableLeadNames = [];
  List<int> availableLeadIds = [];
  List<String> customer_items = [];
  List<int> customer_ids = [];
  int personValue = 0;
  int teamValue = 0;
  String? selectedCustomer;

  @override
  void initState() {
    super.initState();
    _initializeOdooClient();
    _tabController = TabController(length: 2, vsync: this);
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
    await getLeadTags();
    await getSalesTeamsAndSalesperson();
    await getCrmLead();
  }

  Future<void> getLeadTags() async {
    try {
      final lead = widget.lead;
      final response = await client?.callKw({
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
        setState(() {
          leadTags = response.map((tag) => tag['name'] as String).toList();
        });
      }
    } catch (e) {
      print('Error fetching tags: $e');
    }
  }

  Future<void> getCrmLead() async {
    try {
      final leadDetails = await client?.callKw({
        'model': 'crm.lead',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['name'],
        },
      });

      if (leadDetails != null && leadDetails is List) {
        for (var item in leadDetails) {
          availableLeadNames.add(item['name']);
          availableLeadIds.add(item['id']);
        }
      }
      final customerDetails = await client?.callKw({
        'model': 'res.partner',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {
          'fields': ['name'],
        },
      });

      if (customerDetails != null && customerDetails is List) {
        for (var item in customerDetails) {
          customer_items.add(item['name']);
          customer_ids.add(item['id']);
        }
      }
    } catch (e) {
      print('Error fetching tags: $e');
    }
  }

  Future<void> getSalesTeamsAndSalesperson() async {
    try {
      final salesPersonResponse = await client?.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'fields': ['name'],
        },
      });
      if (salesPersonResponse != null && salesPersonResponse is List) {
        for (var item in salesPersonResponse) {
          sales_persons_items.add(item['name']);
          sales_persons_ids.add(item['id']);
        }
      }
      final salesTeamResponse = await client?.callKw({
        'model': 'crm.team',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'fields': ['name'],
        },
      });
      if (salesTeamResponse != null && salesTeamResponse is List) {
        for (var item in salesTeamResponse) {
          sales_teams_items.add(item['name']);
          sales_teams_ids.add(item['id']);
        }
      }
    } catch (e) {
      print('Error fetching tags: $e');
    }
  }

  Future<bool> _convertOpportunity(int id, Map<String, dynamic> opportunityList) async {
    try {
      print(opportunityList);
      print("opportunityListopportunityList");

      final responseWrite = await client?.callKw({
        'model': 'crm.lead2opportunity.partner',
        'method': 'create',
        'args': [
          {
            'lead_id': id,
            'action': opportunityList['action'],
            'name': opportunityList['name'],
            'user_id': opportunityList['user_id'],
            'team_id': opportunityList['team_id'],
            'duplicated_lead_ids': opportunityList['duplicate_lead_ids']
          }
        ],
        'kwargs': {},
      });

      print("ResponseWrite: $responseWrite");

      if (responseWrite == null) {
        return false; // Return failure if response is null
      }

      final response = await client?.callKw({
        'model': 'crm.lead2opportunity.partner',
        'method': 'action_apply',
        'args': [responseWrite],
        'kwargs': {
          'context': {
            'active_ids': [id]
          }
        },
      });

      print("Create Response: $response");

      if (response != null) {
        return true; // Success
      } else {
        return false; // Failure
      }
    } catch (e) {
      print("Error converting opportunity: $e");
      return false; // Handle error case
    }
  }


  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;
    double probability = (lead['probability'] ?? 0).toDouble();

    Color getColorForProbability(double probability) {
      if (probability < 10) {
        return Colors.red;
      } else if (probability >= 10 && probability < 50) {
        return Colors.orange[600]!;
      } else if (probability >= 50 && probability <= 80) {
        return Colors.blue;
      } else if (probability > 80 && probability < 100) {
        return Colors.green[300]!;
      } else if (probability == 100) {
        return Colors.green;
      } else {
        return Colors.grey;
      }
    }

    print(lead['tag_ids']);
    print("hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhaaaaaaaaaaaa");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lead['name'] ?? 'Lead Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
      ),
      body: lead.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.purple.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              minimumSize: Size(double.infinity,
                                  48), // Ensures same height
                            ),
                            onPressed: () {
                              _showConversionPopup(context, lead);
                            },
                            child: const Text(
                              "Convert To Opportunity",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.teal,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              minimumSize: Size(double.infinity,
                                  48), // Ensures same height
                            ),
                            child: const Text(
                              "Enrich",
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              side: BorderSide(color: Colors.teal),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              minimumSize: Size(double.infinity,
                                  48), // Ensures same height
                            ),
                            child: const Text(
                              "Lost",
                              style: TextStyle(
                                color: Colors.teal,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Probability:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: getColorForProbability(probability),
                      ),
                    ),
                    Text(
                      '${probability.toString()}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: getColorForProbability(probability),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: LinearProgressIndicator(
                    value: probability / 100,
                    minHeight: 8,
                    backgroundColor: Colors.purple.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      getColorForProbability(probability),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    lead['partner_id'] != null &&
                        lead['partner_id'] is List &&
                        lead['partner_id'].length > 1
                        ? '${lead['partner_id'][1]}'
                        : '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                buildCustomerDetailRow('Company Name:',
                    lead['partner_name']?.toString() ?? 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow('Address:',
                    lead['street']?.toString() ?? 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow(
                    'Salesperson:',
                    lead['user_id'] is List && lead['user_id'].length > 1
                        ? lead['user_id'][1].toString()
                        : 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow(
                    'Sales Team:',
                    lead['team_id'] is List && lead['team_id'].length > 1
                        ? lead['team_id'][1].toString()
                        : 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow('Contact Name:',
                    lead['contact_name']?.toString() ?? 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow('Email:',
                    lead['email_from']?.toString() ?? 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow('Email CC:',
                    lead['email_cc']?.toString() ?? 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow('Job Position:',
                    lead['function']?.toString() ?? 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow('Phone:',
                    lead['phone']?.toString() ?? 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildCustomerDetailRow('Mobile:',
                    lead['mobile']?.toString() ?? 'Not Available'),
                SizedBox(
                  height: 10,
                ),
                buildPriorityStars(
                    'Priority:',
                    int.tryParse(lead['priority']?.toString() ?? '0') ??
                        0),
                SizedBox(
                  height: 10,
                ),
                buildCustomerTagsRow(
                    'Tags:',
                    leadTags.isNotEmpty
                        ? leadTags.join(', ')
                        : 'No Tags Available'),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Internal Notes'),
                    Tab(text: 'Extra Info'),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          lead['description'] is String &&
                              lead['description'].isNotEmpty
                              ? parseHtmlString(lead['description'])
                              : 'No description available',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EMAIL',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            buildCustomerDetailRow(
                                'Bounce:',
                                lead['message_bounce']?.toString() ??
                                    'Not Available'),
                            SizedBox(height: 20),
                            Text(
                              'ANALYSIS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            buildCustomerDetailRow(
                                'Assignment Date:',
                                lead['date_open']?.toString() ??
                                    'Not Available'),
                            buildCustomerDetailRow(
                                'Closed Date:',
                                lead['date_closed']?.toString() ??
                                    'Not Available'),
                            SizedBox(height: 20),
                            Text(
                              'MARKETING',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            buildCustomerDetailRow(
                                'Campaign:',
                                lead['campaign_id'][1] ??
                                    'Not Available'),
                            buildCustomerDetailRow('Medium:',
                                lead['medium_id'][1] ?? 'Not Available'),
                            buildCustomerDetailRow('Source:',
                                lead['source_id'][1] ?? 'Not Available'),
                            buildCustomerDetailRow(
                              'Referred By:',
                              lead['referred']?.toString() ??
                                  'Not Available',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConversionPopup(BuildContext context, lead) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        teamValue = lead['team_id'] is List && lead['team_id'].length > 1
            ? lead['team_id'][0]
            : 0;
        personValue = lead['user_id'] is List && lead['user_id'].length > 1
            ? lead['user_id'][0]
            : 0;
        List<int> selectedLeads = []; // Store selected lead IDs

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Convert Opportunity"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Conversion Action:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: "convert",
                              groupValue: conversionAction,
                              onChanged: (String? value) {
                                setState(() {
                                  conversionAction = value!;
                                  selectedLeads.clear(); // Clear selection when switching to Convert
                                });
                              },
                            ),
                            Text("Convert to Opportunity"),
                          ],
                        ),
                        Row(
                          children: [
                            Radio<String>(
                              value: "merge",
                              groupValue: conversionAction,
                              onChanged: (String? value) {
                                setState(() {
                                  conversionAction = value!;
                                });
                              },
                            ),
                            Text("Merge with Existing Opportunities"),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    if (conversionAction == "merge") ...[
                      Text("Select Leads to Merge:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      SizedBox(height: 10),
                      DropdownSearch<int>.multiSelection(
                        items: availableLeadIds,
                        selectedItems: selectedLeads,
                        itemAsString: (int? item) => availableLeadNames[availableLeadIds.indexOf(item!)],
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Select Leads',
                          ),
                        ),
                        onChanged: (values) {
                          setState(() {
                            selectedLeads = values;
                          });
                        },
                        popupProps: PopupPropsMultiSelection.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              labelText: 'Search Leads',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 10),
                    Text("Assign This Opportunity To:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    SizedBox(height: 30),
                    DropdownSearch<int>(
                      selectedItem: personValue != 0 ? personValue : null,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Salesperson',
                        ),
                      ),
                      items: sales_persons_ids,
                      itemAsString: (int? item) =>
                      sales_persons_items[sales_persons_ids.indexOf(item!)],
                      onChanged: (value) {
                        setState(() {
                          personValue = value!;
                        });
                      },
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Search Salesperson',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10),
                    Text("Customer:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    SizedBox(height: 10),
                    Column(
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: "create",
                              groupValue: customerOption,
                              onChanged: (String? value) {
                                setState(() {
                                  customerOption = value!;
                                });
                              },
                            ),
                            Text("Create a new customer"),
                          ],
                        ),
                        Row(
                          children: [
                            Radio<String>(
                              value: "exist",
                              groupValue: customerOption,
                              onChanged: (String? value) {
                                setState(() {
                                  customerOption = value!;
                                });
                              },
                            ),
                            Text("Link to an existing customer"),
                          ],
                        ),
                        Row(
                          children: [
                            Radio<String>(
                              value: "nothing",
                              groupValue: customerOption,
                              onChanged: (String? value) {
                                setState(() {
                                  customerOption = value!;
                                });
                              },
                            ),
                            Text("Do not link to a customer"),
                          ],
                        ),
                        if (customerOption == "exist") ...[
                          SizedBox(height: 10),
                          Text("Select Customer:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          SizedBox(height: 10),
                          DropdownSearch<int>(
                            enabled: customerOption == "exist", // Ensure the field is enabled only if 'exist' is selected
                            selectedItem: selectedCustomer != null ? int.tryParse(selectedCustomer!) : null,
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Select Customer',
                              ),
                            ),
                            items: customer_ids,
                            itemAsString: (int? item) => customer_items[customer_ids.indexOf(item!)],
                            onChanged: (value) {
                              setState(() {
                                selectedCustomer = value.toString();
                              });
                            },
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchFieldProps: TextFieldProps(
                                decoration: InputDecoration(
                                  labelText: 'Search Customer',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic> opportunityList = {
                        'action': customerOption,
                        'name': conversionAction,
                        'user_id': personValue,
                        'team_id': teamValue,
                        'duplicate_lead_ids': conversionAction == "merge"
                            ? selectedLeads
                            : lead['duplicate_lead_ids']
                      };
                      bool success = await _convertOpportunity(lead['id'], opportunityList);

                      if (success) {
                        Navigator.pop(context); // Close the popup
                      } else {
                        print("Failed to convert opportunity.");
                      }                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: Text(
                      "Create Opportunity",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? '';
  }

  Widget buildCustomerDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Text(
                  value == null || value == 'false' ? 'None' : value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (value != 'false')
            value != null && label == 'Address:'
                ? Container(
              padding: EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: TextField(
                  controller: TextEditingController(text: value),
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            )
                : Container(),
        ],
      ),
    );
  }

  Widget buildCustomerTagsRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          leadTags.isNotEmpty
              ? leadTags.length > 2
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              (leadTags.length / 2)
                  .ceil(), // Calculate the number of rows
                  (index) {
                final start = index * 2;
                final end = start + 2;
                final tagPair = leadTags.sublist(start,
                    end > leadTags.length ? leadTags.length : end);

                return Row(
                  children: tagPair.map((tag) {
                    final color = Colors.primaries[
                    leadTags.indexOf(tag) %
                        Colors.primaries.length];
                    return Container(
                      margin:
                      EdgeInsets.only(right: 5.0, bottom: 4.0),
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          )
              : Wrap(
            spacing: 5.0,
            children: leadTags.map((tag) {
              final color = Colors.primaries[
              leadTags.indexOf(tag) % Colors.primaries.length];
              return Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              );
            }).toList(),
          )
              : SizedBox(),
        ],
      ),
    );
  }

  Widget buildPriorityStars(String label, int priority) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.star,
              color: priority >= 1 ? Colors.yellow[700] : Colors.grey,
            ),
            Icon(
              Icons.star,
              color: priority >= 2 ? Colors.yellow[700] : Colors.grey,
            ),
            Icon(
              Icons.star,
              color: priority >= 3 ? Colors.yellow[700] : Colors.grey,
            ),
          ],
        ),
      ],
    );
  }
}
