import 'package:flutter_svg/svg.dart';
import 'package:html/parser.dart';

import 'package:flutter/material.dart';
import 'package:odoo_crm_management/initilisation.dart';
import 'package:odoo_crm_management/lead/components/custom_button.dart';

import 'package:odoo_crm_management/opportunity/providers/opportunity_form_provider.dart';

import 'package:provider/provider.dart';

class OpportunityFormView extends StatefulWidget {
  final Map<dynamic, dynamic> opportunity;

  const OpportunityFormView({super.key, required this.opportunity});

  @override
  State<OpportunityFormView> createState() => _OpportunityFormState();
}

class _OpportunityFormState extends State<OpportunityFormView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final client =
        Provider.of<OdooClientManager>(context, listen: false).client;
    Provider.of<OpportunityFormProvider>(context, listen: false)
        .init(client!, widget.opportunity);

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.opportunity;

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
              child: Consumer<OpportunityFormProvider>(
                  builder: (context, provider, child) {
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
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            minimumSize:
                                                const Size(double.infinity, 48),
                                          ),
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, '/quotation_screen');
                                          },
                                          child: const Text(
                                            "New Quotation",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (provider.stageId != 4 &&
                                          provider.active == true) ...[
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              provider.markLeadAsWon(
                                                  widget.opportunity['id'],
                                                  context,
                                                  widget.opportunity);
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
                                                  double.infinity, 48),
                                            ),
                                            child: const Text(
                                              "Won",
                                              style: TextStyle(
                                                color: Colors.teal,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            provider.showBottomSheet(
                                                context, lead);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Colors.teal),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            minimumSize:
                                                const Size(double.infinity, 48),
                                          ),
                                          child: const Text(
                                            "Lost",
                                            style: TextStyle(
                                              color: Colors.teal,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {},
                                          style: ElevatedButton.styleFrom(
                                            side: const BorderSide(
                                                color: Colors.teal),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            minimumSize:
                                                const Size(double.infinity, 48),
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
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Restore Button Section (Using Consumer2 only for OpportunityFormProvider & OdooClientManager)
                                Consumer2<OpportunityFormProvider,
                                    OdooClientManager>(
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
                                if (provider.probability != null) ...[
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
                                              provider.probability!),
                                        ),
                                      ),
                                      Text(
                                        '${provider.probability!.toString()}%',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: getColorForProbability(
                                              provider.probability!),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: LinearProgressIndicator(
                                      value: provider.probability! / 100,
                                      minHeight: 8,
                                      backgroundColor: Colors.purple.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        getColorForProbability(
                                            provider.probability!),
                                      ),
                                    ),
                                  ),
                                ],
                                if (provider.active == null ||
                                    provider.probability == null) ...[
                                  const Center(
                                      child: CircularProgressIndicator()),
                                ],
                              ],
                            ),
                            const SizedBox(height: 28),
                            Center(
                              child: Text(
                                provider.data['partnerId'] != null &&
                                        provider.data['partnerId'] is List &&
                                        provider.data['partnerId'].length > 1
                                    ? '${provider.data['partnerId'][1]}'
                                    : '',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerDetailRow(
                                'Salesperson:',
                                provider.data['userId'] is List &&
                                        provider.data['userId'].length > 1
                                    ? provider.data['userId'][1].toString()
                                    : 'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerDetailRow(
                                'Sales Team:',
                                provider.data['teamId'] is List &&
                                        provider.data['teamId'].length > 1
                                    ? provider.data['teamId'][1].toString()
                                    : 'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerDetailRow(
                                'Contact Name:',
                                provider.data['contactName']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerDetailRow(
                                'Email:',
                                provider.data['emailFrom']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerDetailRow(
                                'Email CC:',
                                provider.data['emailcc']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerDetailRow(
                                'Job Position:',
                                lead['function']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerDetailRow(
                                'Phone:',
                                provider.data['phone']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerDetailRow(
                                'Mobile:',
                                provider.data['mobile']?.toString() ??
                                    'Not Available'),
                            const SizedBox(
                              height: 10,
                            ),
                            buildPriorityStars(
                                'Priority:',
                                int.tryParse(
                                        provider.data['priority']?.toString() ??
                                            '0') ??
                                    0),
                            const SizedBox(
                              height: 10,
                            ),
                            buildCustomerTagsRow(
                                'Tags:',
                                provider.data['tagIds'] != null
                                    ? provider.data['tagIds'].join(', ')
                                    : 'No Tags Available'),
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
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      lead['description'] is String &&
                                              lead['description'].isNotEmpty
                                          ? parseHtmlString(lead['description'])
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
                                        buildCustomerDetailRow(
                                            'Bounce:',
                                            lead['message_bounce']
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
                                        buildCustomerDetailRow(
                                            'Assignment Date:',
                                            lead['date_open']?.toString() ??
                                                'Not Available'),
                                        buildCustomerDetailRow(
                                            'Closed Date:',
                                            lead['date_closed']?.toString() ??
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
                                        buildCustomerDetailRow(
                                          'Campaign:',
                                          (lead['campaign_id'] != null &&
                                                  lead['campaign_id'].length >
                                                      1)
                                              ? lead['campaign_id'][1]
                                              : 'Not Available',
                                        ),
                                        buildCustomerDetailRow(
                                          'Medium:',
                                          (lead['medium_id'] != null &&
                                                  lead['medium_id'].length > 1)
                                              ? lead['medium_id'][1]
                                              : 'Not Available',
                                        ),
                                        buildCustomerDetailRow(
                                          'Source:',
                                          (lead['source_id'] != null &&
                                                  lead['source_id'].length > 1)
                                              ? lead['source_id'][1]
                                              : 'Not Available',
                                        ),
                                        buildCustomerDetailRow(
                                          'Referred By:',
                                          lead['referred']?.toString() ??
                                              'Not Available',
                                        ),

                                        // buildCustomerDetailRow(
                                        //     'Campaign:',
                                        //     lead['campaign_id'][1] ??
                                        //         'Not Available'),
                                        // buildCustomerDetailRow('Medium:',
                                        //     lead['medium_id'][1] ?? 'Not Available'),
                                        // buildCustomerDetailRow('Source:',
                                        //     lead['source_id'][1] ?? 'Not Available'),
                                        // buildCustomerDetailRow(
                                        //   'Referred By:',
                                        //   lead['referred']?.toString() ??
                                        //       'Not Available',
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (provider.active == false) ...[
                      Positioned(
                        top: -20,
                        right: -20,
                        child: SizedBox(
                            height: 180,
                            width: 180,
                            child: SvgPicture.asset(
                              "assets/lost.svg",
                            )),
                      )
                    ],
                    if (provider.stageId == 4 && provider.active == true)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: SizedBox(
                            height: 140,
                            width: 140,
                            child: SvgPicture.asset(
                              "assets/won.svg",
                            )),
                      )
                  ],
                );
              }),
            ),
    );
  }

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? '';
  }

  Widget buildCustomerDetailRow(String label, String? value) {
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
                  value == null || value == 'false' ? 'None' : value,
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
            value != null && label == 'Address:'
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

  Widget buildCustomerTagsRow(
    String label,
    String? value,
  ) {
    return Consumer<OpportunityFormProvider>(
        builder: (context, provider, child) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
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
        ),
      );
    });
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
