import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../service/ai_banner_service.dart';
import '../../../service/ai_event_service.dart';
import '../../../service/location_event_service.dart';
import '../../../service/chat_room_service.dart';
import '../../../service/chat_service_realtime.dart';
import '../../../service/user_service.dart';
import '../../../data/location_event.dart';
import '../../../data/chat_room.dart';
import '../chat_screen.dart';

class AiBannerWidget extends StatefulWidget {
  final String locationName;
  final String chatRoomId;
  final VoidCallback? onTap;

  const AiBannerWidget({
    super.key,
    required this.locationName,
    required this.chatRoomId,
    this.onTap,
  });

  @override
  State<AiBannerWidget> createState() => _AiBannerWidgetState();
}

class _AiBannerWidgetState extends State<AiBannerWidget> {
  final AiBannerService _bannerService = AiBannerService();
  BannerAd? _currentBanner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    try {
      // 하나의 배너만 생성
      final banner = await _bannerService.generateLocationBanner(widget.locationName);
      
      setState(() {
        _currentBanner = banner;
        _isLoading = false;
      });
    } catch (e) {
      print('배너 로딩 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingBanner();
    }

    if (_currentBanner == null) {
      return const SizedBox.shrink();
    }

    return _buildBanner(_currentBanner!);
  }

  Widget _buildLoadingBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(
              'AI로 맞춤 광고를 불러오는 중...',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BannerAd banner) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? () => _showBannerDetails(banner),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  banner.backgroundColor,
                  banner.backgroundColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: banner.backgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // 배경 패턴
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // 메인 콘텐츠
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 아이콘
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconData(banner.icon),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 텍스트 콘텐츠
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 가게 이름
                            Text(
                              banner.storeName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // 제목
                            Text(
                              banner.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // 부제목
                            Text(
                              banner.subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // 할인 표시 + CTA 버튼
                      Column(
                        children: [
                          // 할인 표시
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              banner.discount,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // CTA 버튼
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              banner.callToAction,
                              style: TextStyle(
                                color: banner.backgroundColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'local_see':
        return Icons.local_see;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'explore':
        return Icons.explore;
      case 'local_offer':
        return Icons.local_offer;
      case 'store':
        return Icons.store;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'hotel':
        return Icons.hotel;
      case 'cut':
        return Icons.content_cut;
      case 'place':
      default:
        return Icons.place;
    }
  }

  void _showBannerDetails(BannerAd banner) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconData(banner.icon),
                  color: banner.backgroundColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        banner.category,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              banner.subtitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              banner.description,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // 사장님 메시지
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💬 사장님 한마디',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.ownerMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 영업 정보
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  banner.businessInfo,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // 같이 하기 버튼
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createEventFromBanner(banner),
                    icon: const Icon(Icons.group_add),
                    label: const Text('같이 하기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 기존 액션 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: banner.backgroundColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      banner.callToAction,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createEventFromBanner(BannerAd banner) async {
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text(
                      'AI로 이벤트를 생성하는 중...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final aiEventService = AiEventService();
      final locationEventService = LocationEventService();
      final chatService = ChatServiceRealtime();
      final userService = UserService();

      // AI를 통해 LocationEvent 생성
      final eventId = await aiEventService.generateLocationEventFromBanner(
        banner,
        userService.currentUser.id,
        userService.currentUser.name,
      );

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      if (eventId != null) {
        // 생성된 이벤트 정보 가져오기
        final events = await locationEventService.getNearbyEvents();
        final createdEvent = events.firstWhere(
          (event) => event.id == eventId,
          orElse: () => throw Exception('생성된 이벤트를 찾을 수 없습니다'),
        );
        
        // 채팅방에 LocationEvent 메시지 공유
        final shareSuccess = await chatService.shareLocationEvent(
          chatRoomId: widget.chatRoomId,
          userId: userService.currentUser.id,
          userName: userService.currentUser.name,
          eventId: eventId,
          eventTitle: createdEvent.title,
        );
        
        if (shareSuccess) {
          // 성공 메시지와 함께 모달 닫기
          Navigator.pop(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${createdEvent.title} 이벤트가 생성되어 채팅방에 공유되었습니다!',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          _showErrorMessage('이벤트는 생성되었지만 채팅방 공유에 실패했습니다.');
        }
      } else {
        _showErrorMessage('이벤트 생성에 실패했습니다.');
      }
    } catch (e) {
      // 로딩 다이얼로그가 열려있으면 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      _showErrorMessage('이벤트 생성 중 오류가 발생했습니다: $e');
    }
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
                            color: _getEventColor(event.type).withOpacity(0.2),
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
                        _buildInfoChip(
                          icon: Icons.people,
                          text: '${event.participantIds.length}/${event.maxParticipants}명',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoChip(
                          icon: Icons.access_time,
                          text: event.timeLeftString,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _joinEvent(event),
                        icon: const Icon(Icons.group_add),
                        label: const Text('참여하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getEventColor(event.type),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinEvent(LocationEvent event) async {
    try {
      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      final locationEventService = LocationEventService();
      final chatRoomService = ChatRoomService();
      final userService = UserService();
      
      final userId = userService.currentUser.id;
      final userName = userService.currentUser.name;

      print('이벤트 참여 시도: ${event.title}, 사용자: $userName ($userId)');

      // 1. 먼저 이미 참여했는지 확인
      final isAlreadyParticipating = await locationEventService.isUserParticipating(event.id, userId);
      
      if (isAlreadyParticipating) {
        print('이미 참여한 이벤트입니다. 채팅방으로 이동합니다.');
        
        // 이벤트 전용 채팅방으로 바로 이동
        final chatRoom = await _createEventChatRoom(event, userId, userName);
        
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        
        if (chatRoom != null) {
          Navigator.of(context).pop(); // 이벤트 상세 다이얼로그 닫기
          Navigator.of(context).pop(); // 배너 모달 닫기
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
      final joinSuccess = await locationEventService.joinEvent(event.id, userId, userName);
      
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
        Navigator.of(context).pop(); // 배너 모달 닫기
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: chatRoom),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${event.title} 이벤트에 참여했습니다!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
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
      final chatRoomService = ChatRoomService();
      
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
      await chatRoomService.createChatRoom(chatRoom);
      
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
} 