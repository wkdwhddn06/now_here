class ChatEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final String storeName;
  final String meetingTime;
  final String meetingPlace;
  final int maxParticipants;
  final List<String> participants;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final DateTime expiredAt;
  final String status; // 'active', 'full', 'expired', 'cancelled'
  final String eventType; // 'meal', 'coffee', 'shopping', 'activity'
  final String? specialNote;

  ChatEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.storeName,
    required this.meetingTime,
    required this.meetingPlace,
    required this.maxParticipants,
    required this.participants,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.expiredAt,
    required this.status,
    required this.eventType,
    this.specialNote,
  });

  factory ChatEvent.fromMap(Map<String, dynamic> map) {
    return ChatEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      storeName: map['storeName'] ?? '',
      meetingTime: map['meetingTime'] ?? '',
      meetingPlace: map['meetingPlace'] ?? '',
      maxParticipants: map['maxParticipants'] ?? 4,
      participants: List<String>.from(map['participants'] ?? []),
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      expiredAt: DateTime.fromMillisecondsSinceEpoch(map['expiredAt'] ?? 0),
      status: map['status'] ?? 'active',
      eventType: map['eventType'] ?? 'meal',
      specialNote: map['specialNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'storeName': storeName,
      'meetingTime': meetingTime,
      'meetingPlace': meetingPlace,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiredAt': expiredAt.millisecondsSinceEpoch,
      'status': status,
      'eventType': eventType,
      'specialNote': specialNote,
    };
  }

  // 참여 가능한지 확인
  bool get canJoin => status == 'active' && participants.length < maxParticipants && !isExpired;
  
  // 만료되었는지 확인
  bool get isExpired => DateTime.now().isAfter(expiredAt);
  
  // 참여자 수 표시
  String get participantCount => '${participants.length}/$maxParticipants명';
  
  // 남은 시간 계산
  String get timeUntilExpiry {
    final now = DateTime.now();
    if (isExpired) return '마감됨';
    
    final diff = expiredAt.difference(now);
    if (diff.inHours > 0) {
      return '${diff.inHours}시간 ${diff.inMinutes % 60}분 후 마감';
    } else {
      return '${diff.inMinutes}분 후 마감';
    }
  }
} 