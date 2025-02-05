import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odoo_crm_management/dashboard/charts/custom_charts.dart';
import 'package:odoo_crm_management/dashboard/model/crm_model.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  int _selectedIndex = 0;
  late TabController _tabController;
  int? userId;
  OdooClient? client;
  String url = "";
  MemoryImage? profilePicUrl;
  List<Map<String, dynamic>> _stageData = [];
  List<Map<String, dynamic>> _stageOpportunityData = [];
  String _selectedFilter = 'Count';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  MemoryImage? companyPicUrl;
  String? companyLogo;

  List<FlSpot> lineGraphData = [
    const FlSpot(0, 1),
    const FlSpot(1, 3),
    const FlSpot(2, 1),
    const FlSpot(3, 2),
  ];

  List<BarChartGroupData> barChartData = [
    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 1)]),
    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 1)]),
    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1)]),
  ];

  List<PieChartSectionData> pieChartData = [
    PieChartSectionData(value: 40, color: Colors.blue),
    PieChartSectionData(value: 30, color: Colors.green),
    PieChartSectionData(value: 30, color: Colors.red),
  ];

  List<String> tabs = ["Leads", "Pipeline"];

  // List<String> tabs = ["Leads", "Pipeline", "Forecast", "Team wise report"];

  @override
  void initState() {
    super.initState();
    print(_selectedTabIndex);
    print("_selectedTabIndex_selectedTabIndex");
    _tabController = TabController(length: tabs.length, vsync: this);
    _initializeOdooClient();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    print('userId: $userId');

    url = prefs.getString('url') ?? '';
    print('url: $url');

    final db = prefs.getString('selectedDatabase') ?? '';
    print('selectedDatabase: $db');

    final sessionId = prefs.getString('sessionId') ?? '';
    print('sessionId: $sessionId');

    final serverVersion = prefs.getString('serverVersion') ?? '';
    print('serverVersion: $serverVersion');

    final userLang = prefs.getString('userLang') ?? '';
    print('userLang: $userLang');

    final companyId = prefs.getInt('companyId');
    print('companyId: $companyId');

    final allowedCompaniesStringList =
        prefs.getStringList('allowedCompanies') ?? [];
    print('allowedCompanies: $allowedCompaniesStringList');

    List<Company> allowedCompanies = [];

    if (allowedCompaniesStringList.isNotEmpty) {
      allowedCompanies = allowedCompaniesStringList
          .map((jsonString) => Company.fromJson(jsonDecode(jsonString)))
          .toList();
    }
    if (url == null || db.isEmpty || sessionId.isEmpty) {
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

    client = OdooClient(url!, session);
    print('client${client}');
    await getUserProfile();
    print("working");
    getLeadCrmReport();
    getPipelineCrmReport();
  }

  Future<void> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    companyLogo = prefs.getString("company_logo");

    print("companyLogocompanyLogodddddddddddddddd");
    if (companyLogo != null && companyLogo != 'false') {
      final imageData = base64Decode(companyLogo!);
      setState(() {
        companyPicUrl = MemoryImage(Uint8List.fromList(imageData));
      });
    }
    try {
      final userDetails = await client?.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', userId]
          ]
        ],
        'kwargs': {
          'fields': ['image_1920'],
        },
      });
      if (userDetails != null && userDetails.isNotEmpty) {
        final user = userDetails[0];
        final imageBase64 = user['image_1920'].toString();
        if (imageBase64 != null && imageBase64 != 'false') {
          final imageData = base64Decode(imageBase64);
          setState(() {
            profilePicUrl = MemoryImage(Uint8List.fromList(imageData));
          });
        }
      }
    } catch (e) {
      return;
    }
  }

  Future<void> getLeadCrmReport() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    print("userid $userId");

    print("Fetching lead details...");
    final leadDetails = await client?.callKw({
      'model': 'crm.lead',
      'method': 'search_read',
      'args': [
        [
          ['type', '=', 'lead']
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

      setState(() {
        _stageData = stageCounts.entries.map((e) {
          return {
            'stage': e.key,
            'count': e.value,
            'total_day_close': stageDayCloseTotal[e.key] ?? 0,
            'total_expected_revenue': stageExpectedRevenue[e.key] ?? 0,
            'recurring_revenue_monthly':
                stageRecurringRevenueMonthly[e.key] ?? 0,
            'probability': stageProbability[e.key] ?? 0,
            'recurring_revenue_monthly_prorated':
                stageRecurringRevenueMonthlyProrated[e.key] ?? 0,
            'recurring_revenue_prorated':
                stageRecurringRevenueProrated[e.key] ?? 0,
            'prorated_revenue': stageProratedRevenue[e.key] ?? 0,
            'recurring_revenue': stageRecurringRevenue[e.key] ?? 0,
          };
        }).toList();
        _updateStageData();
      });
      print('stagedata${_stageData.length}');
    } else {
      print("No leads found.");
    }
  }

  Future<void> getPipelineCrmReport() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;

    try {
      final opportunityDetails = await client?.callKw({
        'model': 'crm.lead',
        'method': 'search_read',
        'args': [
          [
            ['type', '=', 'opportunity']
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
            'recurring_revenue'
          ],
        },
      });

      if (opportunityDetails != null && opportunityDetails.isNotEmpty) {
        print("opportunityDetails: $opportunityDetails");

        // Convert JSON data to Opportunity list
        List<Opportunity> opportunities = opportunityDetails
            .map<Opportunity>((data) => Opportunity.fromJson(data))
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
        setState(() {
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
          _updateStageData();
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _updateStageData();
    });
  }

  void _updateStageData() {
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
    String dataKey = filterKeyMap[_selectedFilter] ?? '';

    // Define the list to be sorted depending on the tab index
    List<Map<String, dynamic>> stageDataToSort =
        _selectedTabIndex == 0 ? _stageData : _stageOpportunityData;

    if (dataKey.isNotEmpty) {
      stageDataToSort.sort((a, b) {
        var valueA = a[dataKey] ?? 0;
        var valueB = b[dataKey] ?? 0;
        return valueA.compareTo(valueB);
      });
    }

    print('filtereddata$stageDataToSort');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: const Text(
            'Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            // isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[400],
            tabs: tabs.map((tab) => Tab(text: tab)).toList(),
          ),
          backgroundColor: Colors.purple,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 30.0,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/calendar');
              },
            ),
            const SizedBox(width: 10),
            Container(
              width: 50.0,
              height: 50.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.2),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/profile',
                  );
                },
                child: CircleAvatar(
                  radius: 20.0,
                  backgroundColor: Colors.grey[400],
                  child: Stack(
                    children: [
                      if (profilePicUrl != null)
                        Positioned.fill(
                          child: ClipOval(
                            child: Image(
                              image: profilePicUrl!,
                              fit: BoxFit.cover,
                              width: 80.0,
                              height: 80.0,
                              errorBuilder: (BuildContext context,
                                  Object exception, StackTrace? stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 54,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                      if (profilePicUrl == null)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[400],
                            ),
                            child: const Center(
                              child: Icon(Icons.person),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ]),
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
              title: const Text('Leads',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              onTap: () {
                Navigator.pushNamed(context, '/lead');
              },
            ),
            ListTile(
              title: const Text('Opportunity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              onTap: () {
                Navigator.pushNamed(context, '/opportunity');
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
              padding:
                  const EdgeInsets.symmetric(vertical: 500.0, horizontal: 32.0),
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
      body: _selectedTabIndex == 0
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.tune),
                          color: Colors.black,
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                final List<Map<String, dynamic>>
                                    _filterOptions = [
                                  {"filter": "Count", "icon": Icons.filter_1},
                                  {
                                    "filter": "Days to Close",
                                    "icon": Icons.filter_2
                                  },
                                  {
                                    "filter": "Expected Revenue",
                                    "icon": Icons.filter_3
                                  },
                                  {
                                    "filter": "Expected MRR",
                                    "icon": Icons.filter_4
                                  },
                                  {
                                    "filter": "Probability",
                                    "icon": Icons.filter_5
                                  },
                                  {
                                    "filter": "Prorated MRR",
                                    "icon": Icons.filter_6
                                  },
                                  {
                                    "filter": "Prorated Recurring Revenue",
                                    "icon": Icons.filter_7
                                  },
                                  {
                                    "filter": "Prorated Revenue",
                                    "icon": Icons.filter_8
                                  },
                                  {
                                    "filter": "Recurring Revenue",
                                    "icon": Icons.filter_9
                                  },
                                ];
                                return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: _filterOptions.map((filter) {
                                          return ListTile(
                                            leading: Icon(filter["icon"]),
                                            title: Text(filter["filter"]),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _applyFilter(filter["filter"]);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                    ));
                              },
                            );
                          },
                        ),
                        ToggleButtons(
                          isSelected: [
                            0 == _selectedIndex,
                            1 == _selectedIndex,
                            2 == _selectedIndex
                          ],
                          onPressed: (int index) {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          children: const [
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                  Icons.stacked_line_chart,
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                  Icons.bar_chart,
                                )),
                            Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                  Icons.pie_chart,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildLeadGraph(),
                  ),
                ],
              ),
            )
          : _selectedTabIndex == 1
              ? _buildPipelineTabContent()
              : _selectedTabIndex == 2
                  ? _buildForecastTabContent()
                  : _selectedTabIndex == 3
                      ? _buildTab3Content()
                      : null,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/discuss');
        },
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Future<void> _getDiscussVideocallLocation() async {
    try {
      final response = await client?.callKw({
        'model': 'calendar.event',
        'method': 'get_discuss_videocall_location',
        'args': [],
        'kwargs': {},
      });

      print("Response Type: ${response.runtimeType}");
      print("Response Data: $response");
    } catch (e) {
      print("Error: $e");
    }
  }

  Widget _buildPipelineTabContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune),
                  color: Colors.black,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        final List<Map<String, dynamic>> _filterOptions = [
                          {"filter": "Count", "icon": Icons.filter_2},
                          {"filter": "Days to Close", "icon": Icons.filter_2},
                          {
                            "filter": "Expected Revenue",
                            "icon": Icons.filter_3
                          },
                          {"filter": "Expected MRR", "icon": Icons.filter_4},
                          {"filter": "Probability", "icon": Icons.filter_5},
                          {"filter": "Prorated MRR", "icon": Icons.filter_6},
                          {
                            "filter": "Prorated Recurring Revenue",
                            "icon": Icons.filter_7
                          },
                          {
                            "filter": "Prorated Revenue",
                            "icon": Icons.filter_8
                          },
                          {
                            "filter": "Recurring Revenue",
                            "icon": Icons.filter_9
                          },
                        ];
                        return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: _filterOptions.map((filter) {
                                  return ListTile(
                                    leading: Icon(filter["icon"]),
                                    title: Text(filter["filter"]),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _applyFilter(filter["filter"]);
                                    },
                                  );
                                }).toList(),
                              ),
                            ));
                      },
                    );
                  },
                ),
                ToggleButtons(
                  isSelected: [
                    0 == _selectedIndex,
                    1 == _selectedIndex,
                    2 == _selectedIndex
                  ],
                  onPressed: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: const [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.stacked_line_chart,
                        )),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.bar_chart,
                        )),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.pie_chart,
                        )),
                  ],
                ),
              ],
            ),
          ),
          // Display Selected Graph
          Expanded(
            child: _buildPipelineGraph(),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTabContent() {
    return const Center(child: Text("Content for Tab 2"));
  }

  Widget _buildTab3Content() {
    return const Center(child: Text("Content for Tab 3"));
  }

  Widget _buildPipelineGraph() {
    switch (_selectedIndex) {
      case 0:
        return LineChartWidget(
            stageData: _stageOpportunityData, selectedFilter: _selectedFilter);

      case 1:
        return BarChartWidget(
            stageData: _stageOpportunityData, selectedFilter: _selectedFilter);
      case 2:
        return MyPieChart(
          selectedFilter: _selectedFilter,
          stageData: _stageOpportunityData,
        );
      // return PieChart(PieChartData(sections: _getPipelinePieChartData()));
      default:
        return const Center(child: Text('Select a Graph Type'));
    }
  }

  Widget _buildLeadGraph() {
    switch (_selectedIndex) {
      case 0:
        return LineChartWidget(
          selectedFilter: _selectedFilter,
          stageData: _stageData,
        );

      case 1:
        return BarChartWidget(
          selectedFilter: _selectedFilter,
          stageData: _stageData,
        );
      case 2:
        return MyPieChart(
          selectedFilter: _selectedFilter,
          stageData: _stageData,
        );

      // return PieChart(PieChartData(sections: _getPieChartData()));
      default:
        return const Center(child: Text('Select a Graph Type'));
    }
  }
}
