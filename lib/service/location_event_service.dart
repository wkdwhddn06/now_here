import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../data/location_event.dart';
import 'location_service.dart';
import 'user_service.dart';

class LocationEventService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://nowhere-8985a-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  
  // 초기 위치 이벤트 데이터 로딩 (스트림 구독 전 한 번 실행)
  Future<List<LocationEvent>> getInitialLocationEvents({
    Position? position,
    double radiusKm = 3.0,
  }) async {
    try {
      print('=== 초기 위치 이벤트 데이터 로딩 시작 ===');
      print('전달받은 position: $position');
      print('검색 반경: ${radiusKm}km');
      
      final currentPosition = position ?? await _locationService.getCurrentLocation();
      if (currentPosition == null) {
        print('❌ 현재 위치를 가져올 수 없어 빈 리스트 반환');
        return [];
      }
      
      print('✅ 현재 위치: ${currentPosition.latitude}, ${currentPosition.longitude}');
      
      final snapshot = await _database
          .ref()
          .child('location_events')
          .orderByChild('isActive')
          .equalTo(true)
          .get();

      print('Firebase 데이터 존재 여부: ${snapshot.exists}');
      
      if (!snapshot.exists) {
        print('❌ 활성 이벤트가 없음');
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      print('Firebase에서 가져온 데이터 수: ${data.length}');
      
      final allEvents = data.entries
          .map((entry) => LocationEvent.fromJson(
                Map<String, dynamic>.from(entry.value as Map),
              ))
          .where((event) => !event.isExpired)
          .toList();

      print('만료되지 않은 이벤트 수: ${allEvents.length}');

      // 거리 기반 필터링
      final nearbyEvents = <LocationEvent>[];
      for (final event in allEvents) {
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          event.latitude,
          event.longitude,
        );
        
        print('이벤트 "${event.title}" 거리: ${(distance / 1000).toStringAsFixed(2)}km');
        
        if (distance <= radiusKm * 1000) { // km를 m로 변환
          nearbyEvents.add(event);
        }
      }

      // 생성 시간 기준으로 정렬 (최신순)
      nearbyEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ 초기 근처 이벤트 로딩 완료: ${nearbyEvents.length}개');
      return nearbyEvents;
    } catch (e) {
      print('❌ 초기 위치 이벤트 로딩 실패: $e');
      return [];
    }
  }
  
  // 실시간 이벤트 목록을 위한 스트림
  Stream<List<LocationEvent>> get eventsStream {
    return _database
        .ref()
        .child('location_events')
        .orderByChild('isActive')
        .equalTo(true)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <LocationEvent>[];
      
      return data.entries
          .map((entry) => LocationEvent.fromJson(
                Map<String, dynamic>.from(entry.value as Map),
              ))
          .where((event) => !event.isExpired)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    });
  }

     // 근처 이벤트만 가져오기 (반경 내)
  Future<List<LocationEvent>> getNearbyEvents({
    Position? position,
    double radiusKm = 2.0,
  }) async {
    try {
      final currentPosition = position ?? await _locationService.getCurrentLocation();
      if (currentPosition == null) return [];
      
      final snapshot = await _database
          .ref()
          .child('location_events')
          .orderByChild('isActive')
          .equalTo(true)
          .get();

      if (!snapshot.exists) return [];

      final data = snapshot.value as Map<dynamic, dynamic>;
      final allEvents = data.entries
          .map((entry) => LocationEvent.fromJson(
                Map<String, dynamic>.from(entry.value as Map),
              ))
          .where((event) => !event.isExpired)
          .toList();

      // 거리 기반 필터링
      final nearbyEvents = <LocationEvent>[];
      for (final event in allEvents) {
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          event.latitude,
          event.longitude,
        );
        
        if (distance <= radiusKm * 1000) { // km를 m로 변환
          nearbyEvents.add(event);
        }
      }

      // 생성 시간 기준으로 정렬 (최신순)
      nearbyEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return nearbyEvents;
    } catch (e) {
      print('근처 이벤트 로드 실패: $e');
      return [];
    }
  }

  // 새 이벤트 생성
  Future<String?> createEvent({
    required String title,
    required String description,
    required EventType type,
    required Position position,
    required String locationName,
    required int maxParticipants,
    required Duration duration,
  }) async {
    try {
      final eventId = _database.ref().child('location_events').push().key;
      if (eventId == null) return null;

      // 전역 사용자 정보 사용
      final currentUser = _userService.currentUser;
      final creatorId = currentUser.id;
      final creatorName = currentUser.name;
      
      print('이벤트 생성: $title, 생성자: $creatorName ($creatorId)');
      
      final event = LocationEvent(
        id: eventId,
        title: title,
        description: description,
        type: type,
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: locationName,
        creatorId: creatorId,
        creatorName: creatorName,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(duration),
        maxParticipants: maxParticipants,
        participantIds: [creatorId], // 생성자는 자동 참여
        isActive: true,
      );

      await _database.ref().child('location_events').child(eventId).set(event.toJson());
      return eventId;
    } catch (e) {
      print('이벤트 생성 실패: $e');
      return null;
    }
  }

  // 이벤트 참여
  Future<bool> joinEvent(String eventId, String userId, String userName) async {
    try {
      final eventRef = _database.ref().child('location_events').child(eventId);
      final snapshot = await eventRef.get();
      
      if (!snapshot.exists) return false;
      
      final event = LocationEvent.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
      
      // 이미 참여했거나 만료되었거나 가득 찬 경우
      if (event.participantIds.contains(userId) || 
          event.isExpired || 
          event.isFull) {
        return false;
      }
      
      final updatedParticipants = [...event.participantIds, userId];
      await eventRef.child('participantIds').set(updatedParticipants);
      
      return true;
    } catch (e) {
      print('이벤트 참여 실패: $e');
      return false;
    }
  }

  // 이벤트 떠나기
  Future<bool> leaveEvent(String eventId, String userId) async {
    try {
      final eventRef = _database.ref().child('location_events').child(eventId);
      final snapshot = await eventRef.get();
      
      if (!snapshot.exists) return false;
      
      final event = LocationEvent.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
      
      // 생성자는 떠날 수 없음 (이벤트 삭제해야 함)
      if (event.creatorId == userId) return false;
      
      final updatedParticipants = event.participantIds
          .where((id) => id != userId)
          .toList();
      
      await eventRef.child('participantIds').set(updatedParticipants);
      
      return true;
    } catch (e) {
      print('이벤트 떠나기 실패: $e');
      return false;
    }
  }

  // 이벤트 삭제 (생성자만 가능)
  Future<bool> deleteEvent(String eventId, String userId) async {
    try {
      final eventRef = _database.ref().child('location_events').child(eventId);
      final snapshot = await eventRef.get();
      
      if (!snapshot.exists) return false;
      
      final event = LocationEvent.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
      
      // 생성자만 삭제 가능
      if (event.creatorId != userId) return false;
      
      await eventRef.child('isActive').set(false);
      return true;
    } catch (e) {
      print('이벤트 삭제 실패: $e');
      return false;
    }
  }

  // 사용자가 이벤트에 참여했는지 확인
  Future<bool> isUserParticipating(String eventId, String userId) async {
    try {
      final eventRef = _database.ref().child('location_events').child(eventId);
      final snapshot = await eventRef.get();
      
      if (!snapshot.exists) return false;
      
      final event = LocationEvent.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
      
      return event.participantIds.contains(userId);
    } catch (e) {
      print('참여 여부 확인 실패: $e');
      return false;
    }
  }

  // 거리 계산 헬퍼 메서드
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // 거리를 한국어 텍스트로 변환
  String getDistanceText(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toInt()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  // 만료된 이벤트 정리 (백그라운드 작업)
  Future<void> cleanupExpiredEvents() async {
    try {
      final snapshot = await _database
          .ref()
          .child('location_events')
          .orderByChild('isActive')
          .equalTo(true)
          .get();

      if (!snapshot.exists) return;

      final data = snapshot.value as Map<dynamic, dynamic>;
      final now = DateTime.now();
      
      for (final entry in data.entries) {
        final event = LocationEvent.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        
        if (event.isExpired) {
          await _database
              .ref()
              .child('location_events')
              .child(event.id)
              .child('isActive')
              .set(false);
        }
      }
    } catch (e) {
      print('만료된 이벤트 정리 실패: $e');
    }
  }
} 