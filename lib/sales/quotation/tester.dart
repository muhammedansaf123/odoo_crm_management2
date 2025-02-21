import 'package:flutter/material.dart';
// import 'package:odoo_crm_management/initilisation.dart';
// import 'package:odoo_rpc/odoo_rpc.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'dart:convert';

// import 'package:provider/provider.dart';

// class QuotationScreen extends StatefulWidget {
//   const QuotationScreen({super.key});

//   @override
//   _QuotationScreenState createState() => _QuotationScreenState();
// }

// class _QuotationScreenState extends State<QuotationScreen> {
//   Map<String, dynamic>? quotationData;
//   List<dynamic> orderLines = [];

//   @override
//   void initState() {
//     super.initState();

//    // _fetchQuotationData();
//   }

//   Future<void> _fetchQuotationData() async {
//     final client =
//         Provider.of<OdooClientManager>(context, listen: false).client;
//     try {
//       final response = await client!.callKw({
//         'model': 'sale.order',
//         'method': 'search_read',
//         'args': [
//           [
//             ['id', '=', 24]
//           ]
//         ],
//         'kwargs': {
//           'fields': [
//             'name',
//             'partner_id',
//             'partner_shipping_id',
//             'date_order',
//             'validity_date',
//             'payment_term_id',
//             'order_line',
//             'amount_total',
//             'state'
//           ]
//         }
//       });

//       setState(() {
//         quotationData = response[0];
//         _fetchOrderLines(quotationData!['order_line']);
//       });
//     } catch (e) {
//       _showError('Error fetching quotation: $e');
//     }
//   }

//   Future<void> _fetchOrderLines(List<dynamic> lineIds) async {
//     final client =
//         Provider.of<OdooClientManager>(context, listen: false).client;
//     try {
//       final response = await client!.callKw({
//         'model': 'sale.order.line',
//         'method': 'search_read',
//         'args': [
//           lineIds.map((id) => ['id', '=', id]).toList()
//         ],
//         'kwargs': {
//           'fields': [
//             'product_id',
//             'name',
//             'product_uom_qty',
//             'price_unit',
//             'price_subtotal',
//             'discount'
//           ]
//         }
//       });
//       setState(() {
//         orderLines = response;
//       });
//     } catch (e) {
//       _showError('Error fetching order lines: $e');
//     }
//   }

//   Future<void> _sendByEmail() async {
//     final client =
//         Provider.of<OdooClientManager>(context, listen: false).client;
//     try {
//       await client!.callKw({
//         'model': 'sale.order',
//         'method': 'action_quotation_send',
//         'args': [quotationData!['id']],
//         'kwargs': {
//           'force_send': true,
//           'email_values': {
//             'subject': 'Quotation ${quotationData!['name']}',
//             'body_html': 'Please find your quotation attached.',
//           }
//         },
//       });
//       _showSuccess('Quotation sent by email successfully');
//     } catch (e) {
//       _showError('Error sending email: $e');
//     }
//   }

//   Future<void> _confirmQuotation() async {
//     final client =
//         Provider.of<OdooClientManager>(context, listen: false).client;
//     try {
//       await client!.callKw({
//         'model': 'sale.order',
//         'method': 'action_confirm',
//         'args': [quotationData!['id']],
//         'kwargs': {},
//       });
//       _showSuccess('Quotation confirmed successfully');
//       _fetchQuotationData(); // Refresh data
//     } catch (e) {
//       _showError('Error confirming quotation: $e');
//     }
//   }

//   Future<void> _previewPDF() async {
//     final client =
//         Provider.of<OdooClientManager>(context, listen: false).client;
//     try {
//       final result = await client!.callKw({
//         'model': 'sale.order',
//         'method': 'get_report_data',
//         'args': [quotationData!['id']],
//         'kwargs': {},
//       });

//       final bytes = base64Decode(result['report_content']);
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/quotation.pdf');
//       await file.writeAsBytes(bytes);

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => Scaffold(
//             appBar: AppBar(
//               title: Text('Preview: ${quotationData!['name']}'),
//               backgroundColor: Colors.teal,
//             ),
//             body: PDFView(
//               filePath: file.path,
//               enableSwipe: true,
//               swipeHorizontal: true,
//               autoSpacing: false,
//               pageFling: false,
//             ),
//           ),
//         ),
//       );
//     } catch (e) {
//       _showError('Error previewing PDF: $e');
//     }
//   }

//   Future<void> _addProduct() async {
//     try {
//       // Show product selection dialog
//       final client =
//           Provider.of<OdooClientManager>(context, listen: false).client;
//       final result = await _showProductDialog();
//       if (result != null) {
//         await client!.callKw({
//           'model': 'sale.order.line',
//           'method': 'create',
//           'args': [
//             {
//               'order_id': quotationData!['id'],
//               'product_id': result['product_id'],
//               'product_uom_qty': result['quantity'],
//               'price_unit': result['price'],
//             }
//           ],
//           'kwargs': {},
//         });
//         _fetchQuotationData(); // Refresh data
//       }
//     } catch (e) {
//       _showError('Error adding product: $e');
//     }
//   }

//   Future<void> _addSection() async {
//     final textController = TextEditingController();
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Add Section'),
//         content: TextField(
//           controller: textController,
//           decoration: const InputDecoration(
//             labelText: 'Section Title',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, textController.text),
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );

