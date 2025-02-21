import 'package:flutter_svg/svg.dart';

import 'package:flutter/material.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/lead/components/custom_button.dart';
import 'package:odoo_crm_management/lead/providers/lead_form_provider.dart';

import 'package:provider/provider.dart';

class LeadFormView extends StatefulWidget {
  final Map<dynamic, dynamic> lead;

  const LeadFormView({
    super.key,
    required this.lead,
  });

  @override
  State<LeadFormView> createState() => _LeadFormViewState();
}

class _LeadFormViewState extends State<LeadFormView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Provider.of<LeadFormProvider>(context, listen: false)
        .init(widget.lead, context);
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

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
              child: Consumer2<LeadFormProvider, OdooClientManager>(
                  builder: (context, provider, odooprovider, child) {
                return Stack(
                  children: [
                    Card(
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
                                if (provider.active == true) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Consumer<LeadFormProvider>(
                                            builder:
                                                (context, provider, child) {
                                          return CustomButton(
                                              text: "Convert To Oportunity",
                                              onPressed: () {
                                                provider.getDuplicatedLeads(
                                                    lead['id'], context);
                                                provider.showConversionPopup(
                                                    context, widget.lead);
                                              });
                                        }),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            side: const BorderSide(
                                              color: Colors.teal,
                                            ),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            minimumSize: const Size(
                                                double.infinity,
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
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                        child: Consumer<LeadFormProvider>(
                                            builder:
                                                (context, provider, child) {
                                          return ElevatedButton(
                                            onPressed: () {
                                              provider.showBottomSheet(
                                                  context, widget.lead);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              side: const BorderSide(
                                                  color: Colors.teal),
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              minimumSize: const Size(
                                                  double.infinity,
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
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 20),

                                // Restore Button Section (Using Consumer2 only for OpportunityFormProvider & OdooClientManager)
                                Consumer2<LeadFormProvider, OdooClientManager>(
                                  builder: (context, opportunityProvider,
                                      odooProvider, child) {
                                    if (opportunityProvider.active == false) {
                                      return Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: CustomButton(
                                                  text: "Restore",
                                                  onPressed: () {
                                                    opportunityProvider.restore(
                                                        odooProvider.client!,
                                                        lead,
                                                        context);
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 40),
                                        ],
                                      );
                                    } else {
                                      return const SizedBox();
                                    }
                                  },
                                ),

                                // Probability Section
                                if (provider.probablity != null &&
                                    provider.active != null) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Probability:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: getColorForProbability(
                                              provider.probablity!),
                                        ),
                                      ),
                                      Text(
                                        '${provider.probablity!.toString()}%',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: getColorForProbability(
                                              provider.probablity!),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: LinearProgressIndicator(
                                      value: provider.probablity! / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.purple.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        getColorForProbability(
                                            provider.probablity!),
                                      ),
                                    ),
                                  ),
                                ],
                                if (provider.active == null ||
                                    provider.probablity == null) ...[
                                  const Center(
                                      child: CircularProgressIndicator()),
                                ],
                              ],
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: Text(
                                lead['partner_id'] != null &&
                                        lead['partner_id'] is List &&
                                        lead['partner_id'].length > 1
                                    ? '${lead['partner_id'][1]}'
                                    : '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            CustomRow(
                                label: 'Company Name:',
                                value: lead['partner_name']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Address:',
                                value: lead['street']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Salesperson:',
                                value: lead['user_id'] is List &&
                                        lead['user_id'].length > 1
                                    ? lead['user_id'][1].toString()
                                    : 'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Sales Team:',
                                value: lead['team_id'] is List &&
                                        lead['team_id'].length > 1
                                    ? lead['team_id'][1].toString()
                                    : 'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Contact Name:',
                                value: lead['contact_name']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Email:',
                                value: lead['email_from']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Email CC:',
                                value: lead['email_cc']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Job Position:',
                                value: lead['function']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Phone:',
                                value: lead['phone']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomRow(
                                label: 'Mobile:',
                                value: lead['mobile']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildPriorityStars(
                                'Priority:',
                                int.tryParse(
                                        lead['priority']?.toString() ?? '0') ??
                                    0),
                            const SizedBox(
                              height: 10,
                            ),
                            Consumer<LeadFormProvider>(
                                builder: (context, provider, child) {
                              print("topppppptags ${provider.leadTags}");
                              return CustomTagRow(
                                  label: 'Tags:',
                                  value: provider.leadTags.isNotEmpty
                                      ? provider.leadTags.join(', ')
                                      : 'No Tags Available');
                            }),
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
                              child: Consumer<LeadFormProvider>(
                                  builder: (context, provider, child) {
                                return TabBarView(
                                  controller: _tabController,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        lead['description'] is String &&
                                                lead['description'].isNotEmpty
                                            ? provider.parseHtmlString(
                                                lead['description'])
                                            : 'No description available',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'EMAIL',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                          CustomRow(
                                              label: 'Bounce:',
                                              value: lead['message_bounce']
                                                      ?.toString() ??
                                                  'Not Available'),
                                          const SizedBox(height: 20),
                                          const Text(
                                            'ANALYSIS',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                          CustomRow(
                                              label: 'Assignment Date:',
                                              value: lead['date_open']
                                                      ?.toString() ??
                                                  'Not Available'),
                                          CustomRow(
                                              label: 'Closed Date:',
                                              value: lead['date_closed']
                                                      ?.toString() ??
                                                  'Not Available'),
                                          const SizedBox(height: 20),
                                          const Text(
                                            'MARKETING',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                            ),
                                          ),
                                          CustomRow(
                                              label: 'Campaign:',
                                              value: lead['campaign_id'] == null
                                                  ? 'Not Available'
                                                  : lead['campaign_id'][1] ??
                                                      'Not Available'),
                                          CustomRow(
                                              label: 'Medium:',
                                              value: lead['medium_id'] == null
                                                  ? 'Not Available'
                                                  : lead['medium_id'][1] ??
                                                      'Not Available'),
                                          CustomRow(
                                              label: 'Source:',
                                              value: lead['source_id'] == null
                                                  ? 'Not Available'
                                                  : lead['source_id'][1] ??
                                                      'Not Available'),
                                          CustomRow(
                                            label: 'Referred By:',
                                            value: lead['referred'] == null
                                                ? 'Not Available'
                                                : lead['referred']
                                                        ?.toString() ??
                                                    'Not Available',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Consumer<LeadFormProvider>(
                        builder: (context, provider, child) {
                      if (provider.active == false) {
                        return Positioned(
                          top: -20,
                          right: -20,
                          child: SizedBox(
                              height: 180,
                              width: 180,
                              child: SvgPicture.asset(
                                "assets/lost.svg",
                               
                              )),
                        );
                      } else {
                        return SizedBox();
                      }
                    }),
                  ],
                );
              }),
            ),
    );
  }

  Widget buildPriorityStars(String label, int priority) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
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

class CustomRow extends StatelessWidget {
  final String label;
  final String value;
  const CustomRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Text(
                  value == 'false' ? 'None' : value,
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
            label == 'Address:'
                ? Container(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: TextField(
                        controller: TextEditingController(text: value),
                        maxLines: 2,
                        decoration: const InputDecoration(
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
}

class CustomTagRow extends StatelessWidget {
  final String label;
  final String value;

  const CustomTagRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Consumer<LeadFormProvider>(builder: (context, provider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            provider.leadTags.isNotEmpty
                ? provider.leadTags.length > 2
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          (provider.leadTags.length / 2)
                              .ceil(), // Calculate the number of rows
                          (index) {
                            final start = index * 2;
                            final end = start + 2;
                            final tagPair = provider.leadTags.sublist(
                                start,
                                end > provider.leadTags.length
                                    ? provider.leadTags.length
                                    : end);

                            return Row(
                              children: tagPair.map((tag) {
                                final color = Colors.primaries[
                                    provider.leadTags.indexOf(tag) %
                                        Colors.primaries.length];
                                return Container(
                                  margin: const EdgeInsets.only(
                                      right: 5.0, bottom: 4.0),
                                  padding: const EdgeInsets.symmetric(
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
                        children: provider.leadTags.map((tag) {
                          final color = Colors.primaries[
                              provider.leadTags.indexOf(tag) %
                                  Colors.primaries.length];
                          return Container(
                            padding: const EdgeInsets.symmetric(
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
                : const SizedBox(),
          ],
        );
      }),
    );
  }
}
