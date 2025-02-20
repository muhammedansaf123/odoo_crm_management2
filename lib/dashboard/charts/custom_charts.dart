import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MyPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> stageData;
  final String selectedFilter;

  MyPieChart({required this.stageData, required this.selectedFilter});

  @override
  _MyPieChartState createState() => _MyPieChartState();
}

class _MyPieChartState extends State<MyPieChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return widget.stageData.isEmpty
        ? Center(
            child: Image.asset(
              "assets/odoonodata.png",
              scale: 4,
            ),
          )
        : !_areAllValuesZero()
            ? Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: SfCircularChart(
                      legend: const Legend(
                          position: LegendPosition.top, isVisible: true),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CircularSeries>[
                        PieSeries<PieChartData, String>(
                          dataSource: _getPieChartData(),
                          xValueMapper: (PieChartData data, _) => data.stage,
                          yValueMapper: (PieChartData data, _) => data.value,
                          pointColorMapper: (PieChartData data, _) =>
                              data.color,
                          dataLabelMapper: (PieChartData data, _) =>
                              '${data.stage}\n${data.value.toInt()}',
                          dataLabelSettings: const DataLabelSettings(
                            labelPosition: ChartDataLabelPosition.inside,
                            isVisible: true,
                            offset:
                                Offset(100, 50), // Move labels slightly upward
                            textStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          explode: true,
                          explodeIndex: _selectedIndex,
                          radius: '100%',
                          strokeColor: Colors.white,
                          strokeWidth: 3,
                          onPointTap: (ChartPointDetails details) {
                            setState(() {
                              _selectedIndex = details.pointIndex;
                            });
                          },
                          animationDuration: 1500,
                          enableTooltip: true,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                child: Image.asset(
                  "assets/odoonodata.png",
                  scale: 4,
                ),
              );
  }

  bool _areAllValuesZero() {
    Map<String, String> filterKeyMap = {
      "Days to Close": "total_day_close",
      "count": "Count",
      "Expected Revenue": "total_expected_revenue",
      "Expected MRR": "recurring_revenue_monthly",
      "Probability": "probability",
      "Prorated MRR": "recurring_revenue_monthly_prorated",
      "Prorated Recurring Revenue": "recurring_revenue_prorated",
      "Prorated Revenue": "prorated_revenue",
      "Recurring Revenue": "recurring_revenue",
    };

    String dataKey = filterKeyMap[widget.selectedFilter] ?? "count";

    List<dynamic> values = widget.stageData.map((data) {
      return (data[dataKey] ?? 0).toDouble();
    }).toList();

    return values.every((value) => value == 0.0);
  }

  List<PieChartData> _getPieChartData() {
    Map<String, String> filterKeyMap = {
      "Days to Close": "total_day_close",
      "count": "Count",
      "Expected Revenue": "total_expected_revenue",
      "Expected MRR": "recurring_revenue_monthly",
      "Probability": "probability",
      "Prorated MRR": "recurring_revenue_monthly_prorated",
      "Prorated Recurring Revenue": "recurring_revenue_prorated",
      "Prorated Revenue": "prorated_revenue",
      "Recurring Revenue": "recurring_revenue",
    };

    String dataKey = filterKeyMap[widget.selectedFilter] ?? "count";
    return widget.stageData.map((data) {
      return PieChartData(
        stage: data['stage'],
        value: (data[dataKey] ?? 0).toDouble(),
        color: _getGradientColor(widget.stageData.indexOf(data)),
      );
    }).toList();
  }

  Color _getGradientColor(int index) {
    List<Color> gradientColors = [
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.green.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
    ];
    return gradientColors[index % gradientColors.length];
  }
}

class PieChartData {
  final String stage;
  final double value;
  final Color color;

  PieChartData({required this.stage, required this.value, required this.color});
}

class BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stageData;
  final String selectedFilter;

  BarChartWidget({required this.stageData, required this.selectedFilter});

  @override
  Widget build(BuildContext context) {
    return stageData.isEmpty
? Center(
            child: Image.asset(
              "assets/odoonodata.png",
              scale: 4,
            ),
          )
        : !_areAllValuesZero()
            ? Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: SfCartesianChart(
                      primaryXAxis: CategoryAxis(
                        axisLine: const AxisLine(width: 2, color: Colors.grey),
                        majorGridLines: const MajorGridLines(width: 0),
                        labelStyle: TextStyle(
                            fontSize: 14, color: Colors.blueGrey[800]),
                      ),
                      primaryYAxis: NumericAxis(
                        axisLine: const AxisLine(width: 2, color: Colors.grey),
                        majorGridLines:
                            MajorGridLines(width: 1, color: Colors.grey[300]),
                        labelStyle: TextStyle(
                            fontSize: 14, color: Colors.blueGrey[800]),
                      ),
                      series: <CartesianSeries<BarData, String>>[
                        ColumnSeries<BarData, String>(
                          dataSource: _getBarChartData(),
                          xValueMapper: (BarData data, _) => data.stage,
                          yValueMapper: (BarData data, _) => data.value,
                          pointColorMapper: (BarData data, _) => data.color,
                          dataLabelMapper: (BarData data, _) =>
                              '${data.stage}\n${data.value.toInt()}',
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          borderRadius: BorderRadius.circular(5),
                          enableTooltip: true,
                          animationDuration: 1000,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/odoonodata.png",
                      scale: 4,
                    ),
                  ],
                ),
              );
  }

  bool _areAllValuesZero() {
    Map<String, String> filterKeyMap = {
      "Days to Close": "total_day_close",
      "count": "Count",
      "Expected Revenue": "total_expected_revenue",
      "Expected MRR": "recurring_revenue_monthly",
      "Probability": "probability",
      "Prorated MRR": "recurring_revenue_monthly_prorated",
      "Prorated Recurring Revenue": "recurring_revenue_prorated",
      "Prorated Revenue": "prorated_revenue",
      "Recurring Revenue": "recurring_revenue",
    };

    String dataKey = filterKeyMap[selectedFilter] ?? "count";

    List<dynamic> values = stageData.map((data) {
      return (data[dataKey] ?? 0).toDouble();
    }).toList();

    return values.every((value) => value == 0.0);
  }

  List<BarData> _getBarChartData() {
    Map<String, String> filterKeyMap = {
      "Days to Close": "total_day_close",
      "count": "Count",
      "Expected Revenue": "total_expected_revenue",
      "Expected MRR": "recurring_revenue_monthly",
      "Probability": "probability",
      "Prorated MRR": "recurring_revenue_monthly_prorated",
      "Prorated Recurring Revenue": "recurring_revenue_prorated",
      "Prorated Revenue": "prorated_revenue",
      "Recurring Revenue": "recurring_revenue",
    };

    String dataKey = filterKeyMap[selectedFilter] ?? "count";

    final List<Color> customColors = [
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.green.shade400,
      Colors.red.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
    ];

    return stageData.map((data) {
      return BarData(
        id: 0,
        stage: data['stage'],
        value: (data[dataKey] ?? 0).toDouble(),
        color: customColors[stageData.indexOf(data) % customColors.length],
      );
    }).toList();
  }
}

