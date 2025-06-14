import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/chat_message_realtime.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _userKey = 'current_user';
  
  AnonymousUser? _currentUser;
  
  // 현재 사용자 getter
  AnonymousUser get currentUser {
    if (_currentUser == null) {
      throw Exception('사용자가 초기화되지 않았습니다. initializeUser()를 먼저 호출하세요.');
    }
    return _currentUser!;
  }

  // 사용자가 초기화되었는지 확인
  bool get isInitialized => _currentUser != null;

  // 앱 시작 시 사용자 초기화 (기존 사용자 로드 또는 새로 생성)
  Future<void> initializeUser() async {
    try {
      print('=== 사용자 초기화 시작 ===');
      
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        // 기존 사용자 로드
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = AnonymousUser.fromMap(userData);
        print('✅ 기존 사용자 로드 완료: ${_currentUser!.name} (ID: ${_currentUser!.id})');
      } else {
        // 새 사용자 생성
        await _createNewUser();
      }
    } catch (e) {
      print('⚠️ 사용자 로드 실패, 새 사용자 생성: $e');
      await _createNewUser();
    }
  }

  // 새로운 사용자 생성 및 저장
  Future<void> _createNewUser() async {
    try {
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = AnonymousUser.generate(userId);
      
      await _saveCurrentUser();
      print('✅ 새 사용자 생성 완료: ${_currentUser!.name} (ID: ${_currentUser!.id})');
    } catch (e) {
      print('❌ 새 사용자 생성 실패: $e');
      // 최소한의 사용자라도 생성
      _currentUser = AnonymousUser.generate();
    }
  }

  // 현재 사용자를 SharedPreferences에 저장
  Future<void> _saveCurrentUser() async {
    if (_currentUser == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(_currentUser!.toMap());
      await prefs.setString(_userKey, userJson);
      print('💾 사용자 정보 저장 완료');
    } catch (e) {
      print('❌ 사용자 정보 저장 실패: $e');
    }
  }

  // 사용자 정보 업데이트 (필요한 경우)
  Future<void> updateUser(AnonymousUser updatedUser) async {
    _currentUser = updatedUser;
    await _saveCurrentUser();
  }

  // 사용자 재생성 (닉네임 변경 등)
  Future<void> regenerateUser() async {
    await _createNewUser();
  }

  // 사용자 데이터 초기화 (로그아웃 개념)
  Future<void> clearUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _currentUser = null;
      print('🗑️ 사용자 데이터 초기화 완료');
    } catch (e) {
      print('❌ 사용자 데이터 초기화 실패: $e');
    }
  }

  // 디버깅용 사용자 정보 출력
  void printUserInfo() {
    if (_currentUser != null) {
      print('👤 현재 사용자: ${_currentUser!.name}');
      print('🆔 ID: ${_currentUser!.id}');
      print('🎨 색상: ${_currentUser!.primaryColor}');
      print('🎭 성격: ${_currentUser!.personality}');
      print('📅 생성일: ${_currentUser!.createdAt}');
    } else {
      print('❌ 사용자가 초기화되지 않음');
    }
  }
} 