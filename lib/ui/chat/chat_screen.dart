import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/chat_room.dart';
import '../../data/chat_message_realtime.dart';
import '../../service/chat_service_realtime.dart';
import '../../service/user_service.dart';
import '../widgets/state_widgets.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final bool isPreviewMode; // 미리보기 모드 추가

  const ChatScreen({
    super.key,
    required this.chatRoom,
    this.isPreviewMode = false, // 기본값은 false
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatServiceRealtime _chatService = ChatServiceRealtime();
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  
  late AnonymousUser _currentUser;
  List<ChatMessageRealtime> _messages = [];
  StreamSubscription<List<ChatMessageRealtime>>? _messagesSubscription;
  StreamSubscription<int>? _participantCountSubscription;
  
  bool _isLoading = true;
  int _participantCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _participantCountSubscription?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    _leaveChatRoom();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    // 전역 사용자 정보 사용
    _currentUser = _userService.currentUser;
    print('채팅방 입장: ${_currentUser.name} (${_currentUser.id})');
    
    // 미리보기 모드가 아닐 때만 채팅룸 입장
    if (!widget.isPreviewMode) {
      final joinSuccess = await _chatService.joinChatRoom(
        chatRoomId: widget.chatRoom.id!,
        userId: _currentUser.id,
        userName: _currentUser.name,
      );

      if (!joinSuccess) {
        _showError('채팅룸 입장에 실패했습니다.');
        return;
      }
    }

    // 메시지 스트림 구독
    _messagesSubscription = _chatService
        .getMessagesStream(widget.chatRoom.id!)
        .listen(
      (messages) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      },
      onError: (error) {
        _showError('메시지를 불러오는데 실패했습니다: $error');
      },
    );

    // 참여자 수 스트림 구독
    _participantCountSubscription = _chatService
        .getParticipantCountStream(widget.chatRoom.id!)
        .listen(
      (count) {
        setState(() {
          _participantCount = count;
        });
      },
    );
  }

  Future<void> _leaveChatRoom() async {
    // 미리보기 모드가 아닐 때만 채팅룸 나가기
    if (!widget.isPreviewMode) {
      await _chatService.leaveChatRoom(
        chatRoomId: widget.chatRoom.id!,
        userId: _currentUser.id,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    final success = await _chatService.sendMessage(
      chatRoomId: widget.chatRoom.id!,
      userId: _currentUser.id,
      userName: _currentUser.name,
      message: message,
    );

    if (!success) {
      _showError('메시지 전송에 실패했습니다.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 🎪 GEM 접속 버튼 UI
  Widget _buildGemAccessButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2d2d2d),
        border: Border(
          top: BorderSide(
            color: Color(0xFF444444),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.orange[300],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '지금은 구경하는 중!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onGemAccessPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700), // 골드 색상
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.diamond,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '1 GEM으로 채팅방 입장하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  // 🎪 GEM 버튼 클릭 처리 (현재는 데모용)
  void _onGemAccessPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d2d2d),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.diamond,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'GEM 사용',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          '1 GEM을 사용하여 이 채팅방에 입장하시겠습니까?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _useGemAndEnterChat();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('입장하기'),
          ),
        ],
      ),
    );
  }

  // GEM을 사용하여 채팅방에 입장
  void _useGemAndEnterChat() {
    // GEM 사용 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.diamond,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text('1 GEM을 사용하여 채팅방에 입장했습니다!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // 채팅방 입장 처리
    setState(() {
      // 미리보기 모드 해제하여 채팅 입력 활성화
      // isPreviewMode는 부모에서 전달받는 값이므로 직접 변경할 수 없지만
      // 새로운 ChatScreen으로 교체
    });

    // 실제 채팅 화면으로 교체 (미리보기 모드 해제)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoom: widget.chatRoom,
          isPreviewMode: false, // 미리보기 모드 해제
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.chatRoom.locationName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_participantCount명 참여중',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2d2d2d),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          widget.isPreviewMode 
            ? _buildGemAccessButton() // 미리보기 모드일 때 GEM 버튼
            : ChatInput( // 일반 모드일 때 채팅 입력
                controller: _messageController,
                onSend: _sendMessage,
              ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const LoadingState();
    }

    if (_messages.isEmpty) {
      return const EmptyState(
        message: '아직 메시지가 없습니다.\n첫 번째 메시지를 보내보세요!',
        icon: Icons.message_outlined,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.userId == _currentUser.id;
        
        // 메시지 그룹핑 로직
        final groupInfo = _getMessageGroupInfo(index);
        
        return MessageBubble(
          message: message,
          isMe: isMe,
          isFirstInGroup: groupInfo.isFirst,
          isLastInGroup: groupInfo.isLast,
          showTimestamp: groupInfo.showTimestamp,
        );
      },
    );
  }

  MessageGroupInfo _getMessageGroupInfo(int index) {
    final currentMessage = _messages[index];
    
    // 이전 메시지와 다음 메시지 확인
    final previousMessage = index > 0 ? _messages[index - 1] : null;
    final nextMessage = index < _messages.length - 1 ? _messages[index + 1] : null;
    
    // 같은 사용자인지 확인 (5분 이내)
    bool isSameUserAsPrevious = false;
    bool isSameUserAsNext = false;
    
    if (previousMessage != null) {
      final timeDiff = currentMessage.timestamp - previousMessage.timestamp;
      isSameUserAsPrevious = previousMessage.userId == currentMessage.userId && 
                           timeDiff < 5 * 60 * 1000; // 5분
    }
    
    if (nextMessage != null) {
      final timeDiff = nextMessage.timestamp - currentMessage.timestamp;
      isSameUserAsNext = nextMessage.userId == currentMessage.userId &&
                        timeDiff < 5 * 60 * 1000; // 5분
    }
    
    // 그룹 정보 결정
    final isFirst = !isSameUserAsPrevious;
    final isLast = !isSameUserAsNext;
    
    // 시간 표시: 마지막 메시지이거나, 다음 사용자가 다르거나, 시간 간격이 클 때
    bool showTimestamp = isLast || index == _messages.length - 1;
    if (nextMessage != null && nextMessage.userId == currentMessage.userId) {
      final timeDiff = nextMessage.timestamp - currentMessage.timestamp;
      showTimestamp = timeDiff > 5 * 60 * 1000; // 5분 이상 차이나면 시간 표시
    }
    
    return MessageGroupInfo(
      isFirst: isFirst,
      isLast: isLast,
      showTimestamp: showTimestamp,
    );
  }
}

class MessageGroupInfo {
  final bool isFirst;
  final bool isLast;
  final bool showTimestamp;
  
  MessageGroupInfo({
    required this.isFirst,
    required this.isLast,
    required this.showTimestamp,
  });
} 