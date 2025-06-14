import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../../data/location_event.dart';
import '../../../data/chat_room.dart';
import '../../../service/location_event_service.dart';
import '../../../service/chat_room_service.dart';
import '../../../service/user_service.dart';
import '../../widgets/section_header.dart';
import '../../chat/chat_screen.dart';
import 'location_event_card.dart';
import 'create_event_screen.dart';

class LocationEventsSection extends StatefulWidget {
  final Position? currentPosition;

  const LocationEventsSection({
    super.key,
    this.currentPosition,
  });

  @override
  State<LocationEventsSection> createState() => _LocationEventsSectionState();
}

class _LocationEventsSectionState extends State<LocationEventsSection> {
  final LocationEventService _eventService = LocationEventService();
  final ChatRoomService _chatRoomService = ChatRoomService();
  final UserService _userService = UserService();
  List<LocationEvent> _events = [];
  bool _isLoading = true;
  StreamSubscription<List<LocationEvent>>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    print('LocationEventsSection initState 호출됨, currentPosition: ${widget.currentPosition}');
    _loadEvents();
  }

  @override
  void didUpdateWidget(LocationEventsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위치가 업데이트되었을 때 이벤트 다시 로드
    if (oldWidget.currentPosition != widget.currentPosition) {
      print('위치가 업데이트됨: ${oldWidget.currentPosition} -> ${widget.currentPosition}');
      _loadEvents();
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    print('_loadEvents 호출됨, currentPosition: ${widget.currentPosition}');
    
    if (widget.currentPosition == null) {
      print('현재 위치가 null이므로 이벤트 로드 중단');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // 1. 먼저 초기 데이터를 한 번 로드
      final initialEvents = await _eventService.getInitialLocationEvents(
        position: widget.currentPosition!,
        radiusKm: 3.0,
      );
      
      setState(() {
        _events = initialEvents;
        _isLoading = false;
      });

      // 2. 스트림 구독 시작 (실시간 업데이트)
      _eventsSubscription?.cancel();
      _eventsSubscription = _eventService.eventsStream.listen((allEvents) {
        if (widget.currentPosition != null) {
          _filterNearbyEvents(allEvents);
        }
      });
    } catch (e) {
      print('이벤트 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 근처 이벤트만 필터링하는 헬퍼 메서드
  void _filterNearbyEvents(List<LocationEvent> allEvents) {
    if (widget.currentPosition == null) return;

    final nearbyEvents = <LocationEvent>[];
    const radiusKm = 3.0;

    for (final event in allEvents) {
      final distance = Geolocator.distanceBetween(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
        event.latitude,
        event.longitude,
      );
      
      if (distance <= radiusKm * 1000) { // km를 m로 변환
        nearbyEvents.add(event);
      }
    }

    // 생성 시간 기준으로 정렬 (최신순)
    nearbyEvents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (mounted) {
      setState(() {
        _events = nearbyEvents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: '지금 여기서 일어나는 일'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () {
                    _navigateToCreateEvent();
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildEventsList()
      ],
    );
  }

  Widget _buildEventsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple,
        ),
      );
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
        final event = _events[index];
        return Padding(
          padding: EdgeInsets.only(
            right: index < _events.length - 1 ? 16 : 0,
          ),
          child: LocationEventCard(
            event: event,
            currentPosition: widget.currentPosition,
            onTap: () => _showEventDetails(event),
          ),
        );
      },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '근처에 진행중인 이벤트가 없어요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 이벤트를 만들어보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToCreateEvent,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('이벤트 만들기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateEvent() {
    if (widget.currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('위치 정보를 먼저 확인해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          currentPosition: widget.currentPosition!,
          onEventCreated: () {
            _loadEvents(); // 이벤트 생성 후 목록 새로고침
          },
        ),
      ),
    );
  }

  void _showEventDetails(LocationEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF2d2d2d),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.type.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.locationName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '설명',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.people,
                            label: '참여자',
                            value: '${event.participantIds.length}/${event.maxParticipants}명',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailItem(
                            icon: Icons.access_time,
                            label: '남은 시간',
                            value: event.timeLeftString,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // 이미 참여한 사용자는 항상 채팅방 입장 가능
                          if (event.participantIds.contains(_userService.currentUser.id)) {
                            _joinEvent(event);
                          }
                          // 새로운 사용자는 이벤트가 만료되지 않고 자리가 있어야 함
                          else if (!event.isFull && !event.isExpired) {
                            _joinEvent(event);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: event.participantIds.contains(_userService.currentUser.id)
                              ? Colors.green
                              : Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          event.isFull && !event.participantIds.contains(_userService.currentUser.id)
                              ? '참여 인원 마감'
                              : event.isExpired && !event.participantIds.contains(_userService.currentUser.id)
                                  ? '이벤트 종료'
                                  : event.participantIds.contains(_userService.currentUser.id)
                                      ? '채팅방 입장'
                                      : '참여하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _joinEvent(LocationEvent event) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );

      // 전역 사용자 정보 사용
      final currentUser = _userService.currentUser;
      final userId = currentUser.id;
      final userName = currentUser.name;

      print('이벤트 참여 시도: ${event.title}, 사용자: $userName ($userId)');

      // 1. 먼저 이미 참여했는지 확인
      final isAlreadyParticipating = await _eventService.isUserParticipating(event.id, userId);
      
      if (isAlreadyParticipating) {
        print('이미 참여한 이벤트입니다. 채팅방으로 이동합니다.');
        
        // 이벤트 전용 채팅방으로 바로 이동
        final chatRoom = await _createEventChatRoom(event, userId, userName);
        
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        if (chatRoom != null) {
          Navigator.of(context).pop(); // 이벤트 상세 다이얼로그 닫기
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatRoom: chatRoom),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('채팅방을 찾을 수 없습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 2. 새로운 참여 시도
      final joinSuccess = await _eventService.joinEvent(event.id, userId, userName);
      
      if (!joinSuccess) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이벤트 참여에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 3. 이벤트 전용 채팅방 생성
      final chatRoom = await _createEventChatRoom(event, userId, userName);
      
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      
      if (chatRoom != null) {
        // 4. 채팅방으로 이동
        Navigator.of(context).pop(); // 이벤트 상세 다이얼로그 닫기
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
        
        _loadEvents(); // 목록 새로고침
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('채팅방 생성에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      print('이벤트 참여 중 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 이벤트 전용 채팅방 생성
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
      
      print('이벤트 채팅방 생성 완료: ${chatRoom.id} (isEventRoom: ${chatRoom.isEventRoom})');
      return chatRoom;
    } catch (e) {
      print('이벤트 채팅방 생성 실패: $e');
      // 이미 존재하는 채팅방일 수 있으므로 기본 ChatRoom 객체 반환
      if (e.toString().contains('already exists') || e.toString().contains('ALREADY_EXISTS')) {
        final chatRoom = ChatRoom(
          id: 'event_chat_${event.id}',
          locationName: '${event.type.icon} ${event.title} (${event.locationName})',
          latitude: event.latitude,
          longitude: event.longitude,
          createdAt: DateTime.now(),
          userCount: 1,
          lastMessageAt: DateTime.now(),
          isEventRoom: true, // 이벤트 채팅방으로 표시
        );
        print('기존 이벤트 채팅방 사용: ${chatRoom.id} (isEventRoom: ${chatRoom.isEventRoom})');
        return chatRoom;
      }
      return null;
    }
  }
} 