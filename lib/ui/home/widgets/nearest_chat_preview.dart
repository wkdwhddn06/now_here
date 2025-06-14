import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../data/chat_room.dart';
import '../../../data/chat_message_realtime.dart';
import '../../../service/chat_service_realtime.dart';
import '../../../service/location_service.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/anonymous_user_widgets.dart';
import '../../chat/chat_screen.dart';

class NearestChatPreview extends StatefulWidget {
  final ChatRoom? nearestRoom;
  final Position? currentPosition;

  const NearestChatPreview({
    super.key,
    this.nearestRoom,
    this.currentPosition,
  });

  @override
  State<NearestChatPreview> createState() => _NearestChatPreviewState();
}

class _NearestChatPreviewState extends State<NearestChatPreview> {
  final ChatServiceRealtime _chatService = ChatServiceRealtime();
  final LocationService _locationService = LocationService();
  
  List<ChatMessageRealtime> _recentMessages = [];
  StreamSubscription<List<ChatMessageRealtime>>? _messagesSubscription;
  bool _isLoading = false;
  double? _distanceInMeters;

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
    _calculateDistance();
  }

  @override
  void didUpdateWidget(NearestChatPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nearestRoom?.id != widget.nearestRoom?.id) {
      _subscribeToMessages();
      _calculateDistance();
    }
  }

  Future<void> _calculateDistance() async {
    if (widget.nearestRoom == null || widget.currentPosition == null) {
      setState(() {
        _distanceInMeters = null;
      });
      return;
    }

    try {
      final distance = _locationService.calculateDistance(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
        widget.nearestRoom!.latitude,
        widget.nearestRoom!.longitude,
      );
      
      setState(() {
        _distanceInMeters = distance;
      });
    } catch (e) {
      print('거리 계산 실패: $e');
      setState(() {
        _distanceInMeters = null;
      });
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    
    if (widget.nearestRoom?.id == null) {
      setState(() {
        _recentMessages = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _messagesSubscription = _chatService
        .getMessagesStream(widget.nearestRoom!.id!)
        .listen(
      (messages) {
        setState(() {
          // 최근 6개 메시지만 가져오기 (최신순 유지)
          _recentMessages = messages.take(6).toList();
          _isLoading = false;
        });
      },
      onError: (error) {
        print('메시지 스트림 오류: $error');
        setState(() => _isLoading = false);
      },
    );
  }

  String _getDistanceText() {
    if (_distanceInMeters == null) {
      return '근방 * M';
    }

    if (_distanceInMeters! < 1000) {
      return '근방 ${_distanceInMeters!.round()}M';
    } else {
      double distanceInKm = _distanceInMeters! / 1000;
      return '근방 ${distanceInKm.toStringAsFixed(1)}KM';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nearestRoom == null) {
      return _buildLocationError();
    }

    return GestureDetector(
      onTap: () {
        if (widget.nearestRoom != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatRoom: widget.nearestRoom!),
            ),
          );
        }
      },
      child: Container(
        height: 180, // 고정 높이 설정
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.deepPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _buildMessagePreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationError() {
    return Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '위치 권한이 필요합니다',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '가까운 채팅룸을 찾기 위해 위치 권한을 허용해주세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await _locationService.requestLocationPermission();
            },
            child: const Text(
              '허용',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.deepPurple[300],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nearestRoom!.locationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getDistanceText(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
    );
  }

  Widget _buildMessagePreview() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.deepPurple,
            ),
          ),
        ),
      );
    }

    if (_recentMessages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Center(
          child: Text(
            '아직 메시지가 없습니다.\n첫 번째 메시지를 보내보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // 최대 4개의 메시지만 표시 (최신순으로 정렬)
    final displayMessages = _recentMessages.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SingleChildScrollView(
        reverse: true, // 🔄 리버스 그래비티 적용
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end, // 바닥에서 시작
          children: displayMessages.map((message) { // 메시지 순서 뒤집기
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                  AnonymousUserName(
                    userId: message.userId,
                    userName: message.userName,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    showGradient: false, // 단색으로 변경하여 확실히 보이도록
                  ),
                  const Text(
                    ': ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      message.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      maxLines: 2, // 메시지 최대 2줄로 제한
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
} 