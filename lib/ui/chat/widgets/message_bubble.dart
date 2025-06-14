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

    // 일반 텍스트 메시지
    return _buildTextMessage();
  }

  Widget _buildLoadingEventBubble() {
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isMe ? Colors.blue[600] : Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
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

  Widget _buildTextMessage() {
    return Container(
      margin: EdgeInsets.only(
        left: widget.isMe ? 64 : 16,
        right: widget.isMe ? 16 : 64,
        top: widget.isFirstInGroup ? 8 : 2,
        bottom: widget.isLastInGroup ? 8 : 2,
      ),
      child: Column(
        crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 사용자 이름 (첫 번째 메시지이고 내가 보낸 메시지가 아닐 때만)
          if (widget.isFirstInGroup && !widget.isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: AnonymousUserName(
                userId: widget.message.userId,
                userName: widget.message.userName,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                showGradient: false,
              ),
            ),
          
          // 메시지 버블
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.blue[600] : Colors.grey[800],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(widget.isMe || !widget.isFirstInGroup ? 16 : 4),
                topRight: Radius.circular(!widget.isMe || !widget.isFirstInGroup ? 16 : 4),
                bottomLeft: Radius.circular(widget.isMe || !widget.isLastInGroup ? 16 : 4),
                bottomRight: Radius.circular(!widget.isMe || !widget.isLastInGroup ? 16 : 4),
              ),
            ),
            child: Text(
              widget.message.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
          
          // 시간 표시 (마지막 메시지일 때만)
          if (widget.showTimestamp)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(widget.message.dateTime),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ),
        ],
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