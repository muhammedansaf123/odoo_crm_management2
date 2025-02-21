import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' show parse;

class ActivityDetailPage extends StatefulWidget {
  final Function reloadCRM;
  final Map activity;
  final List<dynamic> calendarTagsDetails;
  final List<dynamic> attendeesList;
  final List<dynamic> calendarAlarmDetails;
  final List<dynamic> userDetails;

  const ActivityDetailPage({
    Key? key,
    required this.reloadCRM,
    required this.activity,
    required this.calendarTagsDetails,
    required this.attendeesList,
    required this.calendarAlarmDetails,
    required this.userDetails,
  }) : super(key: key);

  @override
  _ActivityDetailPageState createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  int? userId;
  OdooClient? client;
  String url = "";
  // DateTime? _startDate;
  // DateTime? _stopDate;
  // final TextEditingController _startController = TextEditingController();
  // final TextEditingController _stopController = TextEditingController();
  // final TextEditingController _durationController = TextEditingController();
  // final TextEditingController _locationController = TextEditingController();
  List<dynamic> attendeesDetails = [];
  List<dynamic> tagsDetails = [];
  List<dynamic> alarmDetails = [];
  // String? _categId;
  // String? _privacy = 'public';
  // String? _reminder;
  // final TextEditingController _organizerController = TextEditingController();
  // final TextEditingController _descriptionController = TextEditingController();
  Map<String, dynamic> calendarDetails = {};
  List<dynamic> _detailedCalendarInfo = [];
  bool isEditLoading = false;
  bool isGeneratedMeetingLink = false;
  String meetingLocation = '';

  @override
  void initState() {
    super.initState();
    _initializeOdooClient();
  }

