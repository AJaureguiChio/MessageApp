// models/call_signal.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CallSignal {
  final String type;
  final String? sdp;
  final String? candidate;
  final String callerId;
  final String calleeId;
  final Timestamp timestamp;

  CallSignal({
    required this.type,
    this.sdp,
    this.candidate,
    required this.callerId,
    required this.calleeId,
    Timestamp? timestamp,
  }) : timestamp = timestamp ?? Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'sdp': sdp,
      'candidate': candidate,
      'callerId': callerId,
      'calleeId': calleeId,
      'timestamp': timestamp,
    };
  }

  factory CallSignal.fromMap(Map<String, dynamic> map) {
    return CallSignal(
      type: map['type'],
      sdp: map['sdp'],
      candidate: map['candidate'],
      callerId: map['callerId'],
      calleeId: map['calleeId'],
      timestamp: map['timestamp'],
    );
  }

  String? get sdpString => sdp;
}