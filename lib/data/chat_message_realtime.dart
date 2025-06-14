import 'dart:math';
import 'package:flutter/material.dart';

class ChatMessageRealtime {
  final String id;
  final String userId;
  final String message;
  final int timestamp;
  final String? userName;

  ChatMessageRealtime({
    required this.id,
    required this.userId,
    required this.message,
    required this.timestamp,
    this.userName,
  });

  // Realtime Database에서 받은 데이터를 객체로 변환
  factory ChatMessageRealtime.fromMap(String key, Map<dynamic, dynamic> data) {
    return ChatMessageRealtime(
      id: key,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? 0,
      userName: data['userName'],
    );
  }

  // 객체를 Realtime Database용 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'timestamp': timestamp,
      'userName': userName,
    };
  }

  // 시간 정렬을 위한 compareTo
  int compareTo(ChatMessageRealtime other) {
    return timestamp.compareTo(other.timestamp);
  }

  // DateTime으로 변환
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

// 🌟 획기적으로 개선된 익명 사용자 시스템
class AnonymousUser {
  final String id;
  final String name;
  final DateTime createdAt;
  final Color primaryColor;
  final Color secondaryColor;
  final String avatar;
  final String personality;
  
  // 캐싱을 위한 static 변수들
  static final Map<String, AnonymousUser> _userCache = {};

  AnonymousUser({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.primaryColor,
    required this.secondaryColor,
    required this.avatar,
    required this.personality,
  });

  // 🎨 핵심 팩토리 메서드 - 사용자 ID 기반으로 일관된 정체성 생성
  factory AnonymousUser.generate([String? userId]) {
    final actualUserId = userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    // 캐시에서 확인
    if (_userCache.containsKey(actualUserId)) {
      return _userCache[actualUserId]!;
    }
    
    final random = Random(actualUserId.hashCode);
    final now = DateTime.now();
    
    // 🎭 감정 형용사들
    final emotions = [
      '행복한', '신나는', '차분한', '다정한', '용감한', '똑똑한', '귀여운', '멋진',
      '활발한', '따뜻한', '시원한', '반짝이는', '신비로운', '유쾌한', '온화한', '빠른'
    ];
    
    // 🐾 동물 & 존재들
    final creatures = [
      '고양이', '강아지', '판다', '여우', '코알라', '펭귄',
      '오리', '토끼', '햄스터', '다람쥐', '고슴도치', '개구리',
      '거북이', '나비', '꿀벌', '고래', '문어', '별',
      '달', '태양', '무지개', '불꽃', '다이아몬드', '벚꽃'
    ];
    
    // 🎨 아름다운 단색 팔레트
    final colors = [
      const Color(0xFF6B73FF), // 블루
      const Color(0xFFFF6B9D), // 핑크
      const Color(0xFF9B59B6), // 퍼플
      const Color(0xFF1ABC9C), // 터콰이즈
      const Color(0xFFE67E22), // 오렌지
      const Color(0xFF2ECC71), // 그린
      const Color(0xFFE74C3C), // 레드
      const Color(0xFFF39C12), // 골드
      const Color(0xFF3498DB), // 스카이 블루
      const Color(0xFFAB47BC), // 마젠타
    ];
    
    // 🎪 성격 특성들
    final personalities = [
      '모험가', '꿈꾸는 자', '탐험가', '예술가', '철학자', '코미디언', '수호자', '치유사',
      '발명가', '음유시인', '마법사', '기사', '현자', '무도가', '요정', '용사'
    ];
    
    final emotion = emotions[random.nextInt(emotions.length)];
    final creature = creatures[random.nextInt(creatures.length)];
    final selectedColor = colors[random.nextInt(colors.length)];
    final personality = personalities[random.nextInt(personalities.length)];
    
    final generatedName = '$emotion $creature';
    
    final user = AnonymousUser(
      id: actualUserId,
      name: generatedName,
      createdAt: now,
      primaryColor: selectedColor,
      secondaryColor: selectedColor, // 단색으로 통일
      avatar: creature,
      personality: personality,
    );
    
    // 캐시에 저장
    _userCache[actualUserId] = user;
    return user;
  }

  // 🎨 특별 테마 생성
  factory AnonymousUser.withTheme(String theme, [String? userId]) {
    // 추후 테마별 특별 닉네임 구현 예정
    return AnonymousUser.generate(userId);
  }

  // 🎭 감정 상태 반영
  factory AnonymousUser.withMood(String mood, [String? userId]) {
    // 추후 감정별 특별 닉네임 구현 예정
    return AnonymousUser.generate(userId);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'avatar': avatar,
      'personality': personality,
    };
  }

  factory AnonymousUser.fromMap(Map<String, dynamic> data) {
    return AnonymousUser(
      id: data['id'] ?? '',
      name: data['name'] ?? '익명',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      primaryColor: Color(data['primaryColor'] ?? 0xFF6B73FF),
      secondaryColor: Color(data['secondaryColor'] ?? 0xFF000DFF),
      avatar: data['avatar'] ?? '⭐ 별',
      personality: data['personality'] ?? '모험가',
    );
  }
} 