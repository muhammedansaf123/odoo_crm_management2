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
    return SfCircularChart(
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
            textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          explode: true, // Enable explosion
          explodeIndex: _selectedIndex, // Dynamically change explode index
          onPointTap: (ChartPointDetails details) {
            setState(() {
              _selectedIndex = details.pointIndex; // Store tapped index
            });
          },
        ),
      ],
    );
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

class LineChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stageData;
  final String selectedFilter;

  const LineChartWidget({
    Key? key,
    required this.stageData,
    required this.selectedFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: _getTitlesData(),
        borderData: FlBorderData(show: true),
        lineBarsData: [_getLineChartBarData()],
      ),
    );
  }

  /// Configures the titles for X-axis
  FlTitlesData _getTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, meta) => _getBottomTitle(value),
        ),
      ),
    );
  }

  /// Generates X-axis titles
  Widget _getBottomTitle(double value) {
    if (value.toInt() < 0 || value.toInt() >= stageData.length) {
      return const SizedBox.shrink();
    }
    return Text(
      stageData[value.toInt()]['stage'],
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
    );
  }

  /// Generates the line chart data
  LineChartBarData _getLineChartBarData() {
    return LineChartBarData(
      spots: _getLineGraphData(),
      isCurved: true,
      color: Colors.blue,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  /// Maps stage data to line graph data
  List<FlSpot> _getLineGraphData() {
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
print("stagedata is $stageData");
    return stageData.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value[dataKey] ?? 0).toDouble(), // Handle null values
      );
    }).toList();
  }
}

class BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stageData;
  final String selectedFilter;

  const BarChartWidget({
    Key? key,
    required this.stageData,
    required this.selectedFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: true),
        titlesData: _getTitlesData(),
        barGroups: _getBarChartData(),
      ),
    );
  }

  /// Configures the X-axis titles
  FlTitlesData _getTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => _getBottomTitle(value),
        ),
      ),
    );
  }

  /// Generates X-axis labels
  Widget _getBottomTitle(double value) {
    if (value.toInt() < 0 || value.toInt() >= stageData.length) {
      return const SizedBox.shrink();
    }
    return Text(
      stageData[value.toInt()]['stage'],
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
    );
  }

  /// Generates bar chart data
  List<BarChartGroupData> _getBarChartData() {
    Map<String, String> filterKeyMap = {
      "Days to Close": "days_to_convert",
      "Expected Revenue": "total_expected_revenue",
      "Expected MRR": "recurring_revenue_monthly",
      "Probability": "probability",
      "Prorated MRR": "recurring_revenue_monthly_prorated",
      "Prorated Recurring Revenue": "recurring_revenue_prorated",
      "Prorated Revenue": "prorated_revenue",
      "Recurring Revenue": "recurring_revenue",
    };

    String dataKey = filterKeyMap[selectedFilter] ?? "count";

    return stageData.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: (entry.value[dataKey] ?? 0).toDouble(), // Ensures null safety
            borderRadius: BorderRadius.zero,
            color: Colors.blue,
          ),
        ],
      );
    }).toList();
  }
}
