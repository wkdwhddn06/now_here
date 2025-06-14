import 'dart:convert';
import 'dart:math';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import '../data/chat_event.dart';
import '../service/ai_banner_service.dart';

class AiEventService {
  static final AiEventService _instance = AiEventService._internal();
  factory AiEventService() => _instance;
  AiEventService._internal();

  late final GenerativeModel _model;
  
  void initialize() {
    try {
      _model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');
      print('AI 이벤트 서비스 초기화 완료');
    } catch (e) {
      print('AI 이벤트 서비스 초기화 실패: $e');
    }
  }

  Future<ChatEvent?> generateEventFromBanner(
    BannerAd banner, 
    String userId, 
    String userName, 
    String chatRoomId,
  ) async {
    try {
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
  "description": "상세 설명 (60자 이내)",
  "meetingTime": "만날 시간 (예: 오늘 오후 7시, 내일 점심)",
  "meetingPlace": "만날 장소 (25자 이내)",
  "maxParticipants": 참여자수(2-6명),
  "eventType": "이벤트타입",
  "specialNote": "특별 안내사항 (40자 이내)"
}

이벤트타입: meal(식사), coffee(카페), shopping(쇼핑), activity(활동)

실제 예시:
- 제목: "정미네 손만두 런치 모임", "치킨파티 같이해요!", "카페에서 수다떨어요"
- 설명: "맛있는 손만두 먹으면서 새친구 만들어요", "바삭한 치킨과 시원한 맥주 한잔!"
- 만날시간: "오늘 오후 7시", "내일 점심 12시", "주말 오후 3시"
- 만날장소: "가게 앞에서 만나요", "지하철 2번 출구", "카페 1층 입구"
- 특별안내: "더치페이로 진행해요", "미리 예약해놨어요", "배가 고픈 상태로 오세요"

JSON만 출력하세요.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        print('AI 이벤트 응답: ${response.text}');
        
        final jsonText = _extractJsonFromResponse(response.text!);
        final Map<String, dynamic> data = json.decode(jsonText);
        
        // 이벤트 ID 생성
        final eventId = '${chatRoomId}_${DateTime.now().millisecondsSinceEpoch}';
        
        // 만료 시간 설정 (2시간 후)
        final expiredAt = DateTime.now().add(const Duration(hours: 2));
        
        return ChatEvent(
          id: eventId,
          title: data['title']?.toString() ?? '${banner.storeName} 모임',
          description: data['description']?.toString() ?? '같이 가서 맛있게 먹어요!',
          location: banner.locationName,
          storeName: banner.storeName,
          meetingTime: data['meetingTime']?.toString() ?? '오늘 저녁 7시',
          meetingPlace: data['meetingPlace']?.toString() ?? '가게 앞에서 만나요',
          maxParticipants: (data['maxParticipants'] as num?)?.toInt() ?? 4,
          participants: [userId], // 생성자가 첫 번째 참여자
          creatorId: userId,
          creatorName: userName,
          createdAt: DateTime.now(),
          expiredAt: expiredAt,
          status: 'active',
          eventType: data['eventType']?.toString() ?? _getEventTypeFromCategory(banner.category),
          specialNote: data['specialNote']?.toString(),
        );
      }
    } catch (e) {
      print('AI 이벤트 생성 실패: $e');
    }
    
    // AI 실패시 기본 이벤트 생성
    return _generateDefaultEvent(banner, userId, userName, chatRoomId);
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

  String _getEventTypeFromCategory(String category) {
    switch (category) {
      case '맛집':
      case '치킨집':
        return 'meal';
      case '카페':
        return 'coffee';
      case '쇼핑':
        return 'shopping';
      default:
        return 'activity';
    }
  }

  ChatEvent _generateDefaultEvent(
    BannerAd banner, 
    String userId, 
    String userName, 
    String chatRoomId,
  ) {
    final random = Random();
    final eventTemplates = [
      {
        'title': '${banner.storeName} 같이 가요!',
        'description': '${banner.discount} 혜택 받으면서 맛있게 먹어요',
        'meetingTime': '오늘 저녁 7시',
        'meetingPlace': '가게 앞에서 만나요',
        'maxParticipants': 4,
        'specialNote': '더치페이로 진행해요!',
      },
      {
        'title': '${banner.title} 함께해요',
        'description': '새로운 친구들과 즐거운 시간을 보내요',
        'meetingTime': '내일 점심 12시',
        'meetingPlace': '지하철역에서 만나요',
        'maxParticipants': 3,
        'specialNote': '미리 예약해놨어요!',
      },
    ];
    
    final template = eventTemplates[random.nextInt(eventTemplates.length)];
    final eventId = '${chatRoomId}_${DateTime.now().millisecondsSinceEpoch}';
    
    return ChatEvent(
      id: eventId,
      title: template['title']! as String,
      description: template['description']! as String,
      location: banner.locationName,
      storeName: banner.storeName,
      meetingTime: template['meetingTime']! as String,
      meetingPlace: template['meetingPlace']! as String,
      maxParticipants: template['maxParticipants']! as int,
      participants: [userId],
      creatorId: userId,
      creatorName: userName,
      createdAt: DateTime.now(),
      expiredAt: DateTime.now().add(const Duration(hours: 2)),
      status: 'active',
      eventType: _getEventTypeFromCategory(banner.category),
      specialNote: template['specialNote'] as String?,
    );
  }
} 