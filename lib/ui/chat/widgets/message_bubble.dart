import 'package:flutter/material.dart';
import '../../../data/chat_message_realtime.dart';

class MessageBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 8 : 2,
        bottom: isLastInGroup ? 8 : 2,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // 첫 번째 메시지에만 아바타 표시, 나머지는 빈 공간
            SizedBox(
              width: 32,
              child: isFirstInGroup ? _buildAvatar() : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 첫 번째 메시지에만 사용자명 표시
                if (!isMe && isFirstInGroup) _buildUserName(),
                _buildMessageBubble(),
                // 마지막 메시지에만 시간 표시
                if (showTimestamp && isLastInGroup) _buildTimestamp(),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            // 첫 번째 메시지에만 아바타 표시, 나머지는 빈 공간
            SizedBox(
              width: 32,
              child: isFirstInGroup ? _buildAvatar() : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isMe ? Colors.deepPurple[300] : Colors.grey[600],
      child: Text(
        isMe ? '나' : (message.userName?.substring(0, 1) ?? '?'),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserName() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        message.userName ?? '익명',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.deepPurple : const Color(0xFF3d3d3d),
        borderRadius: _getBubbleRadius(),
      ),
      child: Text(
        message.message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  BorderRadius _getBubbleRadius() {
    const radius = Radius.circular(18);
    const smallRadius = Radius.circular(6);
    
    if (isFirstInGroup && isLastInGroup) {
      // 단독 메시지 - 모든 모서리 둥글게
      return BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: isMe ? radius : smallRadius,
        bottomRight: isMe ? smallRadius : radius,
      );
    } else if (isFirstInGroup) {
      // 그룹 첫 메시지 - 상단만 둥글게
      return BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: isMe ? radius : smallRadius,
        bottomRight: isMe ? smallRadius : radius,
      );
    } else if (isLastInGroup) {
      // 그룹 마지막 메시지 - 하단만 둥글게
      return BorderRadius.only(
        topLeft: isMe ? radius : smallRadius,
        topRight: isMe ? smallRadius : radius,
        bottomLeft: isMe ? radius : smallRadius,
        bottomRight: isMe ? smallRadius : radius,
      );
    } else {
      // 그룹 중간 메시지 - 양쪽만 둥글게
      return BorderRadius.only(
        topLeft: isMe ? radius : smallRadius,
        topRight: isMe ? smallRadius : radius,
        bottomLeft: isMe ? radius : smallRadius,
        bottomRight: isMe ? smallRadius : radius,
      );
    }
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: isMe ? 0 : 8,
        right: isMe ? 8 : 0,
      ),
      child: Text(
        _formatTime(message.dateTime),
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
      // 오늘인 경우 시간만 표시
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // 다른 날인 경우 날짜와 시간 표시
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
} 