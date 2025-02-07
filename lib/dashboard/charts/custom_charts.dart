import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fl_chart/fl_chart.dart';

class MyPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> stageData;
  final String selectedFilter;

  MyPieChart({required this.stageData, required this.selectedFilter});

  @override
  _MyPieChartState createState() => _MyPieChartState();
}

class _MyPieChartState extends State<MyPieChart> {
  int? _selectedIndex; // Store the tapped index

  @override
  Widget build(BuildContext context) {
    return !_areAllValuesZero()
        ? SfCircularChart(
            series: <CircularSeries>[
              PieSeries<PieChartData, String>(
                dataSource: _getPieChartData(),
                xValueMapper: (PieChartData data, _) => data.stage,
                yValueMapper: (PieChartData data, _) => data.value,
                pointColorMapper: (PieChartData data, _) => data.color,
                dataLabelMapper: (PieChartData data, _) =>
                    '${data.stage}\n${data.value.toInt()}', // Display stage & value
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  textStyle:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                explode: true, // Enable explosion
                explodeIndex:
                    _selectedIndex, // Dynamically change explode index
                onPointTap: (ChartPointDetails details) {
                  setState(() {
                    _selectedIndex = details.pointIndex; // Store tapped index
                  });
                },
              ),
            ],
          )
        : Container(
            color: Colors.red,
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
    _areAllValuesZero();
    print("filtered${_areAllValuesZero()}");
    return widget.stageData.map((data) {
      return PieChartData(
        stage: data['stage'],
        value: (data[dataKey] ?? 0).toDouble(),
        color: Colors.primaries[
            widget.stageData.indexOf(data) % Colors.primaries.length],
      );
    }).toList();
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
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      series: <CartesianSeries<BarData, String>>[
        ColumnSeries<BarData, String>(
          dataSource: _getBarChartData(),
          xValueMapper: (BarData data, _) => data.stage,
          yValueMapper: (BarData data, _) => data.value,
          pointColorMapper: (BarData data, _) => data.color,
          dataLabelMapper: (BarData data, _) =>
              '${data.stage}\n${data.value.toInt()}', // Display stage & value
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          onPointTap: (ChartPointDetails details) {},
        ),
      ],
    );
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

    return stageData.map((data) {
      return BarData(
        stage: data['stage'],
        value: (data[dataKey] ?? 0).toDouble(),
        color:
            Colors.primaries[stageData.indexOf(data) % Colors.primaries.length],
      );
    }).toList();
  }
}

class BarData {
  final String stage;
  final double value;
  final Color color;

  BarData({required this.stage, required this.value, required this.color});
}

class LineChartWidgetcustom extends StatelessWidget {
  final List<Map<String, dynamic>> stageData;
  final String selectedFilter;

  const LineChartWidgetcustom(
      {super.key, required this.stageData, required this.selectedFilter});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      series: <CartesianSeries>[
        SplineSeries<LineData, String>(
          dataSource: _getLineChartData(),
          xValueMapper: (LineData data, _) => data.stage,
          yValueMapper: (LineData data, _) => data.value,
          pointColorMapper: (LineData data, _) => data.color,
          dataLabelMapper: (LineData data, _) =>
              '${data.stage}\n${data.value.toInt()}',
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          onPointTap: (ChartPointDetails details) {},
        ),
      ],
    );
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

    print("current value is ${stageData.map((data) {
      return LineData(
        stage: data['stage'],
        value: (data[dataKey] ?? 0).toDouble(),
        color:
            Colors.primaries[stageData.indexOf(data) % Colors.primaries.length],
      );
    }).toList()}");

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