class BarData {
  final String stage;
  final double value;
  final Color color;
  final int id;
  BarData({
    required this.stage,
    required this.value,
    required this.color,
    required this.id,
  });
}

class LineChartWidgetCustom extends StatelessWidget {
  final List<Map<String, dynamic>> stageData;
  final String selectedFilter;

  const LineChartWidgetCustom(
      {super.key, required this.stageData, required this.selectedFilter});

  @override
  Widget build(BuildContext context) {
    return stageData.isEmpty
        ? Center(
            child: Image.asset(
              "assets/odoonodata.png",
              scale: 4,
            ),
          )
        : !_areAllValuesZero()
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Expanded(
                    child: SfCartesianChart(
                      backgroundColor: Colors.grey[50], // Light background
                      primaryXAxis: const CategoryAxis(),
                      primaryYAxis: const NumericAxis(),
                      series: <CartesianSeries>[
                        SplineSeries<LineData, String>(
                          dataSource: _getLineChartData(),
                          xValueMapper: (LineData data, _) => data.stage,
                          yValueMapper: (LineData data, _) => data.value,
                          pointColorMapper: (LineData data, _) => data.color,
                          dataLabelMapper: (LineData data, _) =>
                              '${data.stage}\n${data.value.toInt()}',
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                            labelAlignment: ChartDataLabelAlignment.outer,
                            labelPosition: ChartDataLabelPosition.outside,
                            connectorLineSettings: ConnectorLineSettings(
                                width: 1, color: Colors.grey.withOpacity(0.6)),
                          ),
                          onPointTap: (ChartPointDetails details) {},
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Center(
                child: Image.asset(
                  "assets/odoonodata.png",
                  scale: 4,
                ),
              );
  }

  bool _areAllValuesZero() {
    Map<String, String> filterKeyMap = {
      "Days to Close": "total_day_close",
      "count": "Count",
      "Expected Revenue": "total_expected_revenue",
      "Expected MRR": "recurring_revenue_monthly",
      "Probability": "probability",
      "Prorated MRR": "recurring_revenue_monthly_prorated",
      "Prorated Recurring Revenue": "recurring_revenue_prorated",
      "Prorated Revenue": "prorated_revenue",
      "Recurring Revenue": "recurring_revenue",
    };

    String dataKey = filterKeyMap[selectedFilter] ?? "count";

    List<dynamic> values = stageData.map((data) {
      return (data[dataKey] ?? 0).toDouble();
    }).toList();

    return values.every((value) => value == 0.0);
  }

  List<LineData> _getLineChartData() {
    Map<String, String> filterKeyMap = {
      "Days to Close": "total_day_close",
      "count": "Count",
      "Expected Revenue": "total_expected_revenue",
      "Expected MRR": "recurring_revenue_monthly",
      "Probability": "probability",
      "Prorated MRR": "recurring_revenue_monthly_prorated",
      "Prorated Recurring Revenue": "recurring_revenue_prorated",
      "Prorated Revenue": "prorated_revenue",
      "Recurring Revenue": "recurring_revenue",
    };

    String dataKey = filterKeyMap[selectedFilter] ?? "count";

    return stageData.map((data) {
      return LineData(
        stage: data['stage'],
        value: (data[dataKey] ?? 0).toDouble(),
        color:
            Colors.primaries[stageData.indexOf(data) % Colors.primaries.length],
      );
    }).toList();
  }
}

class LineData {
  final String stage;
  final double value;
  final Color color;

  LineData({required this.stage, required this.value, required this.color});
}
