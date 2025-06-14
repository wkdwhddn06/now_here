import 'package:flutter/material.dart';
import '../../../data/chat_room.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/chat_room_item.dart';
import '../../chat/chat_screen.dart';

class ChatRoomListSection extends StatelessWidget {
  final List<ChatRoom> chatRooms;
  final bool isLoading;
  final String error;
  final VoidCallback onRetry;

  const ChatRoomListSection({
    super.key,
    required this.chatRooms,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingState();
    }

    if (error.isNotEmpty) {
      return ErrorState(
        error: error,
        onRetry: onRetry,
      );
    }

    if (chatRooms.isEmpty) {
      return const EmptyState(
        message: '아직 채팅룸이 없습니다',
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final room = chatRooms[index];
        return ChatRoomItem(
          location: room.locationName,
          participants: room.userCount,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatRoom: room,
                  isPreviewMode: true, // 미리보기 모드로 열기
                ),
              ),
            );
          },
        );
      },
    );
  }
} 