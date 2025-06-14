import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../data/chat_message_realtime.dart';
import 'ai_event_service.dart';

class ChatServiceRealtime {
  static final ChatServiceRealtime _instance = ChatServiceRealtime._internal();
  factory ChatServiceRealtime() => _instance;
  ChatServiceRealtime._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://nowhere-8985a-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );
  
  final AiEventService _aiService = AiEventService();

  // 채팅룸 메시지 스트림 구독
  Stream<List<ChatMessageRealtime>> getMessagesStream(String chatRoomId) {
    return _database
        .ref('chatRooms/$chatRoomId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final List<ChatMessageRealtime> messages = [];
      
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((key, value) {
          if (value is Map) {
            final message = ChatMessageRealtime.fromMap(
              key, 
              Map<String, dynamic>.from(value as Map)
            );
            messages.add(message);
          }
        });
        
        // 시간순으로 정렬
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
      
      return messages;
    });
  }

  // 메시지 전송
  Future<bool> sendMessage({
    required String chatRoomId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    try {
      final messageRef = _database
          .ref('chatRooms/$chatRoomId/messages')
          .push();

      // AI 비속어 감지
      final hasProfanity = await _aiService.checkForProfanity(message);
      
      final ChatMessageRealtime chatMessage;
      
      if (hasProfanity) {
        // 비속어가 감지된 경우 블라인드 처리된 메시지 생성
        chatMessage = ChatMessageRealtime.blocked(
          id: messageRef.key!,
          userId: userId,
          userName: userName,
          originalMessage: message,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        print('비속어 감지로 메시지 블라인드 처리: $userName');
      } else {
        // 정상 메시지 생성
        chatMessage = ChatMessageRealtime(
          id: messageRef.key!,
          userId: userId,
          userName: userName,
          message: message,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      }

      await messageRef.set(chatMessage.toMap());
      
      // 채팅룸 정보 업데이트 (마지막 메시지 시간)
      await _updateChatRoomLastMessage(chatRoomId);
      
      return true;
    } catch (e) {
      print('메시지 전송 실패: $e');
      return false;
    }
  }

  // 채팅룸 입장
  Future<bool> joinChatRoom({
    required String chatRoomId,
    required String userId,
    required String userName,
  }) async {
    try {
      // 사용자를 채팅룸에 추가
      await _database
          .ref('chatRooms/$chatRoomId/participants/$userId')
          .set({
        'name': userName,
        'joinedAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('채팅룸 입장 실패: $e');
      return false;
    }
  }

  // 채팅룸 퇴장
  Future<bool> leaveChatRoom({
    required String chatRoomId,
    required String userId,
  }) async {
    try {
      // 사용자를 채팅룸에서 제거
      await _database
          .ref('chatRooms/$chatRoomId/participants/$userId')
          .remove();

      return true;
    } catch (e) {
      print('채팅룸 퇴장 실패: $e');
      return false;
    }
  }

  // 현재 참여자 수 조회
  Future<int> getParticipantCount(String chatRoomId) async {
    try {
      final snapshot = await _database
          .ref('chatRooms/$chatRoomId/participants')
          .get();
      
      if (snapshot.exists && snapshot.value is Map) {
        return (snapshot.value as Map).length;
      }
      return 0;
    } catch (e) {
      print('참여자 수 조회 실패: $e');
      return 0;
    }
  }

  // 참여자 수 실시간 스트림
  Stream<int> getParticipantCountStream(String chatRoomId) {
    return _database
        .ref('chatRooms/$chatRoomId/participants')
        .onValue
        .map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return (event.snapshot.value as Map).length;
      }
      return 0;
    });
  }

  // 채팅룸 마지막 메시지 시간 업데이트 (Firestore도 함께 업데이트)
  Future<void> _updateChatRoomLastMessage(String chatRoomId) async {
    try {
      final now = DateTime.now();
      
      // Realtime Database 업데이트
      await _database
          .ref('chatRooms/$chatRoomId')
          .update({
        'lastMessageAt': now.millisecondsSinceEpoch,
      });

      // Firestore도 업데이트 (선택사항 - 필요시 ChatRoomService 사용)
    } catch (e) {
      print('마지막 메시지 시간 업데이트 실패: $e');
    }
  }

  // 채팅룸 초기화 (필요시)
  Future<bool> initializeChatRoom(String chatRoomId) async {
    try {
      await _database
          .ref('chatRooms/$chatRoomId')
          .set({
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('채팅룸 초기화 실패: $e');
      return false;
    }
  }

  // 메시지 삭제 (관리자 기능)
  Future<bool> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await _database
          .ref('chatRooms/$chatRoomId/messages/$messageId')
          .remove();
      return true;
    } catch (e) {
      print('메시지 삭제 실패: $e');
      return false;
    }
  }

  // LocationEvent를 채팅 메시지로 공유
  Future<bool> shareLocationEvent({
    required String chatRoomId,
    required String userId,
    required String userName,
    required String eventId,
    required String eventTitle,
  }) async {
    try {
      final messageRef = _database
          .ref()
          .child('chatRooms')
          .child(chatRoomId)
          .child('messages')
          .push();

      final message = ChatMessageRealtime.locationEvent(
        id: messageRef.key!,
        userId: userId,
        userName: userName,
        eventId: eventId,
        eventTitle: eventTitle,
      );

      await messageRef.set(message.toMap());
      
      // 채팅방의 lastMessageAt 업데이트
      await _database
          .ref()
          .child('chatRooms')
          .child(chatRoomId)
          .child('lastMessageAt')
          .set(ServerValue.timestamp);

      print('LocationEvent 메시지 전송 완료: $eventTitle');
      return true;
    } catch (e) {
      print('LocationEvent 메시지 전송 실패: $e');
      return false;
    }
  }
} 