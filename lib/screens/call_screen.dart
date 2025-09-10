import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/webrtc_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_signal.dart';

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
    _service.initRenderers().then((_) async {
      await _service.openUserMedia();
      setState(() {});

      // 1. Procesar CUALQUIER offer que ya esté en la sala
      final snap = await FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.roomId)
          .collection('signals')
          .where('type', isEqualTo: 'offer')
          .get();

      print('🔎 Ofertas ya en sala: ${snap.docs.length}');

      if (snap.docs.isNotEmpty && !widget.amICaller) {
        final sig = CallSignal.fromMap(snap.docs.first.data());
        print('📞 Procesando offer encontrada');
        await _service.handleOffer(sig.sdp!, sig.callerId); // público
      }

      // 2. Escuchar nuevas señales
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
    // ¿Ya hay video del otro?
    final hasRemote = _service.remoteRenderer.srcObject != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Cámara GRANDE: remoto si existe, si no local
          Positioned.fill(
            child: RTCVideoView(
              hasRemote ? _service.remoteRenderer : _service.localRenderer,
              mirror: !hasRemote,
            ),
          ),

          // Miniatura: siempre la propia
          if (hasRemote)
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

          // Texto mientras no hay remoto
          if (!hasRemote)
            const Center(
              child: Text(
                'Esperando respuesta…',
                style: TextStyle(color: Colors.white, fontSize: 24),
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
