import 'package:flutter/material.dart';

class QuotationScreen extends StatelessWidget {
  const QuotationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.purple,
          actions: [
            TextButton(
              onPressed: () {},
              child: const Text(
                "Send by Email",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Confirm",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Preview",
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "S00024",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Customer: Azure Interior, Brandon Freeman",
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      Text(
                        "Address: 4557 De Silva St, Fremont CA 94538, United States",
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      Text(
                        "GST Treatment: Overseas",
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Expiration: 03/23/2025",
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      Text(
                        "Quotation Date: 02/21/2025",
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                      Text(
                        "Payment Terms: End of Following Month",
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const TabBar(
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              tabs: [
                Tab(text: "Order Lines"),
                Tab(text: "Other Info"),
                Tab(text: "Customer Signature"),
              ],
            ),
            Expanded(
              flex: 2,
              child: TabBarView(
                children: [
                  _orderLinesTab(),
                  Center(
                    child: Text(
                      "Other Info",
                      style: TextStyle(color: Colors.teal[700]),
                    ),
                  ),
                  Center(
                    child: Text(
                      "Customer Signature",
                      style: TextStyle(color: Colors.teal[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderLinesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(Colors.teal[50]),
              columns: [
                DataColumn(
                  label: Text(
                    "Product",
                    style: TextStyle(color: Colors.teal[800]),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Quantity",
                    style: TextStyle(color: Colors.teal[800]),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Unit Price",
                    style: TextStyle(color: Colors.teal[800]),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Amount",
                    style: TextStyle(color: Colors.teal[800]),
                  ),
                ),
              ],
              rows: const [
                DataRow(cells: [
                  DataCell(Text("Product Name")),
                  DataCell(Text("1.00")),
                  DataCell(Text("0.00")),
                  DataCell(Text("₹ 0.00")),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text("Add a Product"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text("Add a Section"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text("Add a Note"),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Divider(color: Colors.teal[100]),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
                Text(
                  "₹ 0.00",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
