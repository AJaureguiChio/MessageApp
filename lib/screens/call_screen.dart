import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final String roomId;   // puedes pasarlo al abrir la pantalla
  final bool amICaller;

  const CallScreen({
    Key? key,
    required this.roomId,
    required this.amICaller,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final WebRTCService _webrtc;

  @override
  void initState() {
    super.initState();
    _webrtc = WebRTCService();
    _init();
  }

  Future<void> _init() async {
    await _webrtc.initRenderers();
    await _webrtc.openUserMedia();

    // if (widget.amICaller) {
    //   await _webrtc.createRoom(widget.roomId);
    // } else {
    //   await _webrtc.joinRoom(widget.roomId);
    // }

    _webrtc.listenSignals(widget.roomId, widget.amICaller);
  }

  @override
  void dispose() {
    _webrtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Videollamada'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Video remoto (pantalla completa)
          Positioned.fill(
            child: RTCVideoView(
              _webrtc.remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          // Video local (pequeña ventana flotante)
          Positioned(
            right: 16,
            top: 16,
            width: 120,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: RTCVideoView(
                _webrtc.localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
          // Controles
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end),
                    onPressed: () async {
                      _webrtc.dispose();
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
