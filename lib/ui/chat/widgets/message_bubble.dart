import 'package:flutter/material.dart';
import '../../../data/chat_message_realtime.dart';
import '../../../data/location_event.dart';
import '../../../service/location_event_service.dart';
import 'location_event_bubble.dart';
import '../../widgets/anonymous_user_widgets.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessageRealtime message;
  final bool isMe;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.showTimestamp = true,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final LocationEventService _eventService = LocationEventService();
  LocationEvent? _locationEvent;
  bool _isLoadingEvent = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.type == MessageType.locationEvent && widget.message.eventId != null) {
      _loadLocationEvent();
    }
  }

  Future<void> _loadLocationEvent() async {
    setState(() => _isLoadingEvent = true);
    
    try {
      final events = await _eventService.getNearbyEvents();
      final event = events.firstWhere(
        (e) => e.id == widget.message.eventId,
        orElse: () => throw Exception('이벤트를 찾을 수 없습니다'),
      );
      
      setState(() {
        _locationEvent = event;
        _isLoadingEvent = false;
      });
    } catch (e) {
      print('LocationEvent 로드 실패: $e');
      setState(() => _isLoadingEvent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // LocationEvent 메시지인 경우
    if (widget.message.type == MessageType.locationEvent) {
      if (_isLoadingEvent) {
        return _buildLoadingEventBubble();
      }
      
      if (_locationEvent != null) {
        return LocationEventBubble(
          event: _locationEvent!,
          isMe: widget.isMe,
        );
      } else {
        return _buildErrorEventBubble();
      }
    }

    // 일반 텍스트 메시지 - 이전 디자인 사용
    return Padding(
      padding: EdgeInsets.only(
        top: widget.isFirstInGroup ? 8 : 2,
        bottom: widget.isLastInGroup ? 8 : 2,
      ),
      child: Row(
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMe) ...[
            // 첫 번째 메시지에만 아바타 표시, 나머지는 빈 공간
            SizedBox(
              width: 32,
              child: widget.isFirstInGroup ? _buildAvatar() : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 첫 번째 메시지에만 사용자명 표시
                if (!widget.isMe && widget.isFirstInGroup) _buildUserName(),
                _buildMessageBubble(),
                // 마지막 메시지에만 시간 표시
                if (widget.showTimestamp && widget.isLastInGroup) _buildTimestamp(),
              ],
            ),
          ),
          if (widget.isMe) ...[
            const SizedBox(width: 8),
            // 첫 번째 메시지에만 아바타 표시, 나머지는 빈 공간
            SizedBox(
              width: 32,
              child: widget.isFirstInGroup ? _buildAvatar() : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingEventBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.deepPurple : const Color(0xFF3d3d3d),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text(
                '이벤트 정보를 불러오는 중...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorEventBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Align(
        alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.red.withOpacity(0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 16),
              SizedBox(width: 8),
              Text(
                '이벤트를 찾을 수 없습니다',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return AnonymousUserAvatar(
      userId: widget.message.userId,
      size: 32,
    );
  }

  Widget _buildUserName() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: AnonymousUserName(
        userId: widget.message.userId,
        userName: widget.message.userName,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        showGradient: false,
      ),
    );
  }

  Widget _buildMessageBubble() {
    // 블라인드 처리된 메시지인 경우 특별한 디자인 적용
    if (widget.message.isBlocked) {
      return _buildBlockedMessageBubble();
    }
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.deepPurple : const Color(0xFF3d3d3d),
        borderRadius: _getBubbleRadius(),
      ),
      child: Text(
        widget.message.message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  // 블라인드 처리된 메시지 버블
  Widget _buildBlockedMessageBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.6),
        borderRadius: _getBubbleRadius(),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_off,
                color: Colors.orange[300],
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.message.message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showOriginalMessage(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[300],
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '원본 보기',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 원본 메시지 보기 다이얼로그
  void _showOriginalMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d2d2d),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[300],
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '원본 메시지',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 메시지는 부적절한 내용으로 인해 자동으로 숨겨졌습니다.',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800]?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                widget.message.originalMessage ?? '원본 메시지를 찾을 수 없습니다.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '닫기',
              style: TextStyle(
                color: Colors.orange[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _getBubbleRadius() {
    const radius = Radius.circular(18);
    const smallRadius = Radius.circular(6);
    
    if (widget.isFirstInGroup && widget.isLastInGroup) {
      // 단독 메시지 - 모든 모서리 둥글게
      return BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: widget.isMe ? radius : smallRadius,
        bottomRight: widget.isMe ? smallRadius : radius,
      );
    } else if (widget.isFirstInGroup) {
      // 그룹 첫 메시지 - 상단만 둥글게
      return BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: widget.isMe ? radius : smallRadius,
        bottomRight: widget.isMe ? smallRadius : radius,
      );
    } else if (widget.isLastInGroup) {
      // 그룹 마지막 메시지 - 하단만 둥글게
      return BorderRadius.only(
        topLeft: widget.isMe ? radius : smallRadius,
        topRight: widget.isMe ? smallRadius : radius,
        bottomLeft: widget.isMe ? radius : smallRadius,
        bottomRight: widget.isMe ? smallRadius : radius,
      );
    } else {
      // 그룹 중간 메시지 - 양쪽만 둥글게
      return BorderRadius.only(
        topLeft: widget.isMe ? radius : smallRadius,
        topRight: widget.isMe ? smallRadius : radius,
        bottomLeft: widget.isMe ? radius : smallRadius,
        bottomRight: widget.isMe ? smallRadius : radius,
      );
    }
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: widget.isMe ? 0 : 8,
        right: widget.isMe ? 8 : 0,
      ),
      child: Text(
        _formatTime(widget.message.dateTime),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white54,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      // 오늘: 시간만 표시
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // 어제
      return '어제 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 그 이전: 날짜 포함
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
} 