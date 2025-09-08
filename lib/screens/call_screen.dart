import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final String roomId;
  final String otherUid;
  final bool amICaller;
  const CallScreen({
    super.key,
    required this.roomId,
    required this.otherUid,
    required this.amICaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final WebRTCService _service;

  @override
  void initState() {
    super.initState();
    _service = WebRTCService();
    _service.initRenderers().then((_) {
      // 1. abre TU cámara
      _service.openUserMedia().then((_) => setState(() {}));
      // 2. escucha señales (cuando el otro responda cambiamos vista)
      _service.listenSignals(widget.roomId, widget.amICaller);
    });
  }

  @override
  void dispose() {
    _service.hangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Tu cámara (grande mientras esperas)
          Positioned.fill(
            child: RTCVideoView(_service.localRenderer, mirror: true),
          ),
          // Texto de espera
          const Center(
            child: Text(
              'Esperando respuesta…',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          // Mini-preview de tu cámara (mismo video, solo más pequeño)
          Positioned(
            right: 20,
            top: 40,
            width: 120,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
              ),
              child: RTCVideoView(_service.localRenderer, mirror: true),
            ),
          ),
          // Botón colgar
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.call_end),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