//     if (result != null && result.isNotEmpty) {
//       try {
//         final client =
//             Provider.of<OdooClientManager>(context, listen: false).client;
//         await client!.callKw({
//           'model': 'sale.order.line',
//           'method': 'create',
//           'args': [
//             {
//               'order_id': quotationData!['id'],
//               'display_type': 'line_section',
//               'name': result,
//             }
//           ],
//           'kwargs': {},
//         });
//         _fetchQuotationData();
//       } catch (e) {
//         _showError('Error adding section: $e');
//       }
//     }
//   }

//   Future<void> _addNote() async {
//     final textController = TextEditingController();
//     final result = await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Add Note'),
//         content: TextField(
//           controller: textController,
//           decoration: const InputDecoration(
//             labelText: 'Note Content',
//             border: OutlineInputBorder(),
//           ),
//           maxLines: 3,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, textController.text),
//             child: const Text('Add'),
//           ),
//         ],
//       ),
//     );

//     if (result != null && result.isNotEmpty) {
//       try {
//         final client =
//             Provider.of<OdooClientManager>(context, listen: false).client;
//         await client!.callKw({
//           'model': 'sale.order.line',
//           'method': 'create',
//           'args': [
//             {
//               'order_id': quotationData!['id'],
//               'display_type': 'line_note',
//               'name': result,
//             }
//           ],
//           'kwargs': {},
//         });
//         _fetchQuotationData();
//       } catch (e) {
//         _showError('Error adding note: $e');
//       }
//     }
//   }

//   Future<Map<String, dynamic>?> _showProductDialog() async {
//     final products = await _fetchProducts();
//     final quantityController = TextEditingController(text: '1');
//     dynamic selectedProduct;

