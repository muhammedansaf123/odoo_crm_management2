import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:html/parser.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kplayer/kplayer.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart' as waveforms;
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:http/http.dart' as http;

import 'meeting.dart';

class DiscussChannel extends StatefulWidget {
  const DiscussChannel({super.key});

  @override
  State<DiscussChannel> createState() => _DiscussChannelState();
}

class _DiscussChannelState extends State<DiscussChannel> {
  int? userId;
  int? partnerId;
  OdooClient? client;
  String url = "";
  List<Map<String, dynamic>> chats = [];
  bool isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  bool isRecording = false;
  late waveforms.RecorderController recorderController;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  Timer? _timer;
  bool isRecordingCompleted = false;
  DateTime? startTime;
  int _pausedTime = 0;
  late Directory appDirectory;
  String? path;
  File? _selectedImage;
  late TextEditingController _titleController;
  bool isEditing = false;
  bool _isPanelVisible = false;
  List<Map<String, dynamic>> _members = [];
  bool _isVisible = false;
  List<int>? _selectedPartnerIds;
  List<dynamic> attendeesList = [];
  int ChannelMemberId = 0;
  String _existingNameError = "";
  String meetingLink = "";

  @override
  void initState() {
    super.initState();
    _initializeOdooClient();
    _getDir();
    _initialiseControllers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initialiseControllers() {
    recorderController = waveforms.RecorderController()
      ..androidEncoder = waveforms.AndroidEncoder.aac
      ..androidOutputFormat = waveforms.AndroidOutputFormat.mpeg4
      ..iosEncoder = waveforms.IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 128000;
  }

  void _getDir() async {
    try {
      appDirectory = await getApplicationDocumentsDirectory();
      final recordingsDirectory = Directory('${appDirectory.path}/recordings');
      if (!await recordingsDirectory.exists()) {
        await recordingsDirectory.create(recursive: true);
      }
      path = "${recordingsDirectory.path}/recording.wav";
      setState(() {});
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  Future<void> getAttendeesList() async {
    try {
      final response = await client?.callKw({
        'model': 'res.partner',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {'fields': []},
      });

      if (response != null) {
        setState(() {
          attendeesList = response;
          print(attendeesList);
          print("attendeesListattendeesListattendeesList");
        });
      }
    } catch (e) {
      print("Error fetching calendar details: $e");
    }
  }

  Future<void> discussData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;

      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final resId = args['res_id'] ?? 0;

      final discussMembers = await client?.callKw({
        'model': 'discuss.channel.member',
        'method': 'search_read',
        'args': [
          [
            ['channel_id', '=', resId],
          ]
        ],
        'kwargs': {
          'fields': ['partner_id'],
        },
      });
      print(discussMembers);
      print("discussMembersdiscussMembersdiscussMembers");
      List<Map<String, dynamic>> members = [];
      for (var partner in discussMembers) {
        print("partnerpartnerpartner$partner");
        final partnerDeatils = await client?.callKw({
          'model': 'res.partner',
          'method': 'search_read',
          'args': [
            [
              ['id', '=', partner['partner_id'][0]],
            ]
          ],
          'kwargs': {
            'fields': ['image_1920', 'name', 'email', 'phone']
          }
        });
        if (partnerDeatils != null && partnerDeatils.isNotEmpty) {
          print(partnerDeatils);
          print("partnerDeatilspartnerDeatilspartnerDeatils");
          members.add(partnerDeatils[0]);
        }
      }
      final discussDetails = await client?.callKw({
        'model': 'mail.message',
        'method': 'search_read',
        'args': [
          [
            ['model', '=', 'discuss.channel'],
            ['res_id', '=', resId],
            [
              'message_type',
              'in',
              ['notification', 'comment']
            ]
          ]
        ],
        'kwargs': {
          'fields': [
            'body',
            'date',
            'res_id',
            'attachment_ids',
            'message_type',
            'email_from',
            'author_avatar',
            'author_id',
          ],
          'order': 'date desc',
        },
      });
      print("discussDetailsdiscussDetailsdiscussDetails$discussDetails");
      if (discussDetails != null && discussDetails is List) {
        for (var message in discussDetails) {
          final attachmentIds = message['attachment_ids'] ?? [];
          print(attachmentIds);
          List<Map<String, dynamic>> attachments = [];

          for (var attachment in attachmentIds) {
            print("$client/ghggggggggggfffffffffffffffffff");
            try {
              // final response = await http.get(Uri.parse('http://10.0.20.53:8017/web/content/ir.attachment/$attachment/datas'));
              // if (response.statusCode == 200) {
              //   print('Attachment downloaded successfully');
              // } else {
              //   print('Failed to fetch attachment: ${response.statusCode}');
              //   print('Response body: ${response.body}');
              // }

              // final response = await client!.callRPC(
              //     '/web/content/ir.attachment/$attachment/datas', 'call', {});
              // print(response.runtimeType);
              // print("responseresponseresponse");
              final attachmentDetails = await client?.callKw({
                'model': 'ir.attachment',
                'method': 'search_read',
                'args': [
                  [
                    ['id', '=', attachment],
                  ]
                ],
                'kwargs': {
                  'context': {'uid': userId}
                }
              });
              print(attachmentDetails);
              print("attachmentDetailsattachmentDetails");
              if (attachmentDetails != null && attachmentDetails.isNotEmpty) {
                attachments.add(attachmentDetails[0]);
              }
            } catch (e) {
              print('Error fetching attachment: $e');
            }

            // final response = await client!.callRPC('/web/content/ir.attachment/#{$attachment}/datas', 'call', {});
            // print(response);
            // print("responseresponseresponse");
            // final attachmentDetails =  await client?.callKw({
            //   'model': 'ir.attachment',
            //   'method': 'search_read',
            //   'args': [
            //     [
            //       ['id', '=', attachment],
            //     ]
            //   ],
            //   'kwargs': {
            //     'context': {'uid': userId}
            //   }
            // });
            // print(attachmentDetails);
            // print("attachmentDetailsattachmentDetails");
            // if (attachmentDetails != null && attachmentDetails.isNotEmpty) {
            //   attachments.add(attachmentDetails[0]);
            // }
          }
          message['attachments'] = attachments;
        }

        setState(() {
          chats = List<Map<String, dynamic>>.from(discussDetails);
          _members = members;
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

  Future<void> sendMessage(String message, String type) async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final resId = args['res_id'] ?? 0;
    try {
      await client?.callKw({
        'model': 'mail.message',
        'method': 'create',
        'args': [
          {
            'body': message,
            'model': 'discuss.channel',
            'res_id': resId,
            'author_id': partnerId,
            'message_type': type,
            'record_name': args['title']
          }
        ],
        'kwargs': {}
      });
      _messageController.clear();
      discussData();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  Future<void> addMembersToChat(List<int>? selectedPartnerIds) async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final resId = args['res_id'] ?? 0;
    if (selectedPartnerIds == null || selectedPartnerIds.isEmpty) {
      print("No members selected to add.");
      return;
    }

    try {
      print("Selected Partner IDs: $selectedPartnerIds");
      print("Res ID: $resId");

      for (var member in selectedPartnerIds) {
        print("Adding member: $member");

        await client?.callKw({
          'model': 'discuss.channel.member',
          'method': 'create',
          'args': [
            {'partner_id': member, 'channel_id': resId}
          ],
          'kwargs': {}
        });
        discussData();
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  Future<void> sendAudioMessage(String filePath) async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final resId = args['res_id'] ?? 0;
    print(resId);
    print("resIdresjjjjjjjjjjjjIdresId");
    try {
      File audioFile = File(filePath);
      List<int> fileBytes = await audioFile.readAsBytes();

      String base64File = base64Encode(fileBytes);
      final response = await client?.callKw({
        'model': 'ir.attachment',
        'method': 'create',
        'args': [
          {
            'name': 'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
            'type': 'binary',
            'datas': base64File,
            'res_model': 'discuss.channel',
            'res_id': resId,
            'mimetype': 'audio/mpeg',
          }
        ],
        'kwargs': {}
      });
      print("responseresponseresponse$response");
      if (response != null) {
        print("$partnerId/responseVoiceresponseVoice");
        await client?.callKw({
          'model': 'mail.message',
          'method': 'create',
          'args': [
            {
              'model': 'discuss.channel',
              'res_id': resId,
              'author_id': partnerId,
              'message_type': "comment",
              'record_name': args['title'],
              'attachment_ids': [response]
            }
          ],
          'kwargs': {}
        });
        _messageController.clear();
        discussData();
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Future<void> sendMeetingLink(String link) async {
  //   final args =
  //   ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  //   final resId = args['res_id'] ?? 0;
  //   final a = await client?.callKw({
  //     'model': 'mail.message',
  //     'method': 'create',
  //     'args': [
  //       {
  //         'body': link,
  //         'model': 'discuss.channel',
  //         'res_id': resId,
  //         'author_id': partnerId,
  //         'message_type': "comment",
  //         'record_name': args['title']
  //       }
  //     ],
  //     'kwargs': {}
  //   });
  //   print(a);
  //   print("dddddddddddddddd");
  // }

  Future<void> _initializeOdooClient() async {
    final prefs = await SharedPreferences.getInstance();
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
    partnerId = prefs.getInt('partnerId') ?? 0;
    discussData();
    getPartnerId();
    getAttendeesList();
  }

  Future<void> getPartnerId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt('userId') ?? 0;
      final userDetails = await client?.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', userId]
          ]
        ],
        'kwargs': {},
      });

      if (userDetails != null) {
        final userName = userDetails[0]['name'];
        final partnerDetails = await client?.callKw({
          'model': 'res.partner',
          'method': 'search_read',
          'args': [
            [
              ['name', '=', userName]
            ]
          ],
          'kwargs': {
            'fields': ['id'],
          },
        });

        if (partnerDetails != null) {
          partnerId = partnerDetails[0]['id'];
          print('Partner ID: $partnerId');
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching profile data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        updateDiscuss();
      });
    }
  }

  Future<void> updateDiscuss() async {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final resId = args['res_id'] ?? 0;
    print(resId);
    print("resIdresjjjjjjjjjjjjIdresId");
    if (_selectedImage != null) {
      final file = _selectedImage as File;
      final imageBytes = await file.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      try {
        await client?.callKw({
          'model': 'discuss.channel',
          'method': 'write',
          'args': [
            [resId],
            {'image_128': base64Image}
          ],
          'kwargs': {}
        });
        setState(() {
          isEditing = false;
          discussData();
        });
      } catch (e) {
        print("Error sending message: $e");
      }
    } else {
      try {
        final a = await client?.callKw({
          'model': 'discuss.channel',
          'method': 'write',
          'args': [
            [resId],
            {'name': _titleController.text}
          ],
          'kwargs': {}
        });
        print(a);
        print("resIdresjjjjjjjjjjjjIdresIdresIdresjjjjjjjjjjjjIdresId");
        setState(() {
          isEditing = false;
          discussData();
        });
      } catch (e) {
        print("Error sending message: $e");
      }
    }
  }

  void _editTitle() {
    setState(() {
      isEditing = true;
    });
  }

  void _togglePanel() {
    setState(() {
      _isPanelVisible = !_isPanelVisible;
    });
  }

  String generateConferenceLink() {
    // Generate a unique conference link (e.g., using a timestamp or UUID)
    return "https://myapp.com/conference/${DateTime.now().millisecondsSinceEpoch}";
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final title = args['title'] ?? 'No Title';
    final recordImage = args['image'] as MemoryImage?;
    print(attendeesList);
    print("ooooooooattendeesList");
    ImageProvider<Object>? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (recordImage != null) {
      imageProvider = recordImage;
    } else {
      imageProvider = null;
    }
    _titleController = TextEditingController(text: title);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                backgroundImage: imageProvider,
                radius: 20,
                child: imageProvider == null
                    ? const Icon(Icons.people, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: _editTitle,
                child: isEditing
                    ? TextField(
                        controller: _titleController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter title',
                          hintStyle: TextStyle(color: Colors.white),
                        ),
                        style: const TextStyle(color: Colors.white),
                        // onSubmitted: (_) => _saveTitle(),
                      )
                    : Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
            isEditing
                ? IconButton(
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: () {
                      updateDiscuss();
                    },
                  )
                : const SizedBox.shrink(),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: Icon(Icons.phone, color: Colors.white),
          //   onPressed: () async {
          //     String conferenceLink = generateConferenceLink();
          //     // meetingLink = conferenceLink;
          //     await sendMeetingLink(conferenceLink);
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => ConferenceCallPage(
          //           conferenceLink: conferenceLink,
          //         ),
          //       ),
          //     );
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
          ),
          IconButton(
              icon: const Icon(Icons.people, color: Colors.white),
              onPressed: _togglePanel),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? Center(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: ListView.builder(
                            itemCount: 10,
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
                        reverse: true,
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final body = chat['body'] ?? 'No Message';
                          final attachments = chat['attachments'] ?? [];
                          final date = chat['date'] ?? 'Unknown Date';
                          final authorIdRaw = chat['author_id'];
                          final messageType = chat['message_type'] ?? '';
                          int? authorId;
                          print(body);
                          print("bodybodybodybodybodybody");
                          final isAudioMessage =
                              body == '' && attachments.isNotEmpty;
                          print(isAudioMessage);
                          if (authorIdRaw is List && authorIdRaw.isNotEmpty) {
                            authorId = authorIdRaw[0] as int?;
                          } else if (authorIdRaw is int) {
                            authorId = authorIdRaw;
                          } else {
                            authorId = null;
                          }

                          print(authorId);
                          print(userId);
                          print("authorIdauthorId");

                          final isSent = authorId == partnerId;

                          final avatarData = chat['author_avatar'];
                          ImageProvider? avatar;

                          if (avatarData is String) {
                            try {
                              avatar = MemoryImage(
                                  Uint8List.fromList(base64Decode(avatarData)));
                            } catch (_) {
                              avatar = null;
                            }
                          }
                          if (isAudioMessage) {
                            final rawAttachment = attachments[0]['raw'];
                            Uint8List? audioData;

                            if (rawAttachment is String) {
                              try {
                                audioData =
                                    Uint8List.fromList(rawAttachment.codeUnits);
                              } catch (e) {
                                print('Error decoding Base64: $e');
                                audioData = base64Decode(rawAttachment);
                                print(
                                    'Fallback: Treated string as binary data.');
                              }
                            } else if (rawAttachment is Uint8List) {
                              audioData = rawAttachment;
                            } else {
                              print(
                                  'Unsupported attachment type: ${rawAttachment.runtimeType}');
                            }

                            if (audioData != null) {
                              print(audioData);
                              print("3333333333333audioData");
                              return ChatBubble(
                                  message: body.isNotEmpty ? body : "",
                                  isSent: isSent,
                                  date: date,
                                  avatar: avatar,
                                  audioData: audioData);
                            } else {
                              return const Text(
                                  'Error: Unable to process audio data.');
                            }
                          } else {
                            if (messageType == 'notification') {
                              print(parseHtmlString(body));
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      date,
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      parseHtmlString(body),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    )
                                  ],
                                ),
                              );
                            } else {
                              return ChatBubble(
                                message: body,
                                isSent: isSent,
                                date: date,
                                avatar: avatar,
                              );
                            }
                          }
                        }),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: isRecording
                          ? Stack(
                              children: [
                                waveforms.AudioWaveforms(
                                  enableGesture: true,
                                  size: Size(
                                    MediaQuery.of(context).size.width / 0.0,
                                    50,
                                  ),
                                  recorderController: recorderController,
                                  waveStyle: const waveforms.WaveStyle(
                                    waveColor: Colors.white,
                                    extendWaveform: true,
                                    showMiddleLine: false,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: Colors.green,
                                  ),
                                  padding: const EdgeInsets.only(left: 18),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                ),
                                Positioned(
                                  bottom: -5,
                                  left: 0,
                                  right: 18,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5.0),
                                    child: Text(
                                      _formatDuration(_elapsedSeconds),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: const TextStyle(color: Colors.teal),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide:
                                      BorderSide(color: Colors.teal[700]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: const BorderSide(
                                      color: Colors.teal, width: 2.0),
                                ),
                              ),
                            ),
                    ),
                    IconButton(
                      icon: !isRecording
                          ? const Icon(Icons.send, color: Colors.teal)
                          : const SizedBox.shrink(),
                      // Empty widget when recording
                      onPressed: () {
                        if (!isRecording &&
                            _messageController.text.isNotEmpty) {
                          final type = "comment";
                          sendMessage(_messageController.text, type);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(isRecording ? Icons.send : Icons.mic),
                      color: isRecording ? Colors.red : Colors.teal,
                      onPressed: _startOrStopRecording,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isPanelVisible ? 0 : -300,
            top: 0,
            bottom: 0,
            child: Container(
              width: 300,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.teal,
                    height: 56,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Channel Members',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isPanelVisible = !_isPanelVisible;
                            });
                          },
                          icon: const Icon(Icons.close,
                              color: Colors
                                  .white), // Optional: Color change for icon
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final imageData = member['image_1920'];
                        ImageProvider<Object>? image;
                        if (imageData is String) {
                          if (imageData != null) {
                            try {
                              image = MemoryImage(
                                Uint8List.fromList(base64Decode(imageData)),
                              );
                            } catch (_) {
                              image = null;
                            }
                          }
                        } else {
                          image = null;
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: image,
                            child:
                                image == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(member['name'] ?? 'Unknown'),
                          subtitle: Text(member['email'] ?? 'No Email'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _isVisible ? 0 : -300,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isVisible = !_isVisible;
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Text(
                    'Invite People',
                    style: TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  if (_existingNameError != '')
                    Text(
                      "The following members already exist: $_existingNameError",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MultiSelectDropdown.simpleList(
                      key: ValueKey(_selectedPartnerIds),
                      list: attendeesList
                          .map((partner) => partner['name'])
                          .toList(),
                      initiallySelected: _selectedPartnerIds != null
                          ? attendeesList
                              .where((partner) =>
                                  _selectedPartnerIds!.contains(partner['id']))
                              .map((partner) => partner['name'])
                              .toList()
                          : [],
                      onChange: (selectedItems) {
                        List<int> selectedPartnerIds = [];

                        for (var item in selectedItems) {
                          var matchingPartner = attendeesList.firstWhere(
                            (partner) => partner['name'] == item,
                            orElse: () => null,
                          );
                          if (matchingPartner != null) {
                            selectedPartnerIds.add(matchingPartner['id']);
                          }
                        }

                        setState(() {
                          _existingNameError = "";
                          _selectedPartnerIds = selectedPartnerIds;
                        });
                      },
                      includeSearch: true,
                      includeSelectAll: true,
                      isLarge: false,
                      numberOfItemsLabelToShow: 3,
                      checkboxFillColor: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedPartnerIds != null) {
                        print('Selected person: $_selectedPartnerIds');
                        List<Map<String, dynamic>> existingMembers = _members
                            .where((member) =>
                                _selectedPartnerIds!.contains(member['id']))
                            .map((member) =>
                                {'id': member['id'], 'name': member['name']})
                            .toList();
                        print(existingMembers);
                        print("existingMembersexistingMembers");
                        if (existingMembers.isNotEmpty) {
                          String existingNames = existingMembers
                              .map((member) => member['name'])
                              .join(', ');
                          print(existingNames);
                          print("ddddddddddddddddddddd");
                          setState(() {
                            _existingNameError = existingNames;
                          });
                        } else {
                          _existingNameError = "";
                          addMembersToChat(_selectedPartnerIds!);
                          setState(() {
                            _isVisible = !_isVisible;
                            _selectedPartnerIds = null;
                            print("444444444ddddddddddd");
                          });
                        }
                      } else {
                        print('No person selected');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.teal, // Primary color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Invite to Group Chat',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
    _isTimerRunning = true;
  }

  void _stopTimer() {
    _timer?.cancel();
    _isTimerRunning = false;
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _elapsedSeconds = 0;
      _pausedTime = 0;
    });
  }

  Future<void> _startOrStopRecording() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      if (isRecording) {
        await recorderController.stop();
        _stopTimer();
        setState(() {
          isRecordingCompleted = true;
          isRecording = false;
        });
        if (path != null) {
          print(path);
          print("________________");
          print("Recording path: $path");
          final file = File(path!);
          if (await file.exists()) {
            print("File exists, size: ${await file.length()} bytes");
          } else {
            print("File does not exist");
          }

          await sendAudioMessage(path!);
        } else {
          print("Recording path is null");
        }
        _resetTimer();
      } else {
        _startTimer();
        try {
          await recorderController.record(path: path!);
          setState(() {
            isRecording = true;
            isRecordingCompleted = false;
          });
        } catch (e) {
          print("Error starting recording: $e");
        }
      }
    } else {
      print("Microphone permission denied");
    }
  }
}

String parseHtmlString(String htmlString) {
  final document = parse(htmlString);
  return document.body?.text ?? '';
}

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isSent;
  final String date;
  final ImageProvider? avatar;
  final List<int>? audioData;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isSent,
    required this.date,
    this.avatar,
    this.audioData,
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  PlayerController? _playerController;
  double _currentPosition = 0.0;
  double _totalDuration = 1.0;
  bool _isPlaying = false;
  bool _isPositionChanging = false;
  late String _tempFilePath;
  Duration? _duration;
  bool _changingPosition = false;
  Duration _position = Duration.zero;
  static PlayerController? _currentPlayer;
  double _playbackSpeed = 1.0;

  double get position {
    if (_duration == null || _duration!.inSeconds == 0) {
      return 0;
    }
    if (_changingPosition) {
      return _position.inSeconds * 100 / _duration!.inSeconds;
    } else {
      final controllerPosition = _position.inSeconds;
      return controllerPosition * 100 / _duration!.inSeconds;
    }
  }

  @override
  void initState() {
    super.initState();
    print("7777777777777777777777777777777");
    _initializePlayer();
  }

  @override
  void dispose() {
    if (_playerController != null) {
      _playerController!.dispose();
    }
    super.dispose();
  }

  void _initializePlayer() async {
    try {
      if (widget.audioData != null && widget.audioData!.isNotEmpty) {
        print("rrrrrrrrrrrrrrrrrrrrrrrrfffffffffff");
        final directory = await getApplicationDocumentsDirectory();
        print(directory);
        print("ffffffffffffffffffffff");
        final tempFile = File(
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tempFile.writeAsBytes(widget.audioData!);
        _tempFilePath = tempFile.path;
        print(_tempFilePath);
        print("_tempFilePath_tempFilePath");
        _playerController = Player.file(_tempFilePath, autoPlay: false);
        print(_playerController);
        _playerController!.streams.position.listen((position) {
          if (mounted && !_isPositionChanging) {
            setState(() {
              _position = position;
              _currentPosition = position.inMilliseconds.toDouble();
              if (_duration != null && _position >= _duration!) {
                _isPlaying = false;
              }
            });
          }
        });
        _playerController!.streams.duration.listen((duration) {
          if (mounted) {
            setState(() {
              _totalDuration = duration.inMilliseconds.toDouble();
            });
          }
        });
        _playerController!.streams.status.listen((status) {
          if (mounted) {
            setState(() {
              _isPlaying = status == PlayerStatus.playing;
              if (status == PlayerStatus.ended) {
                print("Playback has completed.");
                _restartAudio();
                _playbackSpeed = 1.0;
              }
            });
          }
        });
      }
    } catch (e) {
      print("Error initializing player: $e");
    }
  }

  void _restartAudio() {
    _initializePlayer();
  }

  void _changePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
      _playerController!.setSpeed(_playbackSpeed);
    });
  }

  void _playAudio() {
    print(_playerController);
    if (!_isPlaying) {
      if (_currentPlayer != null && _currentPlayer != _playerController) {
        _currentPlayer?.pause();
      }
      _currentPlayer = _playerController;
      _playerController!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _pauseAudio() {
    if (_isPlaying) {
      _playerController!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  String parseHtmlString(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  Widget build(BuildContext context) {
    print(widget.message);
    print("widget.message.widget.message.");
    final parsedMessage = parseHtmlString(widget.message);
    return Row(
      mainAxisAlignment:
          widget.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isSent && widget.avatar != null)
          CircleAvatar(
            backgroundImage: widget.avatar,
            radius: 16,
            child: widget.avatar == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
        if (!widget.isSent) const SizedBox(width: 8),
        SizedBox(
          width: 250.0,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.isSent ? Colors.purple[300] : Colors.teal[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: widget.isSent
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (widget.message.isNotEmpty) ...[
                  // if (parsedMessage.startsWith('https'))
                  //   TextButton(
                  //     onPressed: () async {
                  //       print("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv");
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => ConferenceCallPage(
                  //             conferenceLink: parsedMessage,
                  //           ),
                  //         ),
                  //       );
                  //     },
                  //     child: Text(
                  //       parsedMessage,
                  //       style: TextStyle(
                  //         color: Colors.white,
                  //         decoration: TextDecoration.underline,
                  //         fontSize: 16,
                  //       ),
                  //     ),
                  //   )
                  // else
                  Text(
                    parseHtmlString(widget.message),
                    style: TextStyle(
                      color: widget.isSent ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                if (widget.audioData != null &&
                    widget.audioData!.isNotEmpty) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (_isPlaying) {
                            _pauseAudio();
                          } else {
                            _playAudio();
                          }
                        },
                      ),
                      Expanded(
                        child: Slider(
                          value: _isPositionChanging
                              ? _position.inMilliseconds.toDouble()
                              : _currentPosition,
                          min: 0.0,
                          max: _totalDuration,
                          activeColor: Colors.white,
                          inactiveColor: Colors.grey,
                          onChanged: (double value) {
                            setState(() {
                              _position = Duration(milliseconds: value.toInt());
                              _isPositionChanging = true;
                            });
                          },
                          onChangeStart: (double value) {
                            setState(() {
                              _isPositionChanging = true;
                            });
                          },
                          onChangeEnd: (double value) {
                            setState(() {
                              _isPositionChanging = false;
                              _currentPosition = value;
                            });
                            _playerController!
                                .seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: widget.isSent
                              ? Colors.purple[600]
                              : Colors.teal[600],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: IconButton(
                            icon: Text(
                              '${_playbackSpeed}x',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: _changePlaybackSpeed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_duration != null)
                    Positioned(
                      // right: 8.0,
                      left: 40.0,
                      // bottom: 3.0,
                      bottom: -2.0,
                      child: Text(
                        '${_position.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_position.inSeconds.remainder(60).toString().padLeft(2, '0')}/${_duration?.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_duration?.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12.0),
                      ),
                    ),
                ],
                Text(
                  widget.date,
                  style: TextStyle(
                    color: widget.isSent ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.isSent && widget.avatar != null) const SizedBox(width: 8),
        if (widget.isSent && widget.avatar != null)
          CircleAvatar(
            backgroundImage: widget.avatar,
            radius: 16,
            child: widget.avatar == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
      ],
    );
  }
}
