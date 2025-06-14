import 'package:flutter/material.dart';
import '../../../data/chat_event.dart';
import '../../../service/event_service.dart';
import '../../../service/user_service.dart';

class EventBubble extends StatefulWidget {
  final ChatEvent event;
  final String chatRoomId;

  const EventBubble({
    super.key,
    required this.event,
    required this.chatRoomId,
  });

  @override
  State<EventBubble> createState() => _EventBubbleState();
}

class _EventBubbleState extends State<EventBubble> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _userService.currentUser.id;
    final isParticipant = widget.event.participants.contains(currentUserId);
    final isCreator = widget.event.creatorId == currentUserId;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.grey[900],
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _getEventColor(widget.event.eventType),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getEventColor(widget.event.eventType),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEventIcon(widget.event.eventType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.event.creatorName}님이 제안',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 상태 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.event.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(widget.event.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 이벤트 정보
              Text(
                widget.event.description,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              
              // 상세 정보
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(Icons.store, widget.event.storeName),
                  _buildInfoChip(Icons.schedule, widget.event.meetingTime),
                  _buildInfoChip(Icons.place, widget.event.meetingPlace),
                  _buildInfoChip(Icons.group, widget.event.participantCount),
                ],
              ),
              
              if (widget.event.specialNote != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💡 ${widget.event.specialNote}',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // 하단 정보 및 버튼
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.event.timeUntilExpiry,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (!widget.event.isExpired && widget.event.status != 'cancelled') ...[
                    if (isParticipant) ...[
                      if (isCreator)
                        _buildActionButton(
                          '이벤트 취소',
                          Colors.red,
                          Icons.cancel,
                          () => _cancelEvent(),
                        )
                      else
                        _buildActionButton(
                          '참여 취소',
                          Colors.grey,
                          Icons.exit_to_app,
                          () => _leaveEvent(),
                        ),
                    ] else if (widget.event.canJoin) ...[
                      _buildActionButton(
                        '참여하기',
                        Colors.green,
                        Icons.add,
                        () => _joinEvent(),
                      ),
                    ] else ...[
                      _buildActionButton(
                        '마감됨',
                        Colors.grey,
                        Icons.block,
                        null,
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: _isLoading 
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 14),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> _joinEvent() async {
    setState(() => _isLoading = true);
    
    final success = await _eventService.joinEvent(
      widget.event.id,
      widget.chatRoomId,
      _userService.currentUser.id,
    );
    
    setState(() => _isLoading = false);
    
    if (success) {
      _showMessage('이벤트에 참여했습니다!', Colors.green);
    } else {
      _showMessage('참여에 실패했습니다.', Colors.red);
    }
  }

  Future<void> _leaveEvent() async {
    setState(() => _isLoading = true);
    
    final success = await _eventService.leaveEvent(
      widget.event.id,
      widget.chatRoomId,
      _userService.currentUser.id,
    );
    
    setState(() => _isLoading = false);
    
    if (success) {
      _showMessage('이벤트에서 나갔습니다.', Colors.orange);
    } else {
      _showMessage('나가기에 실패했습니다.', Colors.red);
    }
  }

  Future<void> _cancelEvent() async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('이벤트 취소', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말로 이벤트를 취소하시겠습니까?\n참여자들에게 알림이 전송됩니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니요'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      final success = await _eventService.leaveEvent(
        widget.event.id,
        widget.chatRoomId,
        _userService.currentUser.id,
      );
      
      setState(() => _isLoading = false);
      
      if (success) {
        _showMessage('이벤트가 취소되었습니다.', Colors.red);
      } else {
        _showMessage('취소에 실패했습니다.', Colors.red);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'meal':
        return Colors.orange;
      case 'coffee':
        return Colors.brown;
      case 'shopping':
        return Colors.purple;
      case 'activity':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'meal':
        return Icons.restaurant;
      case 'coffee':
        return Icons.local_cafe;
      case 'shopping':
        return Icons.shopping_bag;
      case 'activity':
        return Icons.local_activity;
      default:
        return Icons.event;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'full':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return '모집중';
      case 'full':
        return '인원마감';
      case 'expired':
        return '마감됨';
      case 'cancelled':
        return '취소됨';
      default:
        return '알 수 없음';
    }
  }
} 