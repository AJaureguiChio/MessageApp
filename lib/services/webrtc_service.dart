import 'package:firebase_auth/firebase_auth.dart';

import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_signal.dart';

class WebRTCService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  RTCPeerConnection? _peer;
  MediaStream? _localStream;

  // Para la pantalla
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> openUserMedia() async {
    // 1. inicializar renders PRIMERO
    await initRenderers();

    // 2. después abrir cámara
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    localRenderer.srcObject = _localStream;
  }

  Future<void> hangUp() async {
    // 1. hardware
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _peer?.close();

    // 2. BORRAR TODAS las señales de la sala actual
    final room = _roomId(currentUid, ''); // sala del par actual
    final snap = await _db
        .collection('calls')
        .doc(room)
        .collection('signals')
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }

    // 3. renders
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
  }

  /* ---------- CREAR OFERTA ---------- */
  Future<String> createOffer(String calleeId) async {
    await openUserMedia();
    _peer = await _createPeer();
    final offer = await _peer!.createOffer();
    await _peer!.setLocalDescription(offer);

    final signal = CallSignal(
      type: 'offer',
      sdp: jsonEncode(offer.toMap()),
      callerId: currentUid,
      calleeId: calleeId,
    );
    // guardamos en una “room” única
    final roomId = _roomId(currentUid, calleeId);
    await _db
        .collection('calls')
        .doc(roomId)
        .collection('signals')
        .add(signal.toMap());
    return roomId;
  }

  /* ---------- ESCUCHAR OFERTA / RESPUESTA / CANDIDATOS ---------- */
  void listenSignals(String roomId, bool amICaller) {
    _db
        .collection('calls')
        .doc(roomId)
        .collection('signals')
        .orderBy('timestamp')
        .snapshots()
        .listen((snap) async {
          for (var change in snap.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final sig = CallSignal.fromMap(change.doc.data()!);
              if (sig.type == 'offer' && !amICaller) {
                await handleOffer(sig.sdp!, sig.callerId);
              } else if (sig.type == 'answer' && amICaller) {
                print('✅ Answer recibida');
                await _handleAnswer(sig.sdp!);
              } else if (sig.type == 'candidate') {
                print('🧊 Ice candidate recibido');
                await _handleCandidate(sig.candidate!);
              }
            }
          }
        });
  }

  /* ---------- HANDLERS ---------- */
Future<void> handleOffer(String sdp, String callerId) async {
  print('📞 Procesando offer...');
  _peer = await _createPeer();
  // sdp ya es Map<String,dynamic>
  await _peer!.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
  await openUserMedia();
  final answer = await _peer!.createAnswer();
  await _peer!.setLocalDescription(answer);

  final signal = CallSignal(
    type: 'answer',
    sdp: jsonEncode(answer.toMap()),
    callerId: currentUid,
    calleeId: callerId,
  );
  final roomId = _roomId(callerId, currentUid);
  await _db
      .collection('calls')
      .doc(roomId)
      .collection('signals')
      .add(signal.toMap());
  print('📡 Answer enviada a room $roomId');
}

Future<void> _handleAnswer(String sdp) async {
  // sdp ya es Map<String,dynamic>
  await _peer!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  print('✅ Answer procesada y aplicada');
}

  Future<void> _handleCandidate(String candidate) async {
    await _peer!.addCandidate(RTCIceCandidate(candidate, '', 0));
  }

  /* ---------- PEER CONFIG ---------- */
  Future<RTCPeerConnection> _createPeer() async {
    final peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    });

    peer.onIceCandidate = (candidate) {
      final signal = CallSignal(
        type: 'candidate',
        candidate: jsonEncode(candidate.toMap()),
        callerId: currentUid,
        calleeId: '', // se rellena en listenSignals
      );
      final roomId = _roomId(currentUid, ''); // ajusta según contexto
      _db
          .collection('calls')
          .doc(roomId)
          .collection('signals')
          .add(signal.toMap());
    };

    peer.onTrack = (event) {
      if (event.track.kind == 'video') {
        print('🎞️ Track remoto recibido!');
        remoteRenderer.srcObject = event.streams[0];
      }
    };
    return peer;
  }

  String _roomId(String a, String b) {
    final list = [a, b]..sort();
    return list.join('_');
  }
}
