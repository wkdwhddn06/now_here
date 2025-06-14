enum EventType {
  study('study', '📚 같이 공부', '공부할 사람 구해요'),
  food('food', '🍽️ 맛집 탐방', '맛있는 걸 같이 먹어요'),
  help('help', '🆘 도움 요청', '도움이 필요해요'),
  chat('chat', '💬 수다 떨기', '그냥 이야기해요'),
  coffee('coffee', '☕ 카페 모임', '커피 마시며 수다'),
  walk('walk', '🚶‍♀️ 산책', '같이 걸을래요'),
  shopping('shopping', '🛍️ 쇼핑', '쇼핑 메이트 구함'),
  emergency('emergency', '🚨 긴급', '긴급 상황');

  const EventType(this.id, this.icon, this.description);
  final String id;
  final String icon;
  final String description;
}

class LocationEvent {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final double latitude;
  final double longitude;
  final String locationName;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int maxParticipants;
  final List<String> participantIds;
  final bool isActive;

  LocationEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.expiresAt,
    required this.maxParticipants,
    required this.participantIds,
    required this.isActive,
  });

  factory LocationEvent.fromJson(Map<String, dynamic> json) {
    return LocationEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.id == json['type'],
        orElse: () => EventType.chat,
      ),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      locationName: json['locationName'] ?? '',
      creatorId: json['creatorId'] ?? '',
      creatorName: json['creatorName'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] ?? 0),
      maxParticipants: json['maxParticipants'] ?? 5,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.id,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'maxParticipants': maxParticipants,
      'participantIds': participantIds,
      'isActive': isActive,
    };
  }

  LocationEvent copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    double? latitude,
    double? longitude,
    String? locationName,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? maxParticipants,
    List<String>? participantIds,
    bool? isActive,
  }) {
    return LocationEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantIds: participantIds ?? this.participantIds,
      isActive: isActive ?? this.isActive,
    );
  }

  // 편의 메서드들
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isFull => participantIds.length >= maxParticipants;
  int get availableSpots => maxParticipants - participantIds.length;
  
  String get timeLeftString {
    final now = DateTime.now();
    if (isExpired) return '종료됨';
    
    final difference = expiresAt.difference(now);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 남음';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 남음';
    } else {
      return '${difference.inDays}일 남음';
    }
  }
} 