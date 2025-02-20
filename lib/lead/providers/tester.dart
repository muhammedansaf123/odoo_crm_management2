import 'package:flutter/material.dart';
import 'package:odoo_crm_management/lead/providers/lead_form_provider.dart';

class LeadSelectionWidget extends StatefulWidget {
  final List<LeadItem> allLeads;
  final List<LeadItem> selectedLeads;

  LeadSelectionWidget({required this.allLeads, required this.selectedLeads});

  @override
  _LeadSelectionWidgetState createState() => _LeadSelectionWidgetState();
}

class _LeadSelectionWidgetState extends State<LeadSelectionWidget> {
  late List<LeadItem> _allLeads;
  late List<LeadItem> selectedLeads;


  @override
  void initState() {
    super.initState();
    _allLeads = widget.allLeads;
    selectedLeads = List.from(widget.selectedLeads);
  }

  void _onLeadSelectionChanged(LeadItem selectedItem) {
   
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       
      ],
    );
  }
}

