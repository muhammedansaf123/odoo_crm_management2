import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multiselect_dropdown_flutter/multiselect_dropdown_flutter.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'activity.dart';

class Calendar extends StatefulWidget {
  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  int? userId;
  OdooClient? client;
  String url = "";
  List<dynamic> calendarDetails = [];
  List<dynamic> attendeesList = [];
  List<dynamic> calendarTagsDetails = [];
  List<dynamic> calendarAlarmDetails = [];
  List<dynamic> userDetails = [];
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  List<dynamic> selectedActivities = [];
  List<Map<String, dynamic>> attendeesDetails = [];
  bool isGeneratedMeetingLink = false;
  String meetingLocation = '';


  @override
  void initState() {
    super.initState();
    _initializeOdooClient();
  }

  Future<void> reloadCRM() async {
    print("ddddddddddddddddddddddddddddddddddddddd");
    _initializeOdooClient();
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
    await getTagsDetails();
    await getReminderDetails();
    await getUsers();
    await getAttendeesList();
  }

  Future<void> getCalendarDetails() async {
    try {
      final response = await client?.callKw({
        'model': 'calendar.event',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {'fields': []},
      });

      if (response != null) {
        setState(() {
          calendarDetails = response;
          print(calendarDetails);
          print("calendarDetails");
          _filterActivitiesForDate(selectedDate);
        });
      }
    } catch (e) {
      print("Error fetching calendar details: $e");
    }
  }


  Future<void> refreshActivityDetails() async {
    await getCalendarDetails();
    setState(() {});
  }


