// import 'dart:convert';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
//
// class CallerUI extends StatefulWidget {
//   final Function onEndCall;
//   final Function onToggleMic;
//   final Function onToggleCamera;
//   final Function onStartRecording;
//   final List<Map<String, dynamic>> members;
//
//   CallerUI({
//     required this.onEndCall,
//     required this.onToggleMic,
//     required this.onToggleCamera,
//     required this.onStartRecording,
//     required this.members,
//   });
//
//   @override
//   _CallerUIState createState() => _CallerUIState();
// }
//
// class _CallerUIState extends State<CallerUI> {
//   bool isMicMuted = true;
//
//   void _toggleMic() {
//     setState(() {
//       isMicMuted = !isMicMuted;
//     });
//
//     widget.onToggleMic();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Align(
//             alignment: Alignment.topCenter,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Container(
//                 color: Colors.black.withOpacity(0.3),
//                 child: MembersList(widget.members),
//               ),
//             ),
//           ),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildCircularIconButton(
//                       icon: isMicMuted ? Icons.mic_off : Icons.mic,
//                       iconColor: isMicMuted ? Colors.red[700]! : Colors.green,
//                       onPressed: _toggleMic,
//                     ),
//                     _buildCircularIconButton(
//                       icon: Icons.videocam_off,
//                       iconColor: Colors.red[700]!,
//                       onPressed: () => widget.onToggleCamera(),
//                     ),
//                     _buildCircularIconButton(
//                       icon: Icons.call_end,
//                       iconColor: Colors.red[700]!,
//                       onPressed: () => widget.onEndCall(),
//                     ),
//                     _buildCircularIconButton(
//                       icon: Icons.fiber_manual_record,
//                       iconColor: Colors.red[700]!,
//                       onPressed: () => widget.onStartRecording(),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCircularIconButton({
//     required IconData icon,
//     required Color iconColor,
//     required VoidCallback onPressed,
//   }) {
//     return Container(
//       width: 56.0,
//       height: 56.0,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         shape: BoxShape.circle,
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: iconColor),
//         onPressed: onPressed,
//       ),
//     );
//   }
// }
//
// class MembersList extends StatelessWidget {
//   final List<Map<String, dynamic>> members;
//
//   MembersList(this.members);
//
//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       padding: const EdgeInsets.all(16.0),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 16.0,
//         mainAxisSpacing: 16.0,
//         childAspectRatio: 3 / 2,
//       ),
//       itemCount: members.length,
//       itemBuilder: (context, index) {
//         final member = members[index];
//         final imageData = member['image_1920'];
//         ImageProvider<Object>? image;
//
//         if (imageData is String) {
//           try {
//             image = MemoryImage(
//               Uint8List.fromList(base64Decode(imageData)),
//             );
//           } catch (_) {
//             image = null;
//           }
//         } else {
//           image = null;
//         }
//
//         return Card(
//           elevation: 2.0,
//           color: Colors.grey[900],
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundImage: image,
//                     child: image == null ? const Icon(Icons.person) : null,
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     member['name'] ?? 'Unknown',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w500,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:jitsi_meet/jitsi_meet.dart';
//
// class MeetingScreen extends StatelessWidget {
//   final List<Map<String, dynamic>> members;
//
//   MeetingScreen({required this.members});
//
//   void startMeeting(BuildContext context) async {
//     try {
//       var options = JitsiMeetingOptions(
//         room: 'group_call_${DateTime.now().millisecondsSinceEpoch}',
//       )
//         ..userDisplayName = 'Host'
//         ..userEmail = 'host@example.com'
//         ..audioMuted = false
//         ..videoMuted = false;
//
//       members.forEach((member) {
//         print("Inviting member: ${member['name']}");
//       });
//
//       await JitsiMeet.joinMeeting(options);
//     } catch (error) {
//       print("Error starting meeting: $error");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Failed to start the meeting: $error")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           backgroundColor: Colors.purple,
//           iconTheme: IconThemeData(
//             color: Colors.white,
//           ),
//           title: Text(
//             "Meeting Call",
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           )),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             "Start Meeting with:",
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 40),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: List.generate(
//                 members.length,
//                     (index) {
//                   final member = members[index];
//                   final imageData = member['image_1920'];
//                   ImageProvider<Object>? image;
//
//                   if (imageData is String) {
//                     try {
//                       image = MemoryImage(
//                         Uint8List.fromList(base64Decode(imageData)),
//                       );
//                     } catch (_) {
//                       image = null;
//                     }
//                   } else {
//                     image = null;
//                   }
//
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                     child: Column(
//                       children: [
//                         CircleAvatar(
//                           radius: 30,
//                           backgroundImage: image,
//                           child:
//                           image == null ? const Icon(Icons.person) : null,
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           member['name'] ?? 'Unknown',
//                           style: TextStyle(fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           SizedBox(height: 20),
//           ElevatedButton(
//               onPressed: () => startMeeting(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.teal,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text(
//                 "Start",
//                 style:
//                 TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ))
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ConferenceCallPage extends StatefulWidget {
  final String conferenceLink;

  ConferenceCallPage({required this.conferenceLink});

  @override
  _ConferenceCallPageState createState() => _ConferenceCallPageState();
}

class _ConferenceCallPageState extends State<ConferenceCallPage> {
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  List<RTCVideoRenderer> _remoteRenderers = [];
  late MediaStream _localStream;
  bool _isMuted = false;
  bool _isVideoOn = true;

  @override
  void initState() {
    super.initState();
    initRenderer();
  }

  Future<void> initRenderer() async {
    await _localRenderer.initialize();
    _startLocalStream();
  }

  Future<void> _startLocalStream() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'}
    });

    _localRenderer.srcObject = _localStream;
  }

  void startConferenceCall() {
    RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
    remoteRenderer.initialize();
    setState(() {
      _remoteRenderers.add(remoteRenderer);
    });
  }

  void toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _localStream.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  void toggleVideo() {
    setState(() {
      _isVideoOn = !_isVideoOn;
    });
    _localStream.getVideoTracks().forEach((track) {
      track.enabled = _isVideoOn;
    });
  }

  void endCall() {
    _localStream.getTracks().forEach((track) {
      track.stop();
    });
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderers.forEach((renderer) => renderer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Conference Call - ${widget.conferenceLink}")),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: RTCVideoView(_localRenderer),
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(border: Border.all(color: Colors.black)),
          ),
          // Remote videos (if there are any participants)
          Expanded(
            child: ListView.builder(
              itemCount: _remoteRenderers.length,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(10),
                  child: RTCVideoView(_remoteRenderers[index]),
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                );
              },
            ),
          ),
          // Conference Call Controls
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.mic_off : Icons.mic,
                    color: _isMuted ? Colors.red : Colors.green,
                  ),
                  onPressed: toggleMute,
                ),
                IconButton(
                  icon: Icon(
                    _isVideoOn ? Icons.videocam : Icons.videocam_off,
                    color: _isVideoOn ? Colors.green : Colors.red,
                  ),
                  onPressed: toggleVideo,
                ),
                IconButton(
                  icon: Icon(Icons.call_end, color: Colors.red),
                  onPressed: endCall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StartConferencePage extends StatelessWidget {
  String generateConferenceLink() {
    return "https://myapp.com/conference/${DateTime.now().millisecondsSinceEpoch}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Start Conference Call")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                String conferenceLink = generateConferenceLink();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConferenceCallPage(
                      conferenceLink: conferenceLink,
                    ),
                  ),
                );
              },
              child: Text("Start Conference Call"),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: StartConferencePage(),
  ));
}
