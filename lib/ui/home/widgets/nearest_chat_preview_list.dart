import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/chat_room.dart';
import 'nearest_chat_preview.dart';

class NearestChatPreviewList extends StatelessWidget {
  final List<ChatRoom> nearestRooms;
  final Position? currentPosition;

  const NearestChatPreviewList({
    super.key,
    required this.nearestRooms,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    if (nearestRooms.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_off,
              color: Colors.orange[300],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '근처에 채팅룸이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '새로운 채팅룸을 만들어보세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: nearestRooms.length,
        itemBuilder: (context, index) {
          return Container(
            width: 280, // 각 카드의 고정 너비
            margin: EdgeInsets.only(
              right: index < nearestRooms.length - 1 ? 12 : 0,
            ),
            child: NearestChatPreview(
              nearestRoom: nearestRooms[index],
              currentPosition: currentPosition,
            ),
          );
        },
      ),
    );
  }
} 