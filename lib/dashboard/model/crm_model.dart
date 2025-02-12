class LeadCrmModel {
  final int id;
  final DateTime createDate;
  final String stageName;
  final double dayClose;
  final double expectedRevenue;
  final double recurringRevenueMonthly;
  final double probability;
  final double recurringRevenueMonthlyProrated;
  final double recurringRevenueProrated;
  final double proratedRevenue;
  final double recurringRevenue;

  LeadCrmModel({
    required this.id,
    required this.createDate,
    required this.stageName,
    required this.dayClose,
    required this.expectedRevenue,
    required this.recurringRevenueMonthly,
    required this.probability,
    required this.recurringRevenueMonthlyProrated,
    required this.recurringRevenueProrated,
    required this.proratedRevenue,
    required this.recurringRevenue,
  });

  /// Factory constructor to create an instance from JSON (Odoo response)
  factory LeadCrmModel.fromJson(Map<String, dynamic> json) {
  
    return LeadCrmModel(
      id: json['id'] ?? 0,
      createDate:
          DateTime.tryParse(json['create_date'] ?? '') ?? DateTime.now(),
      stageName: json['stage_id'] != null && json['stage_id'] is List
          ? json['stage_id'][1]
          : 'Unknown',
      dayClose: (json['day_close']).toDouble(),
      expectedRevenue: (json['expected_revenue'] ?? 0.0).toDouble(),
      recurringRevenueMonthly:
          (json['recurring_revenue_monthly'] ?? 0.0).toDouble(),
      probability: (json['probability'] ?? 0.0).toDouble(),
      recurringRevenueMonthlyProrated:
          (json['recurring_revenue_monthly_prorated'] ?? 0.0).toDouble(),
      recurringRevenueProrated:
          (json['recurring_revenue_prorated'] ?? 0.0).toDouble(),
      proratedRevenue: (json['prorated_revenue'] ?? 0.0).toDouble(),
      recurringRevenue: (json['recurring_revenue'] ?? 0.0).toDouble(),
    );

  
  }
}

class Opportunity {
  final int id;
  final DateTime createDate;
  final String stageName;
  final double dayClose;
  final double expectedRevenue;
  final double recurringRevenueMonthly;
  final double probability;
  final double recurringRevenueMonthlyProrated;
  final double recurringRevenueProrated;
  final double proratedRevenue;
  final double recurringRevenue;

  Opportunity({
    required this.id,
    required this.createDate,
    required this.stageName,
    required this.dayClose,
    required this.expectedRevenue,
    required this.recurringRevenueMonthly,
    required this.probability,
    required this.recurringRevenueMonthlyProrated,
    required this.recurringRevenueProrated,
    required this.proratedRevenue,
    required this.recurringRevenue,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
      print("ansaf${json['stage_id']}");
    return Opportunity(
      id: json['id'] ?? 0,
      createDate: DateTime.parse(json['create_date']),
      stageName: json['stage_id'] != null && json['stage_id'] is List
          ? json['stage_id'][1]
          : 'Unknown',
      dayClose: (json['day_close']).toDouble(),
      expectedRevenue: (json['expected_revenue'] ?? 0).toDouble(),
      recurringRevenueMonthly:
          (json['recurring_revenue_monthly'] ?? 0).toDouble(),
      probability: (json['probability'] ?? 0).toDouble(),
      recurringRevenueMonthlyProrated:
          (json['recurring_revenue_monthly_prorated'] ?? 0).toDouble(),
      recurringRevenueProrated:
          (json['recurring_revenue_prorated'] ?? 0).toDouble(),
      proratedRevenue: (json['prorated_revenue'] ?? 0).toDouble(),
      recurringRevenue: (json['recurring_revenue'] ?? 0).toDouble(),
    );
  }
}
