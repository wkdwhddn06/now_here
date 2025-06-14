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

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: widget.isMe ? 64 : 16,
        right: widget.isMe ? 16 : 64,
      ),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getEventColor(widget.event.type).withOpacity(0.1),
                _getEventColor(widget.event.type).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getEventColor(widget.event.type).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _getEventColor(widget.event.type).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 - 더 컴팩트하고 모던한 디자인
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 이벤트 타입 아이콘
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getEventColor(widget.event.type),
                            _getEventColor(widget.event.type).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getEventColor(widget.event.type).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _getEventIcon(widget.event.type),
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // 제목과 위치
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.event.locationName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 구분선
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      _getEventColor(widget.event.type).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // 내용
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 설명
                    Text(
                      widget.event.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    
                    // 정보 칩들 - 더 모던한 디자인
                    Row(
                      children: [
                        _buildModernInfoChip(
                          icon: Icons.people_outline,
                          text: '${widget.event.participantIds.length}/${widget.event.maxParticipants}',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildModernInfoChip(
                          icon: Icons.schedule,
                          text: widget.event.timeLeftString,
                          color: Colors.orange,
                        ),
                        if (widget.event.isExpired || widget.event.isFull) ...[
                          const SizedBox(width: 8),
                          _buildStatusChip(),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // 액션 버튼 - 더 모던한 디자인
                    if (!widget.event.isExpired) ...[
                      SizedBox(
                        width: double.infinity,
                        child: _buildModernActionButton(
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

  Widget _buildModernInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
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
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    if (widget.event.isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.block,
              size: 14,
              color: Colors.red,
            ),
            const SizedBox(width: 4),
            const Text(
              '마감됨',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    } else if (widget.event.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.group,
              size: 14,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            const Text(
              '인원마감',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildModernActionButton(bool isParticipant, bool isCreator) {
    if (widget.event.isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            '마감된 이벤트',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (isParticipant) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green,
              Color(0xFF4CAF50),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : () => _joinEventAndNavigate(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isCreator ? '내 이벤트 채팅방' : '이벤트 채팅방 입장',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (widget.event.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Center(
          child: Text(
            '인원이 가득참',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getEventColor(widget.event.type),
              _getEventColor(widget.event.type).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getEventColor(widget.event.type).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : () => _joinEventAndNavigate(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  const Text(
                    '참여하기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
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

  IconData _getEventIcon(EventType eventType) {
    switch (eventType) {
      case EventType.study:
        return Icons.school;
      case EventType.food:
        return Icons.restaurant;
      case EventType.help:
        return Icons.help;
      case EventType.chat:
        return Icons.chat;
      case EventType.coffee:
        return Icons.local_cafe;
      case EventType.walk:
        return Icons.directions_walk;
      case EventType.shopping:
        return Icons.shopping_bag;
      case EventType.emergency:
        return Icons.emergency;
    }
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