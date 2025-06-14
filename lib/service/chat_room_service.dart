import 'dart:math' as dart_math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../data/chat_room.dart';
import 'location_service.dart';

class ChatRoomService {
  static final ChatRoomService _instance = ChatRoomService._internal();
  factory ChatRoomService() => _instance;
  ChatRoomService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final String _collection = 'chatRooms';

  // 모든 채팅룸 가져오기
  Stream<List<ChatRoom>> getChatRoomsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromFirestore(doc))
            .toList());
  }

  // 모든 채팅룸 가져오기 (일회성)
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('lastMessageAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('채팅룸 조회 오류: $e');
      return [];
    }
  }

  // 현재 위치에서 가장 가까운 채팅룸 찾기
  Future<ChatRoom?> getNearestChatRoom() async {
    try {
      // 현재 위치 가져오기
      Position? currentPosition = await _locationService.getCurrentLocation();
      if (currentPosition == null) {
        print('현재 위치를 가져올 수 없습니다.');
        return null;
      }

      // 모든 채팅룸 가져오기
      List<ChatRoom> chatRooms = await getChatRooms();
      if (chatRooms.isEmpty) {
        return null;
      }

      // 거리 계산하여 가장 가까운 채팅룸 찾기
      ChatRoom? nearestRoom;
      double minDistance = double.infinity;

      for (ChatRoom room in chatRooms) {
        double distance = _locationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          room.latitude,
          room.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestRoom = room;
        }
      }

      return nearestRoom;
    } catch (e) {
      print('가장 가까운 채팅룸 찾기 오류: $e');
      return null;
    }
  }

  // 현재 위치에서 가장 가까운 채팅룸들 찾기 (개수 제한)
  Future<List<ChatRoom>> getNearestChatRooms({int limit = 3}) async {
    try {
      // 현재 위치 가져오기
      Position? currentPosition = await _locationService.getCurrentLocation();
      if (currentPosition == null) {
        print('현재 위치를 가져올 수 없습니다.');
        return [];
      }

      // 모든 채팅룸 가져오기
      List<ChatRoom> chatRooms = await getChatRooms();
      if (chatRooms.isEmpty) {
        return [];
      }

      // 거리와 함께 저장할 리스트
      List<Map<String, dynamic>> roomsWithDistance = [];

      for (ChatRoom room in chatRooms) {
        double distance = _locationService.calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          room.latitude,
          room.longitude,
        );

        roomsWithDistance.add({
          'room': room,
          'distance': distance,
        });
      }

      // 거리순으로 정렬
      roomsWithDistance.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double));

      // 지정된 개수만큼 반환
      return roomsWithDistance
          .take(limit)
          .map((item) => item['room'] as ChatRoom)
          .toList();
    } catch (e) {
      print('가장 가까운 채팅룸들 찾기 오류: $e');
      return [];
    }
  }

  // 현재 위치에서 가장 가까운 채팅룸들 찾기 (위치 파라미터로 받음)
  Future<List<ChatRoom>> getNearestChatRoomsWithPosition({
    required Position position,
    int limit = 3,
  }) async {
    try {
      // 모든 채팅룸 가져오기
      List<ChatRoom> chatRooms = await getChatRooms();
      if (chatRooms.isEmpty) {
        return [];
      }

      // 거리와 함께 저장할 리스트
      List<Map<String, dynamic>> roomsWithDistance = [];

      for (ChatRoom room in chatRooms) {
        double distance = _locationService.calculateDistance(
          position.latitude,
          position.longitude,
          room.latitude,
          room.longitude,
        );

        roomsWithDistance.add({
          'room': room,
          'distance': distance,
        });
      }

      // 거리순으로 정렬
      roomsWithDistance.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double));

      // 지정된 개수만큼 반환
      return roomsWithDistance
          .take(limit)
          .map((item) => item['room'] as ChatRoom)
          .toList();
    } catch (e) {
      print('가장 가까운 채팅룸들 찾기 오류: $e');
      return [];
    }
  }

  // 현재 위치에서 가장 가까운 채팅룸 스트림
  Stream<ChatRoom?> getNearestChatRoomStream() async* {
    try {
      // 현재 위치 가져오기
      Position? currentPosition = await _locationService.getCurrentLocation();
      if (currentPosition == null) {
        yield null;
        return;
      }

      // 채팅룸 스트림 구독
      await for (List<ChatRoom> chatRooms in getChatRoomsStream()) {
        if (chatRooms.isEmpty) {
          yield null;
          continue;
        }

        // 거리 계산하여 가장 가까운 채팅룸 찾기
        ChatRoom? nearestRoom;
        double minDistance = double.infinity;

        for (ChatRoom room in chatRooms) {
          double distance = _locationService.calculateDistance(
            currentPosition.latitude,
            currentPosition.longitude,
            room.latitude,
            room.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestRoom = room;
          }
        }

        yield nearestRoom;
      }
    } catch (e) {
      print('가장 가까운 채팅룸 스트림 오류: $e');
      yield null;
    }
  }

  // 위치 기반으로 채팅룸 가져오기
  Future<List<ChatRoom>> getChatRoomsByLocation({
    required double latitude,
    required double longitude,
    double radius = 1000, // 미터 단위
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .get();
      
      final chatRooms = snapshot.docs
          .map((doc) => ChatRoom.fromFirestore(doc))
          .where((room) {
            final distance = _locationService.calculateDistance(
              latitude, longitude, 
              room.latitude, room.longitude
            );
            return distance <= radius;
          })
          .toList();
      
      chatRooms.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return chatRooms;
    } catch (e) {
      print('위치 기반 채팅룸 조회 오류: $e');
      return [];
    }
  }

  // 채팅룸 생성
  Future<String?> createChatRoom(ChatRoom chatRoom) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(chatRoom.toFirestore());
      return docRef.id;
    } catch (e) {
      print('채팅룸 생성 오류: $e');
      return null;
    }
  }

  // 채팅룸 업데이트
  Future<bool> updateChatRoom(String id, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(data);
      return true;
    } catch (e) {
      print('채팅룸 업데이트 오류: $e');
      return false;
    }
  }

  // 사용자 수 증가
  Future<bool> incrementUserCount(String chatRoomId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(chatRoomId)
          .update({
        'userCount': FieldValue.increment(1),
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('사용자 수 증가 오류: $e');
      return false;
    }
  }

  // 사용자 수 감소
  Future<bool> decrementUserCount(String chatRoomId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(chatRoomId)
          .update({
        'userCount': FieldValue.increment(-1),
      });
      return true;
    } catch (e) {
      print('사용자 수 감소 오류: $e');
      return false;
    }
  }

  // 간단한 거리 계산 (실제로는 haversine 공식 사용 권장)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // 지구 반지름 (미터)
    final double dLat = (lat2 - lat1) * (3.14159 / 180);
    final double dLon = (lon2 - lon1) * (3.14159 / 180);
    
    final double a = 
        (dLat / 2) * (dLat / 2) +
        lat1 * (3.14159 / 180) * lat2 * (3.14159 / 180) * 
        (dLon / 2) * (dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double atan2(double y, double x) {
    return dart_math.atan2(y, x);
  }

  double sqrt(double x) {
    return dart_math.sqrt(x);
  }
} 