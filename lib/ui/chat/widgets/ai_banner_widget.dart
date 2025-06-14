import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../service/ai_banner_service.dart';

class AiBannerWidget extends StatefulWidget {
  final String locationName;
  final VoidCallback? onTap;

  const AiBannerWidget({
    super.key,
    required this.locationName,
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
            SizedBox(
              width: double.infinity,
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
      ),
    );
  }
} 