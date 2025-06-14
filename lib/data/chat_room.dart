import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String? id;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final int userCount;
  final DateTime lastMessageAt;
  final bool isEventRoom; // 이벤트 채팅방 여부

  ChatRoom({
    this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.userCount,
    required this.lastMessageAt,
    this.isEventRoom = false, // 기본값은 false (일반 채팅방)
  });

  // Firestore 문서에서 ChatRoom 객체로 변환
  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      locationName: data['locationName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userCount: data['userCount'] ?? 0,
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      isEventRoom: data['isEventRoom'] ?? false,
    );
  }

  // ChatRoom 객체를 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'userCount': userCount,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'isEventRoom': isEventRoom,
    };
  }

  // copyWith 메서드
  ChatRoom copyWith({
    String? id,
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    int? userCount,
    DateTime? lastMessageAt,
    bool? isEventRoom,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      userCount: userCount ?? this.userCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isEventRoom: isEventRoom ?? this.isEventRoom,
    );
  }
}

// 채팅 메시지 모델
class ChatMessage {
  final String? id;
  final String userId;
  final String message;
  final DateTime timestamp;
  final String? userName;

  ChatMessage({
    this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    this.userName,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id'],
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      userName: data['userName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'userName': userName,
    };
  }
} 