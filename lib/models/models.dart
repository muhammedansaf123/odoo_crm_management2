class LeadItem {
  final int id;
  final String? contactname;
  final String? name;
  final String? email;
  final String? stage;
  final String? salesperson;
  final String? createdon;
  LeadItem(
      {required this.id,
      required this.contactname,
      required this.name,
      required this.createdon,
      required this.email,
      required this.salesperson,
      required this.stage});

  @override
  bool operator ==(Object other) => other is LeadItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class CustomerItem {
  final int id;
  final String name;

  CustomerItem({required this.id, required this.name});

  @override
  String toString() => name;
}

class SalesPersonItem {
  final int? id;
  final String name;
  final int teamid;
  final String teamName;
  SalesPersonItem(
      {required this.id,
      required this.name,
      required this.teamid,
      required this.teamName});

  @override
  String toString() => name;
}