  Future<void> getTagsDetails() async {
    try {
      final response = await client?.callKw({
        'model': 'calendar.event.type',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {'fields': []},
      });

      if (response != null) {
        setState(() {
          calendarTagsDetails = response;
          print(calendarTagsDetails);
          print("calendarTagsDetailscalendarTagsDetails");
        });
      }
    } catch (e) {
      print("Error fetching calendar details: $e");
    }
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

  Future<void> getReminderDetails() async {
    try {
      final response = await client?.callKw({
        'model': 'calendar.alarm',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {'fields': []},
      });

      if (response != null) {
        setState(() {
          calendarAlarmDetails = response;
          print(calendarAlarmDetails);
          print("alarmDetails");
        });
      }
    } catch (e) {
      print("Error fetching calendar details: $e");
    }
  }

  Future<void> getUsers() async {
    try {
      final response = await client?.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [[]],
        'kwargs': {'fields': []},
      });

      if (response != null) {
        setState(() {
          userDetails = response;
          print(userDetails);
          print("userDetailsuserDetails");
        });
      }
    } catch (e) {
      print("Error fetching calendar details: $e");
    }
  }

  Future<void> _filterActivitiesForDate(DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    setState(() {
      selectedActivities = [];
      selectedActivities = calendarDetails.where((activity) {
        final startDate = activity['start'];
        if (startDate == null) return false;
        try {
          final parsedStartDate = DateTime.parse(startDate);
          return DateFormat('yyyy-MM-dd').format(parsedStartDate) == dateString;
        } catch (e) {
          print("Error parsing date: $e");
          return false;
        }
      }).toList();
    });

    for (var activity in selectedActivities) {
      print(activity);
      print("activityactivityactivity");
      attendeesDetails.clear();

      if (activity['partner_ids'] != null) {
        final attendeeIds = activity['partner_ids']
            .where((attendee) => attendee is int)
            .toList();

        if (attendeeIds.isNotEmpty) {
          try {
            for (var partnerId in attendeeIds) {
              final responsePartner = await client?.callKw({
                'model': 'res.partner',
                'method': 'search_read',
                'args': [
                  [
                    ['id', '=', partnerId],
                    [
                      'meeting_ids',
                      'in',
                      [activity['id']]
                    ]
                  ],
                ],
                'kwargs': {
                  'fields': ['meeting_ids', 'image_1920', 'name'],
                },
              });
              print(responsePartner);
              print("responsePartnerresponsePartner");
              if (responsePartner != null && responsePartner.isNotEmpty) {
                final logoBase64 = responsePartner[0]['image_1920'];
                final partnerName = responsePartner[0]['name'] ?? 'Unknown';

                if (logoBase64 != null &&
                    logoBase64.isNotEmpty &&
                    logoBase64 != 'false') {
                  final imageData = base64Decode(logoBase64);
                  setState(() {
                    attendeesDetails.add({
                      'name': partnerName,
                      'image': MemoryImage(imageData),
                    });

                    if (activity['partner'] == null) {
                      activity['partner'] = [];
                    }
                    activity['partner'].clear();
                    activity['partner'].addAll(attendeesDetails);
                  });
                }
              }
            }
          } catch (e) {
            print("Error fetching partner details: $e");
          }
        }
      }
      if (activity['categ_ids'] != null) {
        final categoryIds = activity['categ_ids'];
        if (categoryIds.isNotEmpty) {
          try {
            final responseCategories = await client?.callKw({
              'model': 'calendar.event.type',
              'method': 'search_read',
              'args': [
                [
                  ['id', 'in', categoryIds]
                ]
              ],
              'kwargs': {
                'fields': ['name'],
              },
            });
            print(responseCategories);
            print("responseCategories");
            if (responseCategories != null && responseCategories.isNotEmpty) {
              final tagNames = responseCategories
                  .map((category) => category['name'])
                  .toList();
              setState(() {
                activity['tag_names'] = tagNames;
              });
            }
          } catch (e) {
            print("Error fetching category names: $e");
          }
        }
      }
    }
  }

  void _showYearMonthPicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: focusedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            primaryColor: Colors.purple,
            colorScheme: ColorScheme.light(primary: Colors.purple),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        focusedDate = pickedDate;
        selectedDate = pickedDate;
        _filterActivitiesForDate(pickedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 20, color: Colors.teal),
                    onPressed: () {
                      setState(() {
                        focusedDate = DateTime(
                          focusedDate.year,
                          focusedDate.month - 1,
                        );
                      });
                    },
                  ),
                  TextButton(
                    onPressed: _showYearMonthPicker,
                    child: Text(
                      DateFormat.yMMMM().format(focusedDate),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios,
                        size: 20, color: Colors.teal),
                    onPressed: () {
                      setState(() {
                        focusedDate = DateTime(
                          focusedDate.year,
                          focusedDate.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              TableCalendar(
                firstDay: DateTime.utc(2000),
                lastDay: DateTime.utc(2100),
                focusedDay: focusedDate,
                selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    selectedDate = selectedDay;
                    _filterActivitiesForDate(selectedDay);
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    focusedDate = focusedDay;
                  });
                },
                headerVisible: false,
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: Colors.black),
                  weekendTextStyle: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Activities",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                        color: Colors.black),
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    onPressed: () {
                      _showActivityCreationDialog(
                          context,
                          selectedDate,
                          attendeesList,
                          calendarTagsDetails,
                          calendarAlarmDetails,
                          userDetails);
                    },
                    icon: Icon(
                      Icons.add,
                      color: Colors.red,
                      size: 30.0,
                    ),
                  )
                ],
              ),
              SizedBox(height: 10),
              selectedActivities.isEmpty
                  ? Center(
                      child: Text(
                        'No activities for selected date',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: selectedActivities.length,
                      itemBuilder: (context, index) {
                        final activity = selectedActivities[index];
                        final currentAttendee =
                            activity['current_attendee'] ?? [];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActivityDetailPage(
                                    reloadCRM: reloadCRM,
                                    activity: activity,
                                    attendeesList: attendeesList,
                                    calendarTagsDetails: calendarTagsDetails,
                                    calendarAlarmDetails: calendarAlarmDetails,
                                    userDetails: userDetails),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            margin: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 0),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['name'] ?? 'No Title',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '${activity['display_time'] ?? 'No Display Name'}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Duration: ${activity['duration'] ?? 'No Duration'} hours',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),
                                  SizedBox(height: 12),
                                  if (activity['partner'] != null &&
                                      activity['partner'].isNotEmpty)
                                    AttendeesWidget(
                                      partners: activity['partner'],
                                    ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  if (activity['videocall_location'] != false)
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          print(activity['videocall_location']);
                                          final url =
                                              activity['videocall_location'];
                                          if (url != null) {
                                            launchUrl(Uri.parse(url));
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Join Video Call',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                  else if (activity['videocall_location'] == false)
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _setDiscussVideocallLocation(
                                              activity['id']);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Generate Video Call',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                  else
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          print(activity['videocall_location']);
                                          final url =
                                              activity['videocall_location'];
                                          if (url != null) {
                                            launchUrl(Uri.parse(url));
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          'Join Video Call',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
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

  void _showActivityCreationDialog(BuildContext context, selectedDate, attendeesList,
      calendarTagsDetails, calendarAlarmDetails, userDetails) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => CreateActivityPage(
              client: client,
              selectedDate: selectedDate,
              attendeesList: attendeesList,
              calendarTagsDetails: calendarTagsDetails,
              calendarAlarmDetails: calendarAlarmDetails,
              userDetails: userDetails,
              onSave: refreshActivityDetails)),
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
          getCalendarDetails();
        });
      } else {
        print("No video call location found for the event.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }
}

class AttendeesWidget extends StatefulWidget {
  final List<dynamic> partners;

  AttendeesWidget({required this.partners});

  @override
  _AttendeesWidgetState createState() => _AttendeesWidgetState();
}

class _AttendeesWidgetState extends State<AttendeesWidget> {
  bool _isFullListVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendees:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        if (widget.partners.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ...widget.partners
                  .take(_isFullListVisible ? widget.partners.length : 2)
                  .toSet()
                  .map<Widget>((attendee) {
                return ListTile(
                  contentPadding: EdgeInsets.only(left: 8.0),
                  leading: CircleAvatar(
                    backgroundImage: attendee['image'],
                  ),
                  title: Text(attendee['name']),
                );
              }).toList(),
              if (widget.partners.length > 2 && !_isFullListVisible)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFullListVisible = true;
                      });
                    },
                    child: Text(
                      '${widget.partners.length - 2} more attendees',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
              if (_isFullListVisible)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFullListVisible = false;
                      });
                    },
                    child: Text(
                      'Fold',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class CreateActivityPage extends StatefulWidget {
  final OdooClient? client;
  final List<dynamic> attendeesList;
  final List<dynamic> calendarTagsDetails;
  final List<dynamic> calendarAlarmDetails;
  final List<dynamic> userDetails;
  final DateTime selectedDate;
  final Function onSave;

  const CreateActivityPage({
    Key? key,
    required this.client,
    required this.attendeesList,
    required this.calendarTagsDetails,
    required this.calendarAlarmDetails,
    required this.userDetails,
    required this.selectedDate,
    required this.onSave,
  }) : super(key: key);

  @override
  _CreateActivityPageState createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _stopController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<dynamic> userDetails = [];
  List<Map<String, dynamic>> attendeesDetails = [];
  final TextEditingController _activityNameController = TextEditingController();

  String? _privacy;
  DateTime? _startDate;
  DateTime? _stopDate;
  int? _selectedOrganizerId;
  List<int>? _selectedCategIds;
  List<int>? _selectedPartnerIds;
  List<int>? _selectedReminderIds;
  String? _errorMessage;
  bool isGeneratedMeetingLink = false;
  String meetingLocation = '';
  bool _isFullListVisible = false;
  bool _isAllDay = false;

  bool _validateName = false;
  bool _validateStart = false;
  bool _validateStop = false;

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
    print(widget.selectedDate);
    _startController.text = DateFormat('yyyy-MM-dd HH:mm').format(widget.selectedDate);
    print("selectedDateselectedDateselectedDateselectedDateselectedDateselectedDate");
    super.initState();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Activity',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage ?? '',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              TextField(
                controller: _activityNameController,
                decoration: InputDecoration(
                  labelText: 'Activity Name',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                  errorText: _validateName ? 'Name cannot be empty' : null,
                ),
                onChanged: (text) {
                  setState(() {
                    if (text.isNotEmpty) {
                      _validateName = false;
                    }
                  });
                },
              ),
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
                      _validateStart = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                  labelText: 'Start',
                  errorText: _validateStart
                      ? 'Please choose a Start Time'
                      : null,
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
                      if (_stopDate != null && _startDate != null && _stopDate!.isBefore(_startDate!)) {
                        setState(() {
                          _errorMessage = "Stop time cannot be earlier than start time";
                        });
                      }
                      _updateDuration();
                      _validateStop = false;
                    });
                  }
                },
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                  labelText: 'Stop',
                  errorText: _validateStop
                      ? 'Please choose a Stop Time'
                      : null,
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text('All Day'),
                  Checkbox(
                    value: _isAllDay,
                    onChanged: (bool? value) {
                      setState(() {
                        _isAllDay = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              if (_isFullListVisible)
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
              if (_isFullListVisible)
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
              if (_isFullListVisible)
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
              if (_isFullListVisible)
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
              if (_isFullListVisible)
                DropdownButtonFormField<int>(
                  value: _selectedOrganizerId,
                  items: widget.userDetails.map((user) {
                    return DropdownMenuItem<int>(
                      value: user['id'],
                      child: Text(user['name']),
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
              if (_isFullListVisible)
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
              SizedBox(height: 20),
              if(!_isFullListVisible)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFullListVisible = true;
                      });
                    },
                    child: Text(
                      'more options',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_activityNameController.text.isEmpty) {
                      setState(() {
                        _validateName = true;
                      });
                    }
                    else if (_startController.text.isEmpty) {
                      setState(() {
                        _validateStart = true;
                      });
                    }
                    else if (_stopController.text.isEmpty) {
                      setState(() {
                        _validateStop = true;
                      });
                    }else {
                      setState(() {
                        _errorMessage = null;
                        _validateName = true;
                      });
                      Map<String, dynamic> created_details = {
                        'name': _activityNameController.text,
                        'start': _startController.text.isNotEmpty
                            ? _startController.text
                            : null,
                        'stop': _stopController.text.isNotEmpty
                            ? _stopController.text
                            : null,
                        'duration': _durationController.text,
                        'location': _locationController.text,
                        'tags': _selectedCategIds,
                        'privacy': _privacy,
                        'organizer': _selectedOrganizerId,
                        'description': _descriptionController.text,
                        'reminders': _selectedReminderIds,
                        'partner_ids': _selectedPartnerIds,
                        'allday': _isAllDay,
                      };
                      print(created_details);
                      print("created_detailscreated_details");
                      await createCRMActivity(created_details);
                      if (_errorMessage == null || _errorMessage!.isEmpty) {
                        widget.onSave();
                        Navigator.of(context).pop(true);
                      } else {
                        widget.onSave();
                        Navigator.of(context).pop(true);
                      }
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
      // ),
    );
  }

  Future<void> createCRMActivity(Map<String, dynamic> createdDetails) async {
    try {
      print(createdDetails['partner_ids']);
      print(createdDetails['reminders']);
      print("updatedDetails['reminders']dddddddddddddddddddddddddddd");
      final response = await widget.client?.callKw({
        'model': 'calendar.event',
        'method': 'create',
        'args': [
          {
            'name': createdDetails['name'] ?? '',
            'start': createdDetails['start'] ?? '',
            'stop': createdDetails['stop'] ?? '',
            'location': createdDetails['location'] ?? '',
            'categ_ids': createdDetails['tags'] ?? [],
            'privacy': createdDetails['privacy'] ?? 'public',
            'user_id': createdDetails['organizer'],
            'description': createdDetails['description'] ?? '',
            'alarm_ids': createdDetails['reminders'] ?? [],
            'partner_ids': createdDetails['partner_ids'] ?? [],
            'allday': createdDetails['allday'] ?? false,
          },
        ],
        'kwargs': {},
      });
      print(response);
      print("responseeeeeeeeeeeeeeeeeeeeeeeeeee");
      if (response == true) {
      } else {
        setState(() {
          _errorMessage = "Please try after some times";
        });
      }
    } catch (e) {
      print("ddddddddddddddddddddddddddd$e");
      setState(() {
        _errorMessage = "Please try after some times";
      });
    }
  }
}
