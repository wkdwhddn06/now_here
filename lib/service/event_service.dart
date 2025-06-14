import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/chat_event.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 이벤트 생성
  Future<bool> createEvent(ChatEvent event, String chatRoomId) async {
    try {
      // 채팅방의 events 컬렉션에 저장
      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('events')
          .doc(event.id)
          .set(event.toMap());
      
      print('이벤트 생성 완료: ${event.title}');
      return true;
    } catch (e) {
      print('이벤트 생성 실패: $e');
      return false;
    }
  }

  // 이벤트 참여
  Future<bool> joinEvent(String eventId, String chatRoomId, String userId) async {
    try {
      final eventRef = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('events')
          .doc(eventId);

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        
        if (!eventDoc.exists) {
          throw Exception('이벤트를 찾을 수 없습니다');
        }

        final event = ChatEvent.fromMap(eventDoc.data()!);
        
        if (!event.canJoin) {
          throw Exception('참여할 수 없는 이벤트입니다');
        }

        if (event.participants.contains(userId)) {
          throw Exception('이미 참여한 이벤트입니다');
        }

        final updatedParticipants = [...event.participants, userId];
        final newStatus = updatedParticipants.length >= event.maxParticipants ? 'full' : 'active';

        transaction.update(eventRef, {
          'participants': updatedParticipants,
          'status': newStatus,
        });
      });

      print('이벤트 참여 완료: $eventId');
      return true;
    } catch (e) {
      print('이벤트 참여 실패: $e');
      return false;
    }
  }

  // 이벤트 나가기
  Future<bool> leaveEvent(String eventId, String chatRoomId, String userId) async {
    try {
      final eventRef = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('events')
          .doc(eventId);

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        
        if (!eventDoc.exists) {
          throw Exception('이벤트를 찾을 수 없습니다');
        }

        final event = ChatEvent.fromMap(eventDoc.data()!);
        
        if (!event.participants.contains(userId)) {
          throw Exception('참여하지 않은 이벤트입니다');
        }

        final updatedParticipants = event.participants.where((id) => id != userId).toList();
        
        // 생성자가 나가면 이벤트 취소
        if (event.creatorId == userId) {
          transaction.update(eventRef, {
            'participants': updatedParticipants,
            'status': 'cancelled',
          });
        } else {
          transaction.update(eventRef, {
            'participants': updatedParticipants,
            'status': 'active', // 자리가 생겼으므로 다시 활성화
          });
        }
      });

      print('이벤트 나가기 완료: $eventId');
      return true;
    } catch (e) {
      print('이벤트 나가기 실패: $e');
      return false;
    }
  }

  // 채팅방의 활성 이벤트 스트림
  Stream<List<ChatEvent>> getActiveEventsStream(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('events')
        .where('status', whereIn: ['active', 'full'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatEvent.fromMap(doc.data()))
              .where((event) => !event.isExpired) // 만료된 이벤트 필터링
              .toList();
        });
  }

  // 특정 이벤트 가져오기
  Future<ChatEvent?> getEvent(String eventId, String chatRoomId) async {
    try {
      final doc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        return ChatEvent.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('이벤트 조회 실패: $e');
      return null;
    }
  }

  // 만료된 이벤트 정리 (백그라운드에서 실행)
  Future<void> cleanupExpiredEvents(String chatRoomId) async {
    try {
      final snapshot = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('events')
          .where('expiredAt', isLessThan: DateTime.now().millisecondsSinceEpoch)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': 'expired'});
      }
      
      await batch.commit();
      print('만료된 이벤트 정리 완료');
    } catch (e) {
      print('이벤트 정리 실패: $e');
    }
  }
} 