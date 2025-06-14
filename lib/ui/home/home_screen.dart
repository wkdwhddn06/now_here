import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/chat_room.dart';
import '../../service/chat_room_service.dart';
import '../../service/location_service.dart';
import '../widgets/section_header.dart';
import '../widgets/state_widgets.dart';
import 'widgets/chat_room_list_section.dart';
import 'widgets/nearest_chat_preview_list.dart';
import 'widgets/location_events_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatRoomService _chatRoomService = ChatRoomService();
  final LocationService _locationService = LocationService();
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  String _error = '';
  List<ChatRoom> _nearestRooms = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCurrentLocation();
    await Future.wait([
      _loadChatRooms(),
      _loadNearestRooms(),
    ]);
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('현재 위치 로드 실패: $e');
    }
  }

  Future<void> _loadChatRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final chatRooms = await _chatRoomService.getChatRooms();
      
      // 이벤트 채팅방 필터링 (isEventRoom이 false인 것만)
      final filteredChatRooms = chatRooms
          .where((room) => !room.isEventRoom)
          .toList();
      
      print('전체 채팅룸: ${chatRooms.length}개, 일반 채팅룸: ${filteredChatRooms.length}개');
      
      setState(() {
        _chatRooms = filteredChatRooms.reversed.toList(); // 오래된 것부터 표시하도록 역순으로 변경
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '채팅룸을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  Future<void> _loadNearestRooms() async {
    if (_currentPosition == null) {
      setState(() {
        _nearestRooms = [];
      });
      return;
    }

    try {
      final nearestRooms = await _chatRoomService.getNearestChatRoomsWithPosition(
        position: _currentPosition!,
        limit: 10, // 이벤트 채팅방 필터링을 고려해 더 많이 가져옴
      );
      
      // 이벤트 채팅방 필터링 (isEventRoom이 false인 것만)
      final filteredRooms = nearestRooms
          .where((room) => !room.isEventRoom)
          .take(3) // 필터링 후 3개만 선택
          .toList();
      
      print('전체 근처 채팅룸: ${nearestRooms.length}개, 일반 채팅룸: ${filteredRooms.length}개');
      
      setState(() {
        _nearestRooms = filteredRooms;
      });
    } catch (e) {
      print('가장 가까운 채팅룸들 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.deepPurple,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        '지금, 여기',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // 가장 가까운 채팅룸들 미리보기
                NearestChatPreviewList(
                  nearestRooms: _nearestRooms,
                  currentPosition: _currentPosition,
                ),
                
                // 실시간 위치 이벤트 섹션
                LocationEventsSection(
                  currentPosition: _currentPosition,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: '무슨 이야기를 하고 있을까요?'),
                    ],
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: ChatRoomListSection(
                    chatRooms: _chatRooms,
                    isLoading: _isLoading,
                    error: _error,
                    onRetry: _loadChatRooms,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const SectionHeader(
                        title: '다른 기능들',
                        isSecondary: true,
                      ),
                      const SizedBox(height: 16),
                      const ComingSoonSection(),
                    ],
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 