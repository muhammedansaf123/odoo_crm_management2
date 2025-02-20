

import 'package:flutter/material.dart';

import 'package:odoo_crm_management/dashboard/charts/custom_charts.dart';
import 'package:odoo_crm_management/dashboard/dashboard_drawer.dart';

import 'package:odoo_crm_management/dashboard/provider/dashboard_provider.dart';
import 'package:odoo_crm_management/initilisation.dart';

import 'package:provider/provider.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  List<String> tabs = ["Leads", "Pipeline"];
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();

    print("_selectedTabIndex_selectedTabIndex");
    _tabController =
        TabController(length: tabs.length, vsync: this, initialIndex: 0);

    Provider.of<DashboardProvider>(context, listen: false).init(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
        builder: (context, dashboardprovider, child) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            leading: IconButton(
                onPressed: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
                icon: const Icon(Icons.menu)),
            bottom: TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  dashboardprovider.selectedTabIndex = index;
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
                child: GestureDetector(onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/profile',
                  );
                }, child: Consumer<OdooClientManager>(
                  builder: (context, provider, child) {
                    print("Rendering profile pic: ${provider.profilePicUrl}");
                    return CircleAvatar(
                      radius: 20.0,
                      backgroundColor: Colors.grey[400],
                      child: Stack(
                        children: [
                          if (provider.profilePicUrl != null)
                            Positioned.fill(
                              child: ClipOval(
                                child: Image(
                                  image: provider.profilePicUrl!,
                                  fit: BoxFit.cover,
                                  width: 80.0,
                                  height: 80.0,
                                  errorBuilder: (BuildContext context,
                                      Object exception,
                                      StackTrace? stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 54,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                            ),
                          if (provider.profilePicUrl == null)
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
                            ),
                        ],
                      ),
                    );
                  },
                )),
              ),
              const SizedBox(width: 10),
            ]),
        drawer: const DashboardDrawer(),
        body: dashboardprovider.selectedTabIndex == 0
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
                                          children:
                                              _filterOptions.map((filter) {
                                            return ListTile(
                                              leading: Icon(filter["icon"]),
                                              title: Text(filter["filter"]),
                                              onTap: () {
                                                Navigator.pop(context);
                                                dashboardprovider.applyFilter(
                                                    filter["filter"]);
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
                              0 == dashboardprovider.selectedIndexlead,
                              1 == dashboardprovider.selectedIndexlead,
                              2 == dashboardprovider.selectedIndexlead
                            ],
                            onPressed: (int index) {
                              setState(() {
                                dashboardprovider.selectedIndexlead = index;
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
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      dashboardprovider.selectedFilter,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Expanded(
                      child: _buildLeadGraph(dashboardprovider),
                    ),
                  ],
                ),
              )
            : dashboardprovider.selectedTabIndex == 1
                ? const PipelineTabContent()
                : dashboardprovider.selectedTabIndex == 2
                    ? _buildForecastTabContent()
                    : dashboardprovider.selectedTabIndex == 3
                        ? _buildTab3Content()
                        : null,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/discuss');
          },
          backgroundColor: Colors.teal,
          child: const Icon(
            Icons.chat,
            color: Colors.white,
          ),
        ),
      );
    });
  }

  Future<void> _getDiscussVideocallLocation() async {
    final odooClientManager =
        Provider.of<OdooClientManager>(context, listen: false);
    final client = odooClientManager.client;
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

  Widget _buildForecastTabContent() {
    return const Center(child: Text("Content for Tab 2"));
  }

  Widget _buildTab3Content() {
    return const Center(child: Text("Content for Tab 3"));
  }

  Widget _buildLeadGraph(DashboardProvider dashboardprovider) {
    switch (dashboardprovider.selectedIndexlead) {
      case 0:
        return LineChartWidgetCustom(
          selectedFilter: dashboardprovider.selectedFilter,
          stageData: dashboardprovider.stageData!,
        );

      case 1:
        return BarChartWidget(
          selectedFilter: dashboardprovider.selectedFilter,
          stageData: dashboardprovider.stageData!,
        );
      case 2:
        return MyPieChart(
          selectedFilter: dashboardprovider.selectedFilter,
          stageData: dashboardprovider.stageData!,
        );

      // return PieChart(PieChartData(sections: _getPieChartData()));
      default:
        return const Center(child: Text('Select a Graph Type'));
    }
  }
}

class PipelineTabContent extends StatefulWidget {
  const PipelineTabContent({
    super.key,
  });

  @override
  State<PipelineTabContent> createState() => _PipelineTabContentState();
}

class _PipelineTabContentState extends State<PipelineTabContent> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(builder: (context, provider, child) {
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
                          final List<Map<String, dynamic>> filterOptions = [
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
                                children: filterOptions.map((filter) {
                                  return ListTile(
                                    leading: Icon(filter["icon"]),
                                    title: Text(filter["filter"]),
                                    onTap: () {
                                      Navigator.pop(context);
                                      provider.applyFilter(filter["filter"]);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  ToggleButtons(
                    isSelected: [
                      0 == provider.selectedindexpipeline,
                      1 == provider.selectedindexpipeline,
                      2 == provider.selectedindexpipeline
                    ],
                    onPressed: (int index) {
                      setState(() {
                        provider.selectedindexpipeline = index;
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.stacked_line_chart),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.bar_chart),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.pie_chart),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              provider.selectedFilter,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Builder(
                builder: (context) {
                  switch (provider.selectedindexpipeline) {
                    case 0:
                      return LineChartWidgetCustom(
                        stageData: provider.stageOpportunityData!,
                        selectedFilter: provider.selectedFilter,
                      );
                    case 1:
                      return BarChartWidget(
                        stageData: provider.stageOpportunityData!,
                        selectedFilter: provider.selectedFilter,
                      );
                    case 2:
                      return MyPieChart(
                        selectedFilter: provider.selectedFilter,
                        stageData: provider.stageOpportunityData!,
                      );
                    default:
                      return const Center(child: Text('Select a Graph Type'));
                  }
                },
              ),
            )
          ],
        ),
      );
    });
  }
}
