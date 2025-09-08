import 'package:cloud_firestore/cloud_firestore.dart';

class CallSignal {
  final String type;   // offer | answer | candidate
  final String? sdp;   // solo offer/answer
  final String? candidate; // solo candidate
  final String callerId;
  final String calleeId;

  CallSignal({
    required this.type,
    this.sdp,
    this.candidate,
    required this.callerId,
    required this.calleeId,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'sdp': sdp,
        'candidate': candidate,
        'callerId': callerId,
        'calleeId': calleeId,
        'timestamp': FieldValue.serverTimestamp(),
      };

  factory CallSignal.fromMap(Map<String, dynamic> map) => CallSignal(
        type: map['type'],
        sdp: map['sdp'],
        candidate: map['candidate'],
        callerId: map['callerId'],
        calleeId: map['calleeId'],
      );
}