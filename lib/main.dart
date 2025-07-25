import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as zoom_view;
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'jwt_generator.dart';

void main() {
  runApp(const ZoomExampleApp());
}

class ZoomExampleApp extends StatelessWidget {
  const ZoomExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const ZoomMeetingScreen());
  }
}

class ZoomMeetingScreen extends StatefulWidget {
  const ZoomMeetingScreen({super.key});

  @override
  State<ZoomMeetingScreen> createState() => _ZoomMeetingScreenState();
}

class _ZoomMeetingScreenState extends State<ZoomMeetingScreen> {
  final ZoomVideoSdk _zoom = ZoomVideoSdk();
  final ZoomVideoSdkEventListener _eventListener = ZoomVideoSdkEventListener();
  bool isInSession = false;
  bool isMuted = true;
  bool isVideoOn = false;
  bool isLoading = false;
  bool isSdkInitialized = false;
  List<ZoomVideoSdkUser> users = [];
  List<StreamSubscription> subscriptions = [];

  final Map<String, String> sessionDetails = {
    'sessionName': 'scheduletest', // Must match 'tpc' in JWT
    'sessionPassword': '123456',
    'displayName': 'Diego Alejandro',
    'sessionTimeout': '30',
  };

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkPermissions();
    }
    _initZoomSdk();
  }

  Future<void> _checkPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    debugPrint('Camera permission: $camera, Microphone permission: $mic');
  }

  Future<void> _initZoomSdk() async {
    try {
      await _zoom.initSdk(InitConfig(domain: 'zoom.us', enableLog: true));
      debugPrint('Zoom SDK initialized successfully.');
      setState(() {
        isSdkInitialized = true;
      });
      _startSession();
    } on PlatformException catch (e) {
      debugPrint('Error initializing Zoom SDK: ${e.code} - ${e.message}');
      setState(() {
        isSdkInitialized = false;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Unexpected error initializing Zoom SDK: $e');
      setState(() {
        isSdkInitialized = false;
        isLoading = false;
      });
    }
  }

  Future<void> _startSession() async {
    if (!isSdkInitialized) {
      debugPrint('Zoom SDK not initialized. Cannot start session.');
      return;
    }
    setState(() => isLoading = true);
    try {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
      final token = generateJwt(sessionDetails['sessionName']!, '1');
      if (token.isEmpty) {
        debugPrint('Failed to generate JWT token');
        setState(() => isLoading = false);
        return;
      }
      _setupEventListeners();
      await _zoom.joinSession(
        JoinSessionConfig(
          sessionName: sessionDetails['sessionName']!,
          sessionPassword: sessionDetails['sessionPassword']!,
          token: token,
          userName: sessionDetails['displayName']!,
          audioOptions: {'connect': true, 'mute': true},
          videoOptions: {'localVideoOn': true},
          sessionIdleTimeoutMins: int.parse(sessionDetails['sessionTimeout']!),
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Error joining session: ${e.code} - ${e.message}');
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Unexpected error joining session: $e');
      setState(() => isLoading = false);
    }
  }

  void _setupEventListeners() {
    subscriptions = [
      _eventListener.addListener(EventType.onSessionJoin, (data) async {
        if (!mounted) return;
        final mySelf = ZoomVideoSdkUser.fromJson(
          jsonDecode(data['sessionUser']),
        );
        final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
        final isMutedState = await mySelf.audioStatus?.isMuted() ?? true;
        final isVideoOnState = await mySelf.videoStatus?.isOn() ?? false;
        setState(() {
          isInSession = true;
          isLoading = false;
          isMuted = isMutedState is bool
              ? isMutedState
              : isMutedState == 'true' || isMutedState == 1;
          isVideoOn = isVideoOnState is bool
              ? isVideoOnState
              : isVideoOnState == 'true' || isVideoOnState == 1;
          users = [mySelf, ...remoteUsers];
        });
      }),
      _eventListener.addListener(EventType.onSessionLeave, (_) {
        if (!mounted) return;
        setState(() {
          isInSession = false;
          users = [];
        });
        for (var subscription in subscriptions) {
          subscription.cancel();
        }
      }),
      _eventListener.addListener(EventType.onUserJoin, (data) async {
        if (!mounted) return;
        final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
        final mySelf = await _zoom.session.getMySelf();
        if (mySelf != null) {
          setState(() => users = [mySelf, ...remoteUsers]);
        }
      }),
      _eventListener.addListener(EventType.onUserLeave, (data) async {
        if (!mounted) return;
        final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
        final mySelf = await _zoom.session.getMySelf();
        if (mySelf != null) {
          setState(() => users = [mySelf, ...remoteUsers]);
        }
      }),
      _eventListener.addListener(EventType.onUserVideoStatusChanged, (
        data,
      ) async {
        if (!mounted) return;
        final mySelf = await _zoom.session.getMySelf();
        final videoStatus = await mySelf?.videoStatus?.isOn();
        if (videoStatus != null) {
          setState(
            () => isVideoOn = videoStatus is bool
                ? videoStatus
                : videoStatus == 'true' || videoStatus == 1,
          );
        }
      }),
      _eventListener.addListener(EventType.onUserAudioStatusChanged, (
        data,
      ) async {
        if (!mounted) return;
        final mySelf = await _zoom.session.getMySelf();
        final audioStatus = await mySelf?.audioStatus?.isMuted();
        if (audioStatus != null) {
          setState(
            () => isMuted = audioStatus is bool
                ? audioStatus
                : audioStatus == 'true' || audioStatus == 1,
          );
        }
      }),
    ];
  }

  Future<void> _toggleAudio() async {
    final mySelf = await _zoom.session.getMySelf();
    if (mySelf?.audioStatus == null) return;
    if (!(await Permission.microphone.isGranted)) {
      await Permission.microphone.request();
    }
    final muted = await mySelf!.audioStatus!.isMuted();
    if (muted is bool ? muted : muted == 'true' || muted == 1) {
      await _zoom.audioHelper.unMuteAudio(mySelf.userId);
    } else {
      await _zoom.audioHelper.muteAudio(mySelf.userId);
    }
    final newMutedStatus = await mySelf.audioStatus!.isMuted();
    setState(
      () => isMuted = newMutedStatus is bool
          ? newMutedStatus
          : newMutedStatus == 'true' || newMutedStatus == 1,
    );
  }

  Future<void> _toggleVideo() async {
    final mySelf = await _zoom.session.getMySelf();
    if (mySelf?.videoStatus == null) return;
    if (!(await Permission.camera.isGranted)) {
      await Permission.camera.request();
    }
    final videoOn = await mySelf!.videoStatus!.isOn();
    if (videoOn is bool ? videoOn : videoOn == 'true' || videoOn == 1) {
      await _zoom.videoHelper.stopVideo();
    } else {
      await _zoom.videoHelper.startVideo();
    }
    final newVideoStatus = await mySelf.videoStatus!.isOn();
    setState(
      () => isVideoOn = newVideoStatus is bool
          ? newVideoStatus
          : newVideoStatus == 'true' || newVideoStatus == 1,
    );
  }

  Future<void> _leaveSession() async {
    await _zoom.leaveSession(false);
    setState(() {
      isInSession = false;
      users = [];
    });
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Stack(
          children: [
            if (!isInSession)
              Center(
                child: ElevatedButton(
                  onPressed: isLoading || !isSdkInitialized
                      ? null
                      : _startSession,
                  child: Text(
                    isLoading
                        ? 'Connecting...'
                        : isSdkInitialized
                        ? 'Start Session'
                        : 'Initializing SDK...',
                  ),
                ),
              )
            else
              Stack(
                children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: users.length <= 2 ? 1 : 2,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 4 / 5,
                    ),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            zoom_view.View(
                              key: Key(user.userId),
                              creationParams: {
                                'userId': user.userId,
                                'videoAspect': 'FullFilled',
                                'fullScreen': false,
                              },
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                color: Colors.black54,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      user.userName ?? 'N/A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    FutureBuilder(
                                      future:
                                          user.audioStatus?.isMuted() ??
                                          Future.value(true),
                                      builder: (context, snapshot) {
                                        final muted = snapshot.data is bool
                                            ? snapshot.data!
                                            : snapshot.data == 'true' ||
                                                  snapshot.data == 1;
                                        return Icon(
                                          muted ? Icons.mic_off : Icons.mic,
                                          color: Colors.white,
                                          size: 20,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _toggleAudio,
                            icon: Icon(
                              isMuted ? Icons.mic_off : Icons.mic,
                              color: Colors.white,
                            ),
                            iconSize: 40,
                            tooltip: isMuted ? 'Unmute' : 'Mute',
                          ),
                          IconButton(
                            onPressed: _toggleVideo,
                            icon: Icon(
                              isVideoOn ? Icons.videocam : Icons.videocam_off,
                              color: Colors.white,
                            ),
                            iconSize: 40,
                            tooltip: isVideoOn ? 'Stop Video' : 'Start Video',
                          ),
                          IconButton(
                            onPressed: _leaveSession,
                            icon: const Icon(Icons.call_end, color: Colors.red),
                            iconSize: 40,
                            tooltip: 'Leave Session',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
