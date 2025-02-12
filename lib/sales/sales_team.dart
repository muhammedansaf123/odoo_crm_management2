import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesTeam extends StatefulWidget {
  const SalesTeam({super.key});

  @override
  State<SalesTeam> createState() => _SalesTeamState();
}

class _SalesTeamState extends State<SalesTeam> {
  int? userId;
  OdooClient? client;
  String url = "";
  List<BarChartGroupData> barChartData = [];
  List<dynamic> values = [];
  int opportunities_count = 0;
  String opportunities_amount = "";
  int opportunities_overdue_count = 0;
  String opportunities_overdue_amount = "";
  List<dynamic> salesTeams = [];
  int? selectedTeamId;
  MemoryImage? companyPicUrl;
  String? companyLogo;
  

  @override
  void initState() {
    super.initState();
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
    await getSalesTeams();
  }

  Future<void> getSalesTeams() async {
    try {
      final response = await client?.callKw({
        'model': 'crm.team',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {},
      });

      setState(() {
        salesTeams = response ?? [];
      });

      if (salesTeams.isNotEmpty) {
        selectedTeamId = salesTeams[0]['id'];
        getSalesTeamDetails();
      }
    } catch (e) {
      print('Error fetching sales teams: $e');
    }
  }

  Future<void> getSalesTeamDetails() async {
    if (selectedTeamId == null) return;

    try {
      final response = await client?.callKw({
        'model': 'crm.team',
        'method': 'read',
        'args': [
          [selectedTeamId]
        ],
        'kwargs': {},
      });

      final rawDashboardData = response?[0]['dashboard_graph_data'];
      final dashboardData = rawDashboardData is String
          ? jsonDecode(rawDashboardData)
          : rawDashboardData ?? [];
      opportunities_count = response?[0]['opportunities_count'];
      opportunities_amount = response![0]['opportunities_amount'].toString();
      opportunities_overdue_count = response?[0]['opportunities_overdue_count'];
      opportunities_overdue_amount =
          response![0]['opportunities_overdue_amount'].toString();

      print('Sales team dashboard data: $dashboardData');

      if (dashboardData is List && dashboardData.isNotEmpty) {
        for (var item in dashboardData) {
          values = item['values'] ?? [];
        }
      }

      setState(() {
        barChartData = values
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final item = entry.value;

              try {
                final rawValue = item['value'];

                if (rawValue == null ||
                    rawValue is! num ||
                    rawValue.isNaN ||
                    !rawValue.isFinite) {
                  throw Exception('Invalid value at index $index: $rawValue');
                }

                final numericValue = rawValue.toDouble();

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: numericValue,
                      width: 25,
                      color: Colors
                          .primaries[index % Colors.primaries.length].shade200,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                );
              } catch (e) {
                print('Skipping invalid item at index $index: $e');
                return null;
              }
            })
            .whereType<BarChartGroupData>()
            .toList();
      });

      print("Bar chart data: $barChartData");
    } catch (e) {
      print('Error fetching sales team details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales Team',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: DropdownButton<int>(
              value: selectedTeamId,
              onChanged: (int? newTeamId) {
                setState(() {
                  selectedTeamId = newTeamId;
                  getSalesTeamDetails();
                });
              },
              items: salesTeams.map<DropdownMenuItem<int>>((team) {
                return DropdownMenuItem<int>(
                  value: team['id'],
                  child: Text(
                    team['name'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              dropdownColor: Colors.purple,
            ),
          ),
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
              title: const Text('Opportunity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal)),
              onTap: () {
                Navigator.pushNamed(context, '/opportunity');
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Sales Team Performance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 20),
            if (barChartData.isNotEmpty)
              SizedBox(
                height: 400,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: barChartData,
                    minY: 2,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value % 2 == 0 && value >= 2) {
                              return Text(value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10));
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < values.length) {
                              return Text(
                                values[index]['label'] ?? 'Unknown',
                                style: const TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.bold),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              )
            else
              const Text('No data available to display.'),
            const SizedBox(height: 20),
            if (opportunities_count != 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      print(selectedTeamId);
                      print("444444444444444444444444444");
                      Navigator.pushNamed(context, '/opportunity', arguments: {
                        'open': true,
                        'selectedTeamId': selectedTeamId
                      });
                    },
                    child: Text(
                      '${opportunities_count} Open Opportunities',
                      style: TextStyle(
                          color: Colors.teal,
                          fontSize: 18,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                  Text(
                    "${opportunities_amount}",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (opportunities_overdue_count != 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/opportunity', arguments: {
                        'overDue': true,
                        'selectedTeamId': selectedTeamId
                      });
                    },
                    child: Text(
                      '${opportunities_overdue_count} Overdue Opportunity',
                      style: TextStyle(
                          color: Colors.teal,
                          fontSize: 18,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                  Text(
                    "${opportunities_overdue_amount}",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/opportunity');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Pipeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white, // Text color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
