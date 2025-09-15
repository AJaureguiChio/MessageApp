import 'package:firebase_auth/firebase_auth.dart';
export '../screens/call_screen.dart';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_signal.dart';
import 'package:flutter/foundation.dart';

class WebRTCService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  final List<RTCIceCandidate> _pendingCandidates = [];

  RTCPeerConnection? _peer;
  bool _peerReady = false;
  MediaStream? _localStream;
  String? _lastRoomId;
  bool _mediaOpened = false;

  // Renderers
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // Notificador de UI
  final ValueNotifier<bool> uiUpdate = ValueNotifier(false);

  Future<void> initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> openUserMedia() async {
    if (_mediaOpened) return;
    _mediaOpened = true;
    await initRenderers();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': true,
    });
    localRenderer.srcObject = _localStream;

    if (_peer != null) {
      _localStream!.getTracks().forEach((track) {
        _peer!.addTrack(track, _localStream!);
      });
    }
  }

  Future<void> hangUp() async {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _peer?.close();
    _peer = null;
    _peerReady = false;

    if (_lastRoomId != null) {
      await _db.collection('calls').doc(_lastRoomId).delete();
      _lastRoomId = null;
    }

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
  }

  /* ---------- CREAR OFERTA ---------- */
  Future<String> createOffer(String calleeId) async {
    await openUserMedia();
    _peer = await _createPeer(calleeId);

    final offer = await _peer!.createOffer();
    await _peer!.setLocalDescription(offer);

    final signal = CallSignal(
      type: 'offer',
      sdp: jsonEncode(offer.toMap()),
      callerId: currentUid,
      calleeId: calleeId,
    );

    final roomId = _roomId(currentUid, calleeId);
    await _db
        .collection('calls')
        .doc(roomId)
        .collection('signals')
        .add(signal.toMap());
    _lastRoomId = roomId;
    print('📡 oferta guardada en sala: $roomId');
    return roomId;
  }

  /* ---------- ESCUCHAR SEÑALES ---------- */
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
                if (sig.sdpString == null || sig.sdpString!.isEmpty) return;
                await handleOffer(sig.sdpString!, sig.callerId);
              } else if (sig.type == 'answer' && amICaller) {
                if (sig.sdpString == null || sig.sdpString!.isEmpty) return;
                await _handleAnswer(sig.sdpString!);
              } else if (sig.type == 'candidate') {
                if (sig.candidate == null || sig.candidate!.isEmpty) return;
                await _handleCandidate(sig.candidate!);
              }
            }
          }
        });
  }

  /* ---------- HANDLERS ---------- */
  Future<void> handleOffer(String sdp, String callerId) async {
    await openUserMedia();

    _peer = await _createPeer(callerId);

    // 🔧 decodificar SDP antes de aplicar
    final sdpMap = jsonDecode(sdp);
    await _peer!.setRemoteDescription(
      RTCSessionDescription(sdpMap['sdp'], sdpMap['type']),
    );

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
    _lastRoomId = roomId;

    for (var ice in _pendingCandidates) {
      await _peer!.addCandidate(ice);
    }
    _pendingCandidates.clear();
  }

  Future<void> _handleAnswer(String sdp) async {
    if (sdp.isEmpty || !_peerReady) return;

    final sdpMap = jsonDecode(sdp);
    await _peer!.setRemoteDescription(
      RTCSessionDescription(sdpMap['sdp'], sdpMap['type']),
    );

    for (var ice in _pendingCandidates) {
      await _peer!.addCandidate(ice);
    }
    _pendingCandidates.clear();
  }

  Future<void> _handleCandidate(String candidate) async {
    final map = jsonDecode(candidate);
    final ice = RTCIceCandidate(
      map['candidate'],
      map['sdpMid'] ?? '',
      map['sdpMLineIndex'] ?? 0,
    );

    if (_peer != null &&
        _peerReady &&
        (await _peer!.getRemoteDescription()) != null) {
      await _peer!.addCandidate(ice);
    } else {
      debugPrint('⏳ Candidate en espera...');
      _pendingCandidates.add(ice);
    }
  }

  /* ---------- PEER CONFIG ---------- */
  Future<RTCPeerConnection> _createPeer(String oppositeId) async {
    final peer = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': 'turn:openrelay.metered.ca:80',
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
      ],
    });

    peer.onIceCandidate = (candidate) {
      final signal = CallSignal(
        type: 'candidate',
        candidate: jsonEncode(candidate.toMap()),
        callerId: currentUid,
        calleeId: oppositeId,
      );
      final roomId = _roomId(currentUid, oppositeId);
      _db
          .collection('calls')
          .doc(roomId)
          .collection('signals')
          .add(signal.toMap());
    };

    // 🔧 usar el uiUpdate correcto
    peer.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        debugPrint('📡 Track remoto recibido: ${event.track.kind}');
        Future.microtask(() {
          remoteRenderer.srcObject = event.streams[0];
          uiUpdate.value = !uiUpdate.value;
        });
      }
    };

    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        peer.addTrack(track, _localStream!);
      });
    }

    _peer = peer;
    _peerReady = true;
    return peer;
  }

  String _roomId(String a, String b) {
    final list = [a, b]..sort();
    return list.join('_');
  }

  Future<void> dispose() async {
  await hangUp();
  localRenderer.dispose();
  remoteRenderer.dispose();
}
}
