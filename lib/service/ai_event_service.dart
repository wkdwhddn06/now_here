import 'dart:convert';
import 'dart:math';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../data/location_event.dart';
import '../service/ai_banner_service.dart';
import '../service/location_event_service.dart';
import '../service/location_service.dart';

class AiEventService {
  static final AiEventService _instance = AiEventService._internal();
  factory AiEventService() => _instance;
  AiEventService._internal();

  late final GenerativeModel _model;
  final LocationEventService _locationEventService = LocationEventService();
  final LocationService _locationService = LocationService();
  
  void initialize() {
    try {
      _model = FirebaseAI.vertexAI().generativeModel(model: 'gemini-2.0-flash');
      print('AI 이벤트 서비스 초기화 완료');
    } catch (e) {
      print('AI 이벤트 서비스 초기화 실패: $e');
    }
  }

  Future<String?> generateLocationEventFromBanner(
    BannerAd banner, 
    String userId, 
    String userName,
  ) async {
    try {
      // 현재 위치 가져오기
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        print('위치 정보를 가져올 수 없습니다');
        return null;
      }

      final prompt = '''
다음 배너 광고 정보를 바탕으로 사람들이 같이 참여할 수 있는 매력적인 이벤트를 생성해 주세요.

배너 정보:
- 가게명: ${banner.storeName}
- 제목: ${banner.title}
- 할인: ${banner.discount}
- 위치: ${banner.locationName}
- 카테고리: ${banner.category}
- 사장님 메시지: ${banner.ownerMessage}

실제 사람들이 참여하고 싶어할 만한 구체적이고 재미있는 이벤트를 만들어 주세요.

반드시 아래 JSON 형식만으로 응답해 주세요:
{
  "title": "이벤트 제목 (20자 이내)",
  "description": "상세 설명 (80자 이내)",
  "eventType": "이벤트타입",
  "maxParticipants": 참여자수(2-6명),
  "durationHours": 지속시간(1-4시간)
}

이벤트타입: food(맛집), coffee(카페), shopping(쇼핑), chat(수다), study(공부), walk(산책), help(도움)

실제 예시:
- 제목: "정미네 손만두 런치 모임", "치킨파티 같이해요!", "카페에서 수다떨어요"
- 설명: "맛있는 손만두 먹으면서 새친구 만들어요! 런치특가 6,500원 혜택도 받고 일석이조"
- 이벤트타입: food, coffee, shopping, chat 등
- 참여자수: 2-6명 사이
- 지속시간: 1-4시간

JSON만 출력하세요.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        print('AI 이벤트 응답: ${response.text}');
        
        final jsonText = _extractJsonFromResponse(response.text!);
        final Map<String, dynamic> data = json.decode(jsonText);
        
        // EventType 매핑
        final eventTypeString = data['eventType']?.toString() ?? 'chat';
        final eventType = _mapStringToEventType(eventTypeString);
        
        // LocationEvent 생성
        final eventId = await _locationEventService.createEvent(
          title: data['title']?.toString() ?? '${banner.storeName} 모임',
          description: data['description']?.toString() ?? '${banner.storeName}에서 같이 시간을 보내요!',
          type: eventType,
          position: position,
          locationName: banner.locationName,
          maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 4,
          duration: Duration(hours: (data['durationHours'] as num?)?.toInt() ?? 2),
        );
        
        return eventId;
      }
    } catch (e) {
      print('AI 이벤트 생성 실패: $e');
    }
    
    // AI 실패시 기본 이벤트 생성
    return _generateDefaultLocationEvent(banner, userId, userName);
  }

  String _extractJsonFromResponse(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        return response.substring(jsonStart, jsonEnd + 1);
      }
      
      throw Exception('JSON 형식을 찾을 수 없습니다');
    } catch (e) {
      print('JSON 추출 실패: $e');
      throw Exception('JSON 파싱 실패: $e');
    }
  }

  EventType _mapStringToEventType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'food':
        return EventType.food;
      case 'coffee':
        return EventType.coffee;
      case 'shopping':
        return EventType.shopping;
      case 'study':
        return EventType.study;
      case 'walk':
        return EventType.walk;
      case 'help':
        return EventType.help;
      case 'chat':
      default:
        return EventType.chat;
    }
  }

  EventType _getEventTypeFromCategory(String category) {
    switch (category) {
      case '맛집':
      case '치킨집':
        return EventType.food;
      case '카페':
        return EventType.coffee;
      case '쇼핑':
        return EventType.shopping;
      default:
        return EventType.chat;
    }
  }

  Future<String?> _generateDefaultLocationEvent(
    BannerAd banner, 
    String userId, 
    String userName,
  ) async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return null;

      final random = Random();
      final eventTemplates = [
        {
          'title': '${banner.storeName} 같이 가요!',
          'description': '${banner.discount} 혜택 받으면서 맛있게 먹어요! 새로운 친구들과 즐거운 시간을 보내요',
          'type': _getEventTypeFromCategory(banner.category),
          'maxParticipants': 4,
          'duration': 2,
        },
        {
          'title': '${banner.title} 함께해요',
          'description': '${banner.storeName}에서 좋은 시간 보내실 분들 모여요! ${banner.ownerMessage}',
          'type': _getEventTypeFromCategory(banner.category),
          'maxParticipants': 3,
          'duration': 2,
        },
      ];
      
      final template = eventTemplates[random.nextInt(eventTemplates.length)];
      
      return await _locationEventService.createEvent(
        title: template['title']! as String,
        description: template['description']! as String,
        type: template['type']! as EventType,
        position: position,
        locationName: banner.locationName,
        maxParticipants: template['maxParticipants']! as int,
        duration: Duration(hours: template['duration']! as int),
      );
    } catch (e) {
      print('기본 LocationEvent 생성 실패: $e');
      return null;
    }
  }

  // 비속어 감지 기능
  Future<bool> checkForProfanity(String message) async {
    try {
      final prompt = '''
다음 메시지에 비속어, 욕설, 혐오 표현, 성적인 내용, 폭력적인 내용이 포함되어 있는지 분석해 주세요.

메시지: "$message"

분석 기준:
1. 한국어 비속어 및 욕설
2. 영어 비속어 및 욕설
3. 성적인 내용
4. 혐오 표현 (인종, 성별, 종교 등)
5. 폭력적인 내용
6. 괴롭힘이나 따돌림 관련 내용

반드시 아래 JSON 형식만으로 응답해 주세요:
{
  "hasProfanity": true/false,
  "reason": "감지된 이유 (한국어)"
}

예시:
- 일반적인 인사나 대화: {"hasProfanity": false, "reason": "적절한 내용"}
- 비속어 포함: {"hasProfanity": true, "reason": "비속어 감지"}
- 혐오 표현: {"hasProfanity": true, "reason": "혐오 표현 감지"}

JSON만 출력하세요.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        final jsonText = _extractJsonFromResponse(response.text!);
        final Map<String, dynamic> data = json.decode(jsonText);
        
        final hasProfanity = data['hasProfanity'] ?? false;
        if (hasProfanity) {
          print('비속어 감지됨: ${data['reason']}');
        }
        
        return hasProfanity;
      }
    } catch (e) {
      print('비속어 감지 실패: $e');
      // AI 검사 실패시 안전하게 통과시킴
      return false;
    }
    
    return false;
  }
} 