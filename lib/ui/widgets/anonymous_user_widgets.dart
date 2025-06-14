import 'package:flutter/material.dart';
import '../../data/chat_message_realtime.dart';

// 🎨 AnonymousUser 이름 표시 위젯
class AnonymousUserName extends StatelessWidget {
  final String? userId;
  final String? userName;
  final double fontSize;
  final FontWeight fontWeight;
  final bool showGradient;

  const AnonymousUserName({
    super.key,
    this.userId,
    this.userName,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    if (userName != null && userName!.isNotEmpty) {
      return Text(
        userName!,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      );
    }

    final anonymousUser = AnonymousUser.generate(userId);

    if (showGradient) {
      return ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [anonymousUser.primaryColor, anonymousUser.secondaryColor],
        ).createShader(bounds),
        blendMode: BlendMode.srcIn, // 이 부분이 중요!
        child: Text(
          anonymousUser.name,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: Colors.white, // ShaderMask가 이 색상을 덮어씁니다
          ),
        ),
      );
    }

    return Text(
      anonymousUser.name,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: anonymousUser.primaryColor,
        shadows: [
          Shadow(
            offset: const Offset(0, 1),
            blurRadius: 2,
            color: anonymousUser.secondaryColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// 🌟 AnonymousUser 아바타 위젯
class AnonymousUserAvatar extends StatelessWidget {
  final String? userId;
  final double size;
  final bool showBorder;

  const AnonymousUserAvatar({
    super.key,
    this.userId,
    this.size = 32,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final anonymousUser = AnonymousUser.generate(userId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: anonymousUser.primaryColor, // 단색으로 변경
        border: showBorder
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Center(
        child: Text(
          anonymousUser.avatar.substring(0, 1).toUpperCase(), // 첫 글자만 대문자로
          style: TextStyle(
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// 🎭 AnonymousUser 카드 위젯
class AnonymousUserCard extends StatelessWidget {
  final String? userId;
  final String? userName;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AnonymousUserCard({
    super.key,
    this.userId,
    this.userName,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (userName != null && userName!.isNotEmpty) {
      return Card(
        color: const Color(0xFF2d2d2d),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            userName!,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          trailing: trailing,
          onTap: onTap,
        ),
      );
    }

    final anonymousUser = AnonymousUser.generate(userId);

    return Card(
      color: const Color(0xFF2d2d2d),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: anonymousUser.primaryColor.withOpacity(0.1), // 단색 배경
          border: Border.all(
            color: anonymousUser.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ListTile(
          leading: AnonymousUserAvatar(userId: userId),
          title: AnonymousUserName(userId: userId, userName: null),
          subtitle: Text(
            '${anonymousUser.personality} · ${_formatTime(anonymousUser.createdAt)}',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }
}

// 🌈 AnonymousUser 치킷치킷한 이름 표시 (애니메이션 포함)
class AnonymousUserAnimatedName extends StatefulWidget {
  final String? userId;
  final String? userName;

  const AnonymousUserAnimatedName({
    super.key,
    this.userId,
    this.userName,
  });

  @override
  State<AnonymousUserAnimatedName> createState() => _AnonymousUserAnimatedNameState();
}

class _AnonymousUserAnimatedNameState extends State<AnonymousUserAnimatedName>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: AnonymousUserName(
              userId: widget.userId,
              userName: widget.userName,
              showGradient: true,
            ),
          ),
        );
      },
    );
  }
} 