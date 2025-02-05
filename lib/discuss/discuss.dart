import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:html/parser.dart';
import 'package:url_launcher/url_launcher.dart';

class Discuss extends StatefulWidget {
  const Discuss({super.key});

  @override
  State<Discuss> createState() => _DiscussState();
}

class _DiscussState extends State<Discuss> {
  int? userId;
  OdooClient? client;
  String url = "";
  MemoryImage? profilePicUrl;
  MemoryImage? companyPicUrl;
  List<Map<String, dynamic>> chats = [];
  String? companyLogo;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeOdooClient();
  }

  Future<void> discussData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;

      final discussDetails = await client?.callKw({
        'model': 'mail.message',
        'method': 'search_read',
        'args': [
          [
            ['model', '=', 'discuss.channel']
          ]
        ],
        'kwargs': {
          'fields': ['id', 'body', 'date', 'res_id', 'attachment_ids'],
          'order': 'date desc',
        },
      });

      if (discussDetails != null && discussDetails is List) {
        final channelImages = <String, ImageProvider>{};
        final channelTitles = <String, String>{};
        final filteredDiscussDetails = List<Map<String, dynamic>>.from(discussDetails);

        for (var rec in filteredDiscussDetails) {
          final resId = rec['res_id'];
          if (resId is int || resId is String) {
            final channelDetails = await client?.callKw({
              'model': 'discuss.channel',
              'method': 'read',
              'args': [
                [resId]
              ],
              'kwargs': {'fields': ['name', 'image_128']}
            });

            if (channelDetails != null && channelDetails is List) {
              for (var channel in channelDetails) {
                final imageData = channel['image_128'];
                var title = "";
                if(channel['name']!="")
                  title = channel['name'];

                if (title.isNotEmpty) {
                  channelTitles[resId.toString()] = title;
                }

                if (imageData is String) {
                  try {
                    channelImages[resId.toString()] = MemoryImage(
                      Uint8List.fromList(base64Decode(imageData)),
                    );
                  } catch (e) {
                    print("Error decoding image data for resId $resId: $e");
                  }
                }
              }
            }
          }
        }

        setState(() {
          final uniqueChats = <String>{};
          chats = filteredDiscussDetails.where((chat) {
            final resId = chat['res_id'].toString();
            if (uniqueChats.contains(resId)) {
              return false;
            } else {
              uniqueChats.add(resId);
              final title = channelTitles[resId] ?? 'No Title';
              final image = channelImages[resId];
              chat['record_title'] = title;
              chat['record_image'] = image;
              return true;
            }
          }).toList();

          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching discuss data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }



  Future<void> _initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId') ?? 0;
    url = prefs.getString('url') ?? '';
    final db = prefs.getString('selectedDatabase') ?? '';
    final sessionId = prefs.getString('sessionId') ?? '';
    final serverVersion = prefs.getString('serverVersion') ?? '';
    final userLang = prefs.getString('userLang') ?? '';
    final companyId = prefs.getInt('companyId');
    final allowedCompaniesStringList =
        prefs.getStringList('allowedCompanies') ?? [];
    List<Company> allowedCompanies = [];

    if (allowedCompaniesStringList.isNotEmpty) {
      allowedCompanies = allowedCompaniesStringList
          .map((jsonString) => Company.fromJson(jsonDecode(jsonString)))
          .toList();
    }
    if (url == null || db.isEmpty || sessionId.isEmpty) {
      throw Exception('URL, database, or session details not set');
    }

    final session = OdooSession(
      id: sessionId,
      userId: prefs.getInt('userId') ?? 0,
      partnerId: prefs.getInt('partnerId') ?? 0,
      userLogin: prefs.getString('userLogin') ?? '',
      userName: prefs.getString('userName') ?? '',
      userLang: userLang,
      userTz: '',
      isSystem: prefs.getBool('isSystem') ?? false,
      dbName: db,
      serverVersion: serverVersion,
      companyId: companyId ?? 1,
      allowedCompanies: allowedCompanies,
    );

    client = OdooClient(url!, session);
    discussData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discuss',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          isLoading
              ? Center(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ListView.builder(
                itemCount: 10, // Placeholder shimmer effect
                itemBuilder: (context, index) => ListTile(
                  title: Container(
                    color: Colors.white,
                    height: 20.0,
                  ),
                ),
              ),
            ),
          )
              : ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final channelTitle = chat['record_title'] ?? 'No Title';  // Get channel title

              final lastMessage = chat['body'] != ''
                  ? parseHtmlString(chat['body'] is String ? chat['body'] : 'No Body')
                  : "No Message";

              final recordImage = chat['record_image'];
              print(chat['id']);
              print(channelTitle);
              print("chatschatschatschatsxxx");

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  title: Text(
                    channelTitle,  // Display the channel title
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  leading: CircleAvatar(
                    backgroundImage: recordImage,
                    child: recordImage == null
                        ? const Icon(Icons.people)
                        : null,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/discuss_channel', arguments: {
                      'title': channelTitle,  // Pass title to the next page
                      'image': recordImage,
                      'res_id': chat['res_id']
                    });
                  },
                ),
              );
            },
          ),
          // Positioned(
          //   bottom: 20,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: FloatingActionButton.extended(
          //       onPressed: () {
          //         print('Start Meeting clicked');
          //         _getDiscussVideocallLocation();
          //       },
          //       backgroundColor: Colors.purple,
          //       icon: const Icon(Icons.video_call, size: 30, color: Colors.white),
          //       label: const Text(
          //         'Start a Meeting',
          //         style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Future<void> _getDiscussVideocallLocation() async {
    try {
      final response = await client?.callKw({
        'model': 'calendar.event',
        'method': 'get_discuss_videocall_location',
        'args': [],
        'kwargs': {},
      });

      print("Response Type: ${response.runtimeType}");
      print("Response Data: $response");
      if (response != null) {
        launchUrl(Uri.parse(response));
      }

    } catch (e) {
      print("Error: $e");
    }
}


String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? '';
  }
}