//     return showDialog<Map<String, dynamic>>(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: const Text('Add Product'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               DropdownButtonFormField<dynamic>(
//                 decoration: const InputDecoration(
//                   labelText: 'Product',
//                   border: OutlineInputBorder(),
//                 ),
//                 value: selectedProduct,
//                 items: products.map((product) {
//                   return DropdownMenuItem(
//                     value: product,
//                     child: Text(product['name']),
//                   );
//                 }).toList(),
//                 onChanged: (value) => setState(() => selectedProduct = value),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: quantityController,
//                 decoration: const InputDecoration(
//                   labelText: 'Quantity',
//                   border: OutlineInputBorder(),
//                 ),
//                 keyboardType: TextInputType.number,
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (selectedProduct != null) {
//                   Navigator.pop(context, {
//                     'product_id': selectedProduct['id'],
//                     'quantity': double.parse(quantityController.text),
//                     'price': selectedProduct['lst_price'],
//                   });
//                 }
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<List<dynamic>> _fetchProducts() async {
//     try {
//       final client =
//           Provider.of<OdooClientManager>(context, listen: false).client;
//       final response = await client!.callKw({
//         'model': 'product.product',
//         'method': 'search_read',
//         'args': [],
//         'kwargs': {
//           'fields': ['id', 'name', 'lst_price'],
//           'limit': 100,
//         },
//       });
//       return response;
//     } catch (e) {
//       _showError('Error fetching products: $e');
//       return [];
//     }
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   void _showSuccess(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           automaticallyImplyLeading: false,
//           backgroundColor: Colors.purple,
//           actions: [
//             TextButton(
//               onPressed: _sendByEmail,
//               child: const Text("Send by Email",
//                   style: TextStyle(color: Colors.white)),
//             ),
//             TextButton(
//               onPressed: _confirmQuotation,
//               child:
//                   const Text("Confirm", style: TextStyle(color: Colors.white)),
//             ),
//             TextButton(
//               onPressed: _previewPDF,
//               child:
//                   const Text("Preview", style: TextStyle(color: Colors.white)),
//             ),
//             TextButton(
//               onPressed: () {
//                 setState(() {
//                   orderLines.clear();
//                   quotationData = null;
//                 });
//                 Navigator.pop(context);
//               },
//               child:
//                   const Text("Cancel", style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         ),
//         body: Column(
//                 children: [
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               quotationData!['name'] ?? "S00024",
//                               style: TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.teal[800],
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             Text(
//                               "Customer: ${quotationData!['partner_id'][1]}",
//                               style: TextStyle(color: Colors.grey[800]),
//                             ),
//                             Text(
//                               "Status: ${quotationData!['state']}",
//                               style: TextStyle(color: Colors.grey[800]),
//                             ),
//                             Text(
//                               "Expiration: ${quotationData!['validity_date']}",
//                               style: TextStyle(color: Colors.grey[800]),
//                             ),
//                             Text(
//                               "Quotation Date: ${quotationData!['date_order'].split(' ')[0]}",
//                               style: TextStyle(color: Colors.grey[800]),
//                             ),
//                             Text(
//                               "Payment Terms: ${quotationData!['payment_term_id']?[1] ?? 'End of Following Month'}",
//                               style: TextStyle(color: Colors.grey[800]),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const TabBar(
//                     labelColor: Colors.teal,
//                     unselectedLabelColor: Colors.grey,
//                     indicatorColor: Colors.teal,
//                     tabs: [
//                       Tab(text: "Order Lines"),
//                       Tab(text: "Other Info"),
//                       Tab(text: "Customer Signature"),
//                     ],
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: TabBarView(
//                       children: [
//                         _orderLinesTab(),
//                         _otherInfoTab(),
//                         _customerSignatureTab(),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   Widget _orderLinesTab() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: DataTable(
//                 headingRowColor: MaterialStateProperty.all(Colors.teal[50]),
//                 columns: const [
//                   DataColumn(label: Text("Product")),
//                   DataColumn(label: Text("Quantity")),
//                   DataColumn(label: Text("Unit Price")),
//                   DataColumn(label: Text("Amount")),
//                 ],
//                 rows: orderLines.map((line) {
//                   if (line['display_type'] == 'line_section') {
//                     return DataRow(
//                       cells: [
//                         DataCell(
//                           Text(line['name'],
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               )),
//                         ),
//                         const DataCell(Text("")),
//                         const DataCell(Text("")),
//                         const DataCell(Text("")),
//                       ],
//                     );
//                   } else if (line['display_type'] == 'line_note') {
//                     return DataRow(
//                       cells: [
//                         DataCell(Text(
//                           line['name'],
//                           style: const TextStyle(fontStyle: FontStyle.italic),
//                         )),
//                         const DataCell(Text("")),
//                         const DataCell(Text("")),
//                         const DataCell(Text("")),
//                       ],
//                     );
//                   } else {
//                     return DataRow(
//                       cells: [
//                         DataCell(Text(line['product_id'][1])),
//                         DataCell(Text(line['product_uom_qty'].toString())),
//                         DataCell(Text(line['price_unit'].toString())),
//                         DataCell(Text("₹ ${line['price_subtotal']}")),
//                       ],
//                     );
//                   }
//                 }).toList(),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: _addProduct,
//                   icon: const Icon(Icons.add_shopping_cart),
//                   label: const Text("Add a Product"),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: _addSection,
//                   icon: const Icon(Icons.playlist_add),
//                   label: const Text("Add a Section"),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                   ),
//                   onPressed: _addNote,
//                   icon: const Icon(Icons.note_add),
//                   label: const Text("Add a Note"),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 32),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Total:",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.teal[800],
//                   ),
//                 ),
//                 Text(
//                   "₹ ${quotationData!['amount_total'].toStringAsFixed(2)}",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.teal[800],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _otherInfoTab() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Sales Information",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.teal[800],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                       "Sales Person: ${quotationData!['user_id']?[1] ?? 'Not Assigned'}"),
//                   Text(
//                       "Sales Team: ${quotationData!['team_id']?[1] ?? 'Not Assigned'}"),
//                   Text(
//                       "Company: ${quotationData!['company_id']?[1] ?? 'Not Specified'}"),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Shipping Information",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.teal[800],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                       "Delivery Address: ${quotationData!['partner_shipping_id']?[1] ?? 'Not Specified'}"),
//                   Text(
//                       "Shipping Policy: ${quotationData!['picking_policy'] ?? 'Not Specified'}"),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _customerSignatureTab() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.gesture,
//             size: 64,
//             color: Colors.teal[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "No signature required",
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.teal[800],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "This quotation doesn't require customer signature",
//             style: TextStyle(
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
