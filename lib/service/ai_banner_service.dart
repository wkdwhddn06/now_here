import 'dart:convert';
import 'dart:math';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AiBannerService {
  static final AiBannerService _instance = AiBannerService._internal();
  factory AiBannerService() => _instance;
  AiBannerService._internal();

  late final GenerativeModel _model;
  
  void initialize() {
    try {
      // Firebase Vertex AI 모델 초기화
      _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.0-flash');
      print('AI 배너 서비스 초기화 완료');
    } catch (e) {
      print('AI 배너 서비스 초기화 실패: $e');
    }
  }

  Future<BannerAd?> generateLocationBanner(String locationName) async {
    try {
      // AI 프롬프트 생성 - 더 구체적이고 효과적인 프롬프트
      final prompt = '''
다음 위치 "${locationName}"에 실제로 있을 법한 가게의 매력적인 배너 광고를 JSON 형식으로 생성해 주세요.

실제 가게처럼 생생하게 만들어 주세요:
- 진짜 있을 법한 한국식 가게 이름
- 구체적인 할인가격이나 퍼센트
- 사장님이 직접 쓸 법한 친근한 멘트
- 실제 영업정보 (시간, 전화번호 뒷자리 등)

반드시 아래 JSON 형식만으로 응답해 주세요:
{
  "storeName": "실제 한국 가게 이름 (12자 이내)",
  "title": "눈에 띄는 광고 제목 (18자 이내)",
  "subtitle": "구체적인 할인혜택 (30자 이내)",
  "description": "사장님 멘트나 가게 소개 (45자 이내)",
  "category": "업종",
  "color": "#FF5722",  
  "icon": "restaurant",
  "callToAction": "실제 행동유도 (12자 이내)",
  "businessInfo": "영업시간이나 연락처 (25자 이내)",
  "discount": "할인 표시 (15자 이내)",
  "ownerMessage": "사장님 한마디 (35자 이내)"
}

업종: 맛집, 카페, 치킨집, 편의점, 미용실, 병원, 약국, 쇼핑, 관광, 숙박
색상: 업종에 맞는 hex 코드
아이콘: restaurant, local_cafe, local_hospital, shopping_bag, hotel, store, cut

실제 예시:
- 가게명: "정미네 손만두", "24시 훼미리마트", "오빠닭갈비 본점"
- 제목: "점심특가 6,500원!", "1+1 도시락 이벤트", "50% 할인 마지막 기회"
- 사장님멘트: "30년 전통 비법양념!", "학생할인 1000원 더!", "사장님이 직접 구워드려요"
- 할인: "런치 2,000원↓", "회원가 30%↓", "오늘만 반값!"

JSON만 출력하세요.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.isNotEmpty) {
        print('AI 응답: ${response.text}');
        
        // JSON 파싱
        final jsonText = _extractJsonFromResponse(response.text!);
        final Map<String, dynamic> data = json.decode(jsonText);
        
        return BannerAd(
          storeName: data['storeName']?.toString() ?? '${locationName} 맛집',
          title: data['title']?.toString() ?? '런치특가 6,500원!',
          subtitle: data['subtitle']?.toString() ?? '오늘만 특별할인 진행중',
          description: data['description']?.toString() ?? '사장님이 직접 만든 정성가득 요리',
          category: data['category']?.toString() ?? '맛집',
          color: data['color']?.toString() ?? '#FF5722',
          icon: data['icon']?.toString() ?? 'restaurant',
          callToAction: data['callToAction']?.toString() ?? '주문하기',
          businessInfo: data['businessInfo']?.toString() ?? '영업중 09:00-22:00',
          discount: data['discount']?.toString() ?? '런치 2,000원↓',
          ownerMessage: data['ownerMessage']?.toString() ?? '30년 전통 비법양념!',
          locationName: locationName,
        );
      }
    } catch (e) {
      print('AI 배너 생성 실패: $e');
    }
    
    // 실패 시 기본 배너 반환
    return _getDefaultBanner(locationName);
  }

  String _extractJsonFromResponse(String response) {
    try {
      // JSON 블록 찾기
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        return response.substring(jsonStart, jsonEnd + 1);
      }
      
      // 다른 패턴으로 시도
      final lines = response.split('\n');
      final jsonLines = <String>[];
      bool inJson = false;
      
      for (final line in lines) {
        if (line.trim().startsWith('{')) {
          inJson = true;
          jsonLines.add(line);
        } else if (inJson && line.trim().endsWith('}')) {
          jsonLines.add(line);
          break;
        } else if (inJson) {
          jsonLines.add(line);
        }
      }
      
      if (jsonLines.isNotEmpty) {
        return jsonLines.join('\n');
      }
      
      throw Exception('JSON 형식을 찾을 수 없습니다');
    } catch (e) {
      print('JSON 추출 실패: $e');
      throw Exception('JSON 파싱 실패: $e');
    }
  }

  BannerAd _getDefaultBanner(String locationName) {
    final random = Random();
    final bannerTemplates = [
      {
        'storeName': '${locationName} 맛집',
        'title': '런치특가 6,500원!',
        'subtitle': '오늘만 특별할인 진행중',
        'description': '사장님이 직접 만든 정성가득 한식',
        'category': '맛집',
        'color': '#FF5722',  
        'icon': 'restaurant',
        'callToAction': '주문하기',
        'businessInfo': '영업중 09:00-22:00',
        'discount': '런치 2,000원↓',
        'ownerMessage': '30년 전통 비법양념!'
      },
      {
        'storeName': '${locationName} 카페',
        'title': '아메리카노 1+1 이벤트',
        'subtitle': '친구와 함께 오면 한잔 더!',
        'description': '신선한 원두로 매일 직접 로스팅',
        'category': '카페',
        'color': '#8D6E63',
        'icon': 'local_cafe',
        'callToAction': '방문하기',
        'businessInfo': '영업중 07:00-23:00',
        'discount': '아메리카노 무료',
        'ownerMessage': '따뜻한 분위기에서 힐링하세요'
      },
      {
        'storeName': '${locationName} 치킨',
        'title': '후라이드+콜라 15,900원',
        'subtitle': '바삭바삭 갓 튀긴 치킨!',
        'description': '주문 즉시 튀겨드리는 신선한 치킨',
        'category': '치킨집',
        'color': '#FFA726',
        'icon': 'restaurant',
        'callToAction': '주문하기',
        'businessInfo': '배달 가능 17:00-01:00',
        'discount': '콜라 무료 증정',
        'ownerMessage': '치킨은 역시 갓 튀긴게 최고!'
      },
    ];
    
    final template = bannerTemplates[random.nextInt(bannerTemplates.length)];
    
    return BannerAd(
      storeName: template['storeName']!,
      title: template['title']!,
      subtitle: template['subtitle']!,
      description: template['description']!,
      category: template['category']!,
      color: template['color']!,
      icon: template['icon']!,
      callToAction: template['callToAction']!,
      businessInfo: template['businessInfo']!,
      discount: template['discount']!,
      ownerMessage: template['ownerMessage']!,
      locationName: locationName,
    );
  }

  // 여러 배너를 미리 생성하여 캐시
  Future<List<BannerAd>> generateMultipleBanners(String locationName, {int count = 2}) async {
    final List<BannerAd> banners = [];
    
    // AI 생성과 기본 배너를 조합
    try {
      final aiBanner = await generateLocationBanner(locationName);
      if (aiBanner != null) {
        banners.add(aiBanner);
      }
    } catch (e) {
      print('AI 배너 생성 중 오류: $e');
    }
    
    // 추가 배너가 필요한 경우 기본 템플릿 사용
    while (banners.length < count) {
      banners.add(_getDefaultBanner(locationName));
    }
    
    return banners;
  }
}

class BannerAd {
  final String storeName;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String color;
  final String icon;
  final String callToAction;
  final String businessInfo;
  final String discount;
  final String ownerMessage;
  final String locationName;
  final DateTime createdAt;

  BannerAd({
    required this.storeName,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.color,
    required this.icon,
    required this.callToAction,
    required this.businessInfo,
    required this.discount,
    required this.ownerMessage,
    required this.locationName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 색상 문자열을 Color 객체로 변환
  Color get backgroundColor {
    try {
      return Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF2196F3); // 기본값
    }
  }
} 