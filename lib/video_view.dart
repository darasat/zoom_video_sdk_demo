import 'package:flutter/material.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as flutter_zoom_view;
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';

class VideoView extends StatefulWidget {
  final ZoomVideoSdkUser? user;
  final bool sharing;
  final bool preview;
  final bool focused;
  final bool hasMultiCamera;
  final bool isPiPView;
  final String multiCameraIndex;
  final String videoAspect;
  final bool fullScreen;
  final String resolution;
  final bool isMuted;
  final bool isVideoOn;

  const VideoView({
    super.key,
    required this.user,
    required this.sharing,
    required this.preview,
    required this.focused,
    required this.hasMultiCamera,
    required this.isPiPView,
    required this.multiCameraIndex,
    required this.videoAspect,
    required this.fullScreen,
    required this.resolution,
    required this.isMuted,
    required this.isVideoOn,
  });

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  Map<String, dynamic> _getCreationParams() {
    final params = <String, dynamic>{
      'userId': widget.user?.userId,
      'sharing': widget.sharing,
      'preview': widget.preview,
      'focused': widget.focused,
      'hasMultiCamera': widget.hasMultiCamera,
      'isPiPView': widget.isPiPView,
      'videoAspect': widget.videoAspect.isEmpty
          ? VideoAspect.PanAndScan
          : widget.videoAspect,
      'fullScreen': widget.fullScreen,
    };
    if (widget.resolution.isNotEmpty) {
      params['resolution'] = widget.resolution;
    }
    return params;
  }

  @override
  Widget build(BuildContext context) {
    return GridTile(
      footer: Container(
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.user?.userName ?? 'N/A',
              style: const TextStyle(color: Colors.white),
            ),
            Icon(
              widget.isMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            )
          ],
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        child: widget.isVideoOn
            ? flutter_zoom_view.View(
                key: UniqueKey(),
                creationParams: _getCreationParams(),
              )
            : const Center(child: Text('User')),
      ),
    );
  }
}
