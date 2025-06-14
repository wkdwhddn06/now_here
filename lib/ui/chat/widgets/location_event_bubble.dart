import 'package:flutter/material.dart';
import '../../../data/location_event.dart';
import '../../../service/location_event_service.dart';
import '../../../service/chat_room_service.dart';
import '../../../service/user_service.dart';
import '../../../data/chat_room.dart';
import '../chat_screen.dart';

class LocationEventBubble extends StatefulWidget {
  final LocationEvent event;
  final bool isMe;

  const LocationEventBubble({
    super.key,
    required this.event,
    required this.isMe,
  });

  @override
  State<LocationEventBubble> createState() => _LocationEventBubbleState();
}

class _LocationEventBubbleState extends State<LocationEventBubble> {
  final LocationEventService _eventService = LocationEventService();
  final ChatRoomService _chatRoomService = ChatRoomService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _userService.currentUser.id;
    final isParticipant = widget.event.participantIds.contains(currentUserId);
    final isCreator = widget.event.creatorId == currentUserId;

    return Container(
      margin: EdgeInsets.only(
        left: widget.isMe ? 64 : 16,
        right: widget.isMe ? 16 : 64,
        top: 4,
        bottom: 4,
      ),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.blue[600] : Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getEventColor(widget.event.type).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getEventColor(widget.event.type).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getEventColor(widget.event.type),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.event.type.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.event.locationName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 내용
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // 정보 칩들
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                          icon: Icons.people,
                          text: '${widget.event.participantIds.length}/${widget.event.maxParticipants}',
                          color: Colors.blue,
                        ),
                        _buildInfoChip(
                          icon: Icons.access_time,
                          text: widget.event.timeLeftString,
                          color: Colors.orange,
                        ),
                        if (widget.event.isExpired)
                          _buildInfoChip(
                            icon: Icons.block,
                            text: '마감됨',
                            color: Colors.red,
                          )
                        else if (widget.event.isFull)
                          _buildInfoChip(
                            icon: Icons.group,
                            text: '인원마감',
                            color: Colors.amber,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 액션 버튼
                    if (!widget.event.isExpired) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(
                          isParticipant, 
                          isCreator,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isParticipant, bool isCreator) {
    if (widget.event.isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '마감된 이벤트',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    if (isParticipant) {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _joinEventAndNavigate(),
        icon: _isLoading 
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chat, size: 14),
        label: Text(
          isCreator ? '내 이벤트 채팅방' : '이벤트 채팅방 입장',
          style: const TextStyle(fontSize: 11),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else if (widget.event.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            '인원이 가득참',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _joinEventAndNavigate(),
        icon: _isLoading 
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add, size: 14),
        label: const Text(
          '참여하기',
          style: TextStyle(fontSize: 11),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getEventColor(widget.event.type),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _joinEventAndNavigate() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _userService.currentUser.id;
      final userName = _userService.currentUser.name;
      
      // 이미 참여했는지 확인
      final isAlreadyParticipating = await _eventService.isUserParticipating(widget.event.id, userId);
      
      if (!isAlreadyParticipating) {
        // 새로운 참여 시도
        final joinSuccess = await _eventService.joinEvent(widget.event.id, userId, userName);
        
        if (!joinSuccess) {
          _showMessage('이벤트 참여에 실패했습니다.', Colors.red);
          return;
        }
      }
      
      // 이벤트 전용 채팅방 생성/이동
      final chatRoom = await _createEventChatRoom(widget.event, userId, userName);
      
      if (chatRoom != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
        
        if (!isAlreadyParticipating) {
          _showMessage('${widget.event.title} 이벤트에 참여했습니다!', Colors.green);
        }
      } else {
        _showMessage('채팅방 생성에 실패했습니다.', Colors.red);
      }
    } catch (e) {
      _showMessage('오류가 발생했습니다: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<ChatRoom?> _createEventChatRoom(LocationEvent event, String userId, String userName) async {
    try {
      // 이벤트 ID를 기반으로 한 고유한 채팅방 ID
      final eventChatRoomId = 'event_chat_${event.id}';
      final chatRoomLocationName = '${event.type.icon} ${event.title} (${event.locationName})';
      
      // 채팅방 생성
      final chatRoom = ChatRoom(
        id: eventChatRoomId,
        locationName: chatRoomLocationName,
        latitude: event.latitude,
        longitude: event.longitude,
        createdAt: DateTime.now(),
        userCount: 1,
        lastMessageAt: DateTime.now(),
        isEventRoom: true, // 이벤트 채팅방으로 표시
      );

      // Firestore에 채팅방 저장
      await _chatRoomService.createChatRoom(chatRoom);
      
      return chatRoom;
    } catch (e) {
      print('이벤트 채팅방 생성 실패: $e');
      // 이미 존재하는 채팅방일 수 있으므로 기본 ChatRoom 객체 반환
      if (e.toString().contains('already exists') || e.toString().contains('ALREADY_EXISTS')) {
        final chatRoom = ChatRoom(
          id: 'event_chat_${widget.event.id}',
          locationName: '${widget.event.type.icon} ${widget.event.title} (${widget.event.locationName})',
          latitude: widget.event.latitude,
          longitude: widget.event.longitude,
          createdAt: DateTime.now(),
          userCount: 1,
          lastMessageAt: DateTime.now(),
          isEventRoom: true, // 이벤트 채팅방으로 표시
        );
        return chatRoom;
      }
      return null;
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getEventColor(EventType eventType) {
    switch (eventType) {
      case EventType.study:
        return Colors.blue;
      case EventType.food:
        return Colors.orange;
      case EventType.help:
        return Colors.red;
      case EventType.chat:
        return Colors.purple;
      case EventType.coffee:
        return Colors.brown;
      case EventType.walk:
        return Colors.green;
      case EventType.shopping:
        return Colors.pink;
      case EventType.emergency:
        return Colors.red;
    }
  }
} 