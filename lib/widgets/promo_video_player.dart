import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// [수정] video_player -> youtube_player_iframe
class PromoVideoPlayer extends StatefulWidget {
  final String youtubeVideoId;
  const PromoVideoPlayer({super.key, required this.youtubeVideoId});

  @override
  State<PromoVideoPlayer> createState() => _PromoVideoPlayerState();
}

class _PromoVideoPlayerState extends State<PromoVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.youtubeVideoId,
      autoPlay: false, // 자동 재생 금지 (iOS 정책)
      params: const YoutubePlayerParams(
        showControls: true, // 유튜브 기본 컨트롤러 표시
        showFullscreenButton: true,
        mute: false,
        loop: true, //// 반복 재생
      ),

    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Card로 감싸서 둥근 모서리 적용
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.transparent,
      child: YoutubePlayer(
        controller: _controller,
        // 16:9 비율을 기본으로 함
        aspectRatio: 16 / 9,
      ),
    );
  }
}