  Future<void> refreshActivityDetails() async {
    await getCalendarDetails();
    setState(() {});
  }

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
    await getCalendarDetails();
  }

  Future<void> getCalendarDetails() async {
    try {
      final response = await client?.callKw({
        'model': 'calendar.event',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', widget.activity['id']]
          ]
        ],
        'kwargs': {
          'fields': [
            'name',
            'display_time',
            'duration',
            'user_id',
            'description',
            'privacy',
            'location',
            'start',
            'stop',
            'categ_ids',
            'partner_ids',
            'alarm_ids',
            'videocall_location'
          ]
        },
      });

      if (response != null && response.isNotEmpty) {
        calendarDetails = response[0];
        await _fetchAttendeeDetails(response[0]['partner_ids']);
        await _fetchTagsDetails(response[0]['categ_ids']);
        await _fetchReminderDetails(response[0]['alarm_ids']);
        _combineDetails();
      }
    } catch (e) {
      print("Error fetching calendar details: $e");
    }
  }

  Future<void> _fetchAttendeeDetails(List<dynamic> partnerIds) async {
    try {
      attendeesDetails.clear();
      for (var partnerId in partnerIds) {
        final responsePartner = await client?.callKw({
          'model': 'res.partner',
          'method': 'search_read',
          'args': [
            [
              ['id', '=', partnerId]
            ]
          ],
          'kwargs': {
            'fields': ['name', 'image_1920']
          },
        });

        if (responsePartner != null && responsePartner.isNotEmpty) {
          final partner = responsePartner[0];
          final logoBase64 = partner['image_1920'];
          final partnerName = partner['name'] ?? 'Unknown';

          if (logoBase64 != null &&
              logoBase64.isNotEmpty &&
              logoBase64 != 'false') {
            final imageData = base64Decode(logoBase64);
            attendeesDetails.add({
              'name': partnerName,
              'image': MemoryImage(imageData),
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching partner details: $e");
    }
  }

  Future<void> _fetchTagsDetails(List<dynamic> tagIds) async {
    try {
      tagsDetails.clear();
      for (var tagId in tagIds) {
        final responseCategories = await client?.callKw({
          'model': 'calendar.event.type',
          'method': 'search_read',
          'args': [
            [
              ['id', '=', tagId]
            ]
          ],
          'kwargs': {
            'fields': ['name'],
          },
        });
        if (responseCategories != null && responseCategories.isNotEmpty) {
          final tag = responseCategories[0];
          tagsDetails.add({
            'id': tag['id'],
            'name': tag['name'],
          });
          print(tag);
          print("tagtagtagtagtag");
        }
      }
    } catch (e) {
      print("Error fetching partner details: $e");
    }
  }

  Future<void> _fetchReminderDetails(List<dynamic> alarmIds) async {
    try {
      alarmDetails.clear();
      for (var alarmId in alarmIds) {
        final responseAlarm = await client?.callKw({
          'model': 'calendar.alarm',
          'method': 'search_read',
          'args': [
            [
              ['id', '=', alarmId]
            ]
          ],
          'kwargs': {
            'fields': ['name'],
          },
        });
        if (responseAlarm != null && responseAlarm.isNotEmpty) {
          final alarm = responseAlarm[0];
          alarmDetails.add({
            'id': alarm['id'],
            'name': alarm['name'],
          });
          print(alarm);
          print("alarmalarmalarm");
        }
      }
    } catch (e) {
      print("Error fetching partner details: $e");
    }
  }

  void _combineDetails() {
    setState(() {
      _detailedCalendarInfo = [
        calendarDetails,
        {'attendees': attendeesDetails},
        {'tags': tagsDetails},
        {'alarms': alarmDetails}
      ];
    });
    print(_detailedCalendarInfo);
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.reloadCRM);
    print("333333333333333333333");
    final args = ModalRoute.of(context)!.settings.arguments as Map? ?? {};

    final activity =
        _detailedCalendarInfo.isNotEmpty ? _detailedCalendarInfo[0] : {};
    final attendees = _detailedCalendarInfo.length > 1
        ? (_detailedCalendarInfo[1]['attendees'] ?? [])
        : [];
    final tags = _detailedCalendarInfo.length > 1
        ? (_detailedCalendarInfo[2]['tags'] ?? [])
        : [];
    final alarms = _detailedCalendarInfo.length > 1
        ? (_detailedCalendarInfo[3]['alarms'] ?? [])
        : [];

    print("taggggggggggggggggssssssssss$isGeneratedMeetingLink");
    return WillPopScope(
      onWillPop: () async {
        print(args);
        widget.reloadCRM();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            activity['name'] ?? 'Activity Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.edit_calendar_outlined,
                color: Colors.white,
                size: 30.0,
              ),
              onPressed: () {
                _showEditActivityDialog(
                    context, activity, attendees, tags, alarms);
              },
            ),
          ],
          backgroundColor: Colors.purple,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attendees.isNotEmpty) _buildAttendeesSection(attendees),
                _buildDetailCard(
                    'Time',
                    activity['display_time'] ?? 'No Display Name',
                    Icons.access_time),
                _buildDetailCard(
                    'Duration',
                    '${activity['duration'] ?? 'No Duration'} hours',
                    Icons.timer),
                _buildDetailCard(
                    'Location',
                    activity['location'] is String
                        ? activity['location']
                        : activity['location'] == true
                            ? 'Location Available'
                            : 'No Location',
                    Icons.location_on),
                _buildDetailCard(
                  'Tags',
                  tags.isNotEmpty
                      ? tags.map((tag) => tag['name']).join(', ')
                      : 'No Tags',
                  Icons.category,
                ),
                _buildDetailCard('Privacy',
                    activity['privacy'] ?? 'No Privacy Info', Icons.lock),
                _buildDetailCard(
                    'Organized by',
                    activity['user_id'] is List
                        ? (activity['user_id'].isNotEmpty
                            ? activity['user_id'][1].toString()
                            : 'No User Info')
                        : (activity['user_id']?.toString() ?? 'No User Info'),
                    Icons.person),
                _buildDetailCard(
                    'Description',
                    activity['description'] is String
                        ? activity['description']
                        : (activity['description'] == true
                            ? 'Description Available'
                            : 'No Description'),
                    Icons.description),
                _buildDetailCard(
                  'Reminders',
                  alarms.isNotEmpty
                      ? alarms.map((alarm) => alarm['name']).join(', ')
                      : 'No Reminders',
                  Icons.notifications,
                ),
                SizedBox(
                  height: 20,
                ),
                if (activity['videocall_location'] != null &&
                    activity['videocall_location'] is String)
                  _buildVideoCallButton(activity['videocall_location'])
                else if (!isGeneratedMeetingLink)
                  _buildGenerateVideoCallButton(activity['id']??0)
                else
                  _buildVideoCallButton(meetingLocation),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<DateTime?> showCustomDateTimePicker(
      BuildContext context, DateTime initialDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.purple,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        return combinedDateTime;
      }
    }

    return null;
  }

  void _showEditActivityDialog(
    BuildContext context,
    dynamic activity,
    List<dynamic> attendees,
    List<dynamic> tags,
    List<dynamic> alarms,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditActivityPage(
                client: client,
                activity: activity,
                attendees: attendees,
                tags: tags,
                alarms: alarms,
                attendeesList: widget.attendeesList,
                calendarTagsDetails: widget.calendarTagsDetails,
                calendarAlarmDetails: widget.calendarAlarmDetails,
                userDetails: widget.userDetails,
                onSave: refreshActivityDetails,
              )),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    bool isTagOrReminder = title == 'Tags' || title == 'Reminders';
    List<String> items = value.split(',');

    Color getRandomColor() {
      Random random = Random();
      return Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        0.6,
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title),
        subtitle: isTagOrReminder
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items
                    .map(
                      (item) => Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        margin: EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: getRandomColor(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.trim(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
              )
            : Text(value),
      ),
    );
  }

  Widget _buildAttendeesSection(List<dynamic> attendees) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Attendees'),
          ...attendees.map<Widget>((attendee) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: attendee['image'],
              ),
              title: Text(attendee['name']),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVideoCallButton(String url) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          final Uri videoUrl = Uri.parse(url);
          launchUrl(videoUrl);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
        child: Text(
          'Join Video Call',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _setDiscussVideocallLocation(int id) async {
    try {
      final response = await client?.callKw({
        'model': 'calendar.event',
        'method': 'get_discuss_videocall_location',
        'args': [],
        'kwargs': {},
      });

      print("Response Type: ${response.runtimeType}");
      print("Response Data: $response");

      final responseData = await client?.callKw({
        'model': 'calendar.event',
        'method': 'write',
        'args': [
          [id],
          {'videocall_location': response},
        ],
        'kwargs': {},
      });

      print("Write Response: $responseData");

      final searchResponse = await client?.callKw({
        'model': 'calendar.event',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', id]
          ],
          ['videocall_location'],
        ],
        'kwargs': {},
      });

      print("Search Response: $searchResponse");
      if (searchResponse != null && searchResponse.isNotEmpty) {
        final updatedVideocallLocation =
            searchResponse[0]['videocall_location'];
        print("Updated Video Call Location: $updatedVideocallLocation");
        setState(() {
          isGeneratedMeetingLink = true;
          meetingLocation = updatedVideocallLocation;
        });
      } else {
        print("No video call location found for the event.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Widget _buildGenerateVideoCallButton(int id) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          _setDiscussVideocallLocation(id);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
        child: Text(
          'Generate Video Call',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class EditActivityPage extends StatefulWidget {
  final dynamic activity;
  final List<dynamic> attendees;
  final List<dynamic> tags;
  final List<dynamic> alarms;
  final List<dynamic> calendarTagsDetails;
  final List<dynamic> calendarAlarmDetails;
  final List<dynamic> attendeesList;
  final List<dynamic> userDetails;
  final OdooClient? client;
  final Function onSave;

  const EditActivityPage({
    Key? key,
    required this.activity,
    required this.tags,
    required this.attendees,
    required this.alarms,
    required this.calendarTagsDetails,
    required this.calendarAlarmDetails,
    required this.attendeesList,
    required this.userDetails,
    required this.client,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditActivityPageState createState() => _EditActivityPageState();
}

class _EditActivityPageState extends State<EditActivityPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _startController;
  late TextEditingController _stopController;
  late TextEditingController _durationController;
  late TextEditingController _locationController;
  late TextEditingController _organizerController;
  late TextEditingController _descriptionController;

  String? _privacy;
  DateTime? _startDate;
  DateTime? _stopDate;
  int? _selectedOrganizerId;
  List<int>? _selectedCategIds;
  List<int>? _selectedPartnerIds;
  List<int>? _selectedReminderIds;
  String? _errorMessage;

  void _updateDuration() {
    if (_startDate == null && _startController.text.isNotEmpty) {
      _startDate = DateFormat('yyyy-MM-dd HH:mm').parse(_startController.text);
    }
    if (_stopDate == null && _stopController.text.isNotEmpty) {
      _stopDate = DateFormat('yyyy-MM-dd HH:mm').parse(_stopController.text);
    }
    if (_startDate != null && _stopDate != null) {
      final duration = _stopDate!.difference(_startDate!);
      setState(() {
        final hours = duration.inHours;
        final minutes = (duration.inMinutes % 60);
        _durationController.text = '$hours hours, $minutes minutes';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(
      text:
          widget.activity['start'] != null && widget.activity['start'] != false
              ? DateFormat('yyyy-MM-dd HH:mm')
                  .format(DateTime.parse(widget.activity['start']))
              : 'None',
    );

    _stopController = TextEditingController(
      text: widget.activity['stop'] != null && widget.activity['stop'] != false
          ? DateFormat('yyyy-MM-dd HH:mm')
              .format(DateTime.parse(widget.activity['stop']))
          : 'None',
    );

    _durationController = TextEditingController(
      text: widget.activity['duration'] != null &&
              widget.activity['duration'] != false
          ? '${widget.activity['duration'].toStringAsFixed(2)} hours'
          : 'None',
    );

    _locationController = TextEditingController(
      text: widget.activity['location'] != null &&
              widget.activity['location'] != false
          ? (widget.activity['location'] is String
              ? widget.activity['location']
              : widget.activity['location']?.toString() ?? '')
          : 'None',
    );

    _descriptionController = TextEditingController(
      text: widget.activity['description'] != null &&
              widget.activity['description'] != false
          ? (widget.activity['description'] is String
              ? parseHtmlString(widget.activity['description'])
              : widget.activity['description']?.toString() ?? '')
          : 'None',
    );

    _selectedCategIds = widget.activity['categ_ids'] != null &&
            widget.activity['categ_ids'] != false &&
            widget.activity['categ_ids'].isNotEmpty
        ? List<int>.from(widget.activity['categ_ids'])
        : [];

    _privacy = widget.activity['privacy'] != null &&
            widget.activity['privacy'] != false
        ? widget.activity['privacy']
        : 'None';

    _selectedReminderIds = widget.activity['alarm_ids'] != null &&
            widget.activity['alarm_ids'] != false &&
            widget.activity['alarm_ids'].isNotEmpty
        ? List<int>.from(widget.activity['alarm_ids'])
        : [];

    _selectedPartnerIds = widget.activity['partner_ids'] != null &&
            widget.activity['partner_ids'] != false &&
            widget.activity['partner_ids'].isNotEmpty
        ? List<int>.from(widget.activity['partner_ids'])
        : [];

    _selectedOrganizerId = widget.activity['user_id'] != null &&
            widget.activity['user_id'] != false
        ? widget.activity['user_id'] is List
            ? (widget.activity['user_id'] as List<dynamic>).first as int?
            : widget.activity['user_id'] as int?
        : null;
  }

  @override
  void dispose() {
    _startController.dispose();
    _stopController.dispose();
    _durationController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String parseHtmlString(String htmlString) {
    final document = parse(htmlString);
    return document.body?.text ?? '';
  }

  Future<DateTime?> showCustomDateTimePicker(
      BuildContext context, DateTime initialDate) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.purple,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (pickedTime != null) {
        DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        return combinedDateTime;
      }
    }

    return null;
  }


  @override
  Widget build(BuildContext context) {
    print(widget.calendarTagsDetails);
    print(widget.calendarAlarmDetails);
    print(widget.userDetails);
    print("widgetwidgetwidgetwidgetwidgetwidgetwidgetwidgetwidgetwidget");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Activity',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  readOnly: true,
                  controller: _startController,
                  onTap: () async {
                    final DateTime? selectedDateTime =
                        await showCustomDateTimePicker(
                      context,
                      DateTime.now(),
                    );
                    if (selectedDateTime != null) {
                      setState(() {
                        _startDate = selectedDateTime;
                        _startController.text = DateFormat('yyyy-MM-dd HH:mm')
                            .format(selectedDateTime);
                        _updateDuration();
                      });
                    }
                  },
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    labelText: 'Start',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  readOnly: true,
                  controller: _stopController,
                  onTap: () async {
                    final DateTime? selectedDateTime =
                        await showCustomDateTimePicker(
                      context,
                      DateTime.now(),
                    );
                    if (selectedDateTime != null) {
                      setState(() {
                        _stopDate = selectedDateTime;
                        _stopController.text = DateFormat('yyyy-MM-dd HH:mm')
                            .format(selectedDateTime);
                        _updateDuration();
                      });
                    }
                  },
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    labelText: 'Stop',
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _durationController,
                  readOnly: true,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    labelText: 'Duration',
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    labelText: 'Location for online meeting',
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.teal,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                        child: Text(
                          'Add Attendees',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MultiSelectDropdown.simpleList(
                          list: widget.attendeesList
                              .map((partner) => partner['name'])
                              .toList(),
                          initiallySelected: _selectedPartnerIds != null
                              ? widget.attendeesList
                                  .where((partner) => _selectedPartnerIds!
                                      .contains(partner['id']))
                                  .map((partner) => partner['name'])
                                  .toList()
                              : [],
                          onChange: (selectedItems) {
                            List<int> selectedPartnerIds = [];

                            for (var item in selectedItems) {
                              var matchingPartner =
                                  widget.attendeesList.firstWhere(
                                (partner) => partner['name'] == item,
                                orElse: () => null,
                              );
                              if (matchingPartner != null) {
                                selectedPartnerIds.add(matchingPartner['id']);
                              }
                            }

                            setState(() {
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
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.teal,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                        child: Text(
                          'Tags',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MultiSelectDropdown.simpleList(
                          list: widget.calendarTagsDetails
                              .map((tag) => tag['name'])
                              .toList(),
                          initiallySelected: _selectedCategIds != null
                              ? widget.calendarTagsDetails
                                  .where((tag) =>
                                      _selectedCategIds!.contains(tag['id']))
                                  .map((tag) => tag['name'])
                                  .toList()
                              : [],
                          onChange: (selectedItems) {
                            List<int> selectedTagIds = [];

                            for (var item in selectedItems) {
                              var matchingTag =
                                  widget.calendarTagsDetails.firstWhere(
                                (tag) => tag['name'] == item,
                                orElse: () => null,
                              );
                              if (matchingTag != null) {
                                selectedTagIds.add(matchingTag['id']);
                              }
                            }

                            setState(() {
                              _selectedCategIds = selectedTagIds;
                            });
                          },
                          includeSearch: true,
                          includeSelectAll: true,
                          isLarge: false,
                          numberOfItemsLabelToShow: 3,
                          checkboxFillColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _privacy,
                  items: {
                    'public': 'Public',
                    'private': 'Private',
                    'confidential': 'Only Internal Users',
                  }
                      .entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    labelText: 'Privacy',
                  ),
                  onChanged: (value) => setState(() => _privacy = value),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _selectedOrganizerId,
                  items: widget.userDetails.map((tag) {
                    return DropdownMenuItem<int>(
                      value: tag['id'],
                      child: Text(tag['name']),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    labelText: 'Organizer',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedOrganizerId = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    labelText: 'Description',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.teal,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                        child: Text(
                          'Reminder',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MultiSelectDropdown.simpleList(
                          list: widget.calendarAlarmDetails
                              .map((reminder) => reminder['name'])
                              .toList(),
                          initiallySelected: _selectedReminderIds != null
                              ? widget.calendarAlarmDetails
                                  .where((reminder) => _selectedReminderIds!
                                      .contains(reminder['id']))
                                  .map((reminder) => reminder['name'])
                                  .toList()
                              : [],
                          onChange: (selectedItems) {
                            List<int> selectedReminderIds = [];

                            for (var item in selectedItems) {
                              var matchingReminder =
                                  widget.calendarAlarmDetails.firstWhere(
                                (reminder) => reminder['name'] == item,
                                orElse: () => null,
                              );
                              if (matchingReminder != null) {
                                selectedReminderIds.add(matchingReminder['id']);
                              }
                            }

                            setState(() {
                              _selectedReminderIds = selectedReminderIds;
                            });
                          },
                          includeSearch: true,
                          includeSelectAll: true,
                          isLarge: false,
                          numberOfItemsLabelToShow: 3,
                          checkboxFillColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _errorMessage = null;
                      });
                      Map<String, dynamic> updated_details = {
                        'id': widget.activity['id'],
                        'start': _startController.text,
                        'stop': _stopController.text,
                        'duration': _durationController.text,
                        'location': _locationController.text,
                        'tags': _selectedCategIds,
                        'privacy': _privacy,
                        'organizer': _selectedOrganizerId,
                        'description': _descriptionController.text,
                        'reminders': _selectedReminderIds,
                        'partner_ids': _selectedPartnerIds
                      };
                      await updateCRMActivity(updated_details);
                      if (_errorMessage == null || _errorMessage!.isEmpty) {
                        widget.onSave();
                        Navigator.of(context).pop(true);
                      } else {
                        widget.onSave();
                        Navigator.of(context).pop(true);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      "Save",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> updateCRMActivity(Map<String, dynamic> updatedDetails) async {
    try {
      print(updatedDetails['partner_ids']);
      print(updatedDetails['reminders']);
      print("updatedDetails['reminders']");
      final response = await widget.client?.callKw({
        'model': 'calendar.event',
        'method': 'write',
        'args': [
          [updatedDetails['id']],
          {
            'start': updatedDetails['start'],
            'stop': updatedDetails['stop'],
            'location': updatedDetails['location'],
            'categ_ids': updatedDetails['tags'],
            'privacy': updatedDetails['privacy'],
            'user_id': updatedDetails['organizer'],
            'description': updatedDetails['description'],
            'alarm_ids': updatedDetails['reminders'],
            'partner_ids': updatedDetails['partner_ids']
          },
        ],
        'kwargs': {},
      });
      if (response == true) {
      } else {
        _errorMessage = "Please try after some times";
      }
    } catch (e) {
      _errorMessage = "Please check your network";
    }
  }
}
