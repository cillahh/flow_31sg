import 'dart:async'; // [추가] Timer 사용을 위해 import
// import 'package:election_campaign_web/services/guestbook_service.dart';
import '../main.dart'; // 패키지 경로로 수정
import '../util.dart';
import '../widgets/mobile_layout_wrapper.dart'; // 패키지 경로로 수정
import '../widgets/contact_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:marquee/marquee.dart';

// [수정] StatelessWidget -> StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //HeroSection
  final PageController _pageController = PageController();
  bool _isMissionExpanded = false;

  late final Timer _timer; // 자동 슬라이드를 위한 타이머
  int _currentPage = 0; // 현재 페이지 인덱스

  final AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer.newPlayer();
  bool _isPlaying = false; // 재생 상태 추적 (기본값 false)

  // [추가] 오디오가 최초로 로드되었는지 추적
  bool _isAudioInitialized = false;

  // [추가] 이스터에그 상태 변수
  bool _isMascotVisible = false;
  String _mascotImagePath = 'assets/images/mascot_union.gif';
  Timer? _mascotTimer;

  bool _isKorean = true; // true: KOR, false: ENG

  final String audioIcon = '아이콘을 눌러 배경음악을 재생해보세요!';

  final List<String> _heroImages = [
    'https://firebasestorage.googleapis.com/v0/b/flow-7049f.firebasestorage.app/o/banner1.jpg?alt=media&token=bbdea87b-1bac-4373-b01f-6c3426c290fd',
    'https://firebasestorage.googleapis.com/v0/b/flow-7049f.firebasestorage.app/o/banner2.jpg?alt=media&token=0e9d47cc-937a-421e-8998-abee0d3f0b67',
  ];

  final String _showcaseKey = 'hasSeenAudioShowcase_vv0';

  // [추가] 스크롤 제어를 위한 GlobalKey
  final GlobalKey _scrollKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_heroImages.isEmpty) return; // 이미지가 없으면 타이머 작동 안 함

      if (_currentPage < _heroImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0; // 마지막 이미지에 도달하면 처음으로 돌아감
      }

      // 애니메이션 효과로 페이지 넘김
      _pageController.jumpToPage(
        _currentPage,
        // duration: const Duration(milliseconds: 400),
        // curve: Curves.easeIn,
      );
    });
  }

  // void _toggleLanguage() {
  //   setState(() {
  //     _isKorean = !_isKorean;
  //     // TODO: 여기에 실제 언어 변경 로직(i18n)을 연결해야 합니다.
  //     // 예: context.setLocale(_isKorean ? Locale('ko') : Locale('en'));
  //     debugPrint("언어 변경: ${_isKorean ? 'KOR' : 'ENG'}");
  //   });
  // }

  void _togglePlayPause() async {
    // (최초 클릭)
    if (!_isAudioInitialized) {
      try {
        await _assetsAudioPlayer.open(
          Audio.network(
            "https://firebasestorage.googleapis.com/v0/b/flow-7049f.firebasestorage.app/o/flow_song.mp3?alt=media&token=69808dbb-ae19-4de7-98df-0b9d12303ea5",
          ),
          loopMode: LoopMode.single,
          autoStart: true,
          showNotification: false,
        );

        _assetsAudioPlayer.isPlaying.listen((isPlaying) {
          if (mounted) {
            setState(() {
              _isPlaying = isPlaying;
            });
          }
        });

        setState(() {
          _isAudioInitialized = true;
        });
      } catch (t) {
        debugPrint("오디오 재생 실패: $t");
      }
    } else {
      //이미 초기화된 경우, 재생/정지만 토글
      _assetsAudioPlayer.playOrPause();
    }
  }

  @override
  void dispose() {
    _assetsAudioPlayer.dispose();
    _mascotTimer?.cancel();
    _timer.cancel();
    super.dispose();
  }

  void _showMascot(String imagePath) {
    _mascotTimer?.cancel();
    setState(() {
      _mascotImagePath = imagePath;
      _isMascotVisible = true;
    });
    _mascotTimer = Timer(const Duration(milliseconds: 1500), () {
      setState(() {
        _isMascotVisible = false;
      });
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = kPrimaryColor;
    final Color backgroundColor = kBackgroundColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white24.withAlpha(200),
        elevation: 0,
        title: Text(
          'FLOW',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'HelveticaRounded',
            fontSize: 25 * Util.getScaleHeight(context), // [수정]
            color: kPrimaryColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _togglePlayPause,
            icon: Icon(
              _isPlaying ? Icons.volume_up_sharp : Icons.volume_off_sharp,
            ),
          ),
          SizedBox(
            width: 17 * Util.getScaleHeight(context), // [유지] 너비 간격
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 기존 스크롤 콘텐츠 (맨 아래)
          SingleChildScrollView(
            key: _scrollKey, // 스크롤 키
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 70 * Util.getScaleHeight(context)),
                MobileLayoutWrapper(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0 * Util.getScaleHeight(context),
                    ),
                    // [유지] 너비 간격
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 10 * Util.getScaleHeight(context)),
                        // [유지] 높이 간격
                        _buildHeroSection(context),
                        SizedBox(height: 20 * Util.getScaleHeight(context)),
                        _buildMissionSection(context),
                        SizedBox(height: 20 * Util.getScaleHeight(context)),
                        // [유지] 높이 간격
                        Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildSectionTitle(
                                      context,
                                      "🌊 FLOW 소식",
                                      "캠프의 최신 소식을 확인하세요.",
                                    ),
                                  ],
                                ),
                                _buildLinksCard(context),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Image.asset(
                                  // [수정] getScaleWidth -> getScaleHeight
                                  height: 90 * Util.getScaleHeight(context),
                                  'assets/images/flongnews.png',
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                          ],
                        ),
                        // SizedBox(height: 30 * Util.getScaleHeight(context)),
                        // _buildLogoSection(context),
                        SizedBox(height: 30 * Util.getScaleHeight(context)),
                        // [유지] 높이 간격

                        // [유지] 높이 간격
                        Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  context,
                                  "🌊 FLOW의 4대 가치",
                                  "하나님의 일하심이 흘러가는 4가지 통로",
                                ),
                                _buildCategoryGrid(context),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '  *가치 카드를 터치해 보세요!',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: kPrimaryColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30 * Util.getScaleHeight(context)),
                        // [유지] 높이 간격
                        Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(
                                  context,
                                  "🌊 FLOW의 3대 비전",
                                  "우리의 삶과 공동체 가운데 흘러갈 비전",
                                ),
                                _buildVisionSection(context),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Image.asset(
                                  // [수정] getScaleWidth -> getScaleHeight
                                  height: 80 * Util.getScaleHeight(context),
                                  'assets/images/flong.png',
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 30 * Util.getScaleHeight(context)),
                        // [유지] 높이 간격
                        // _buildPledgeTestCard(context),
                        // SizedBox(height: 30 * Util.getScaleHeight(context)), // [유지] 높이 간격
                      ],
                    ),
                  ),
                ),
                _buildFooter(context, primaryColor),
              ],
            ),
          ),

          // 2. 뒷배경 어둡게 처리 (Dimming Layer)
          IgnorePointer(
            ignoring: !_isMascotVisible,
            child: AnimatedOpacity(
              opacity: _isMascotVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                color: Colors.black.withOpacity(0.5), // 30% 불투명
              ),
            ),
          ),

          // 3. [수정] 이스터에그 마스코트 (AnimatedScale 사용)
          Center(
            child: AnimatedScale(
              scale: _isMascotVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: _isMascotVisible ? Curves.elasticOut : Curves.easeIn,
              child: IgnorePointer(
                ignoring: !_isMascotVisible,
                child: Image.asset(
                  _mascotImagePath,
                  width: 300 * Util.getScaleHeight(context), // [수정]
                  height: 300 * Util.getScaleHeight(context), // [수정]
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. 히어로 섹션 (후보 포스터 통합) ---
  Widget _buildHeroSection(BuildContext context) {
    // 600:90 비율 계산 (약 6.66)
    const double imageAspectRatio = 600 / 90;

    if (_heroImages.isEmpty) {
      return AspectRatio(
        // SizedBox 대신 비율 유지 위젯 사용
        aspectRatio: imageAspectRatio,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          color: Colors.transparent,
          child: Container(
            color: Colors.grey[300],
            child: const Center(child: Text('이미지를 불러오는 중입니다.')),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: imageAspectRatio, // 너비에 맞춰 높이를 600:90 비율로 자동 설정
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _heroImages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                color: Colors.transparent,
                margin: EdgeInsets.zero,
                // 카드 기본 마진 제거 (비율 딱 맞추기 위해)
                child: FadeInImage(
                  placeholder: const AssetImage(
                    'assets/images/placeholder.gif',
                  ),
                  image: NetworkImage(_heroImages[index]),
                  fit: BoxFit.cover,
                  // 비율이 딱 맞으므로 cover 사용
                  fadeInDuration: const Duration(milliseconds: 200),
                  fadeOutDuration: const Duration(milliseconds: 100),
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // 하단 인디케이터
          // Positioned(
          //   bottom: 8 * Util.getScaleHeight(context),
          //   left: 0,
          //   right: 0,
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: List.generate(_heroImages.length, (index) {
          //       return Container(
          //         width: 6.0 * Util.getScaleHeight(context),
          //         height: 6.0 * Util.getScaleHeight(context),
          //         margin: EdgeInsets.symmetric(horizontal: 4.0 * Util.getScaleHeight(context)),
          //         decoration: BoxDecoration(
          //           shape: BoxShape.circle,
          //           color:
          //               _currentPage == index
          //                   ? Colors.white
          //                   : Colors.white.withOpacity(0.4),
          //         ),
          //       );
          //     }),
          //   ),
          // ),
        ],
      ),
    );
  }

  // --- 1. 로고 섹션 (메인 로고) ---
  Widget _buildLogoSection(BuildContext context) {
    const double imageAspectRatio = 600 / 90;
    return AspectRatio(
      aspectRatio: imageAspectRatio,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: Colors.transparent, // 흰색 배경에 카드 그림자가 없도록
        child: FadeInImage(
          placeholder: AssetImage('assets/images/placeholder.gif'),
          // 1x1 투명 플레이스홀더
          image: NetworkImage(
            'https://firebasestorage.googleapis.com/v0/b/flow-7049f.firebasestorage.app/o/mainLogo.jpg?alt=media&token=05471e85-cfe0-4984-8af0-4e2d04d00acb',
          ),
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
        ),
      ),
    );
  }

  // --- [신규] 1.5. 핵심 정체성 (Mission) ---
  Widget _buildMissionSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: kPrimaryColor.withOpacity(0.05),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(24.0 * Util.getScaleHeight(context)), // [수정]
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "하나님의 FLOW가 한동의 FLOW가 되길 소망하는, 기호 3번 FLOW",
              style: TextStyle(
                fontFamily: 'HelveticaRounded',
                fontWeight: FontWeight.w700,
                color: kPrimaryColor,
                fontSize: 20 * Util.getScaleHeight(context), // [수정]
              ),
            ),
            SizedBox(height: 16 * Util.getScaleHeight(context)), // [수정]
            SizedBox(
              height: 24 * Util.getScaleHeight(context), // [중요] 흐르는 텍스트의 높이 제한
              child: Marquee(
                text:
                    "“내가 주는 물을 마시는 자는 영원히 목마르지 아니하리니 내가 주는 물은 그 속에서 영생하도록 솟아나는 샘물이 되리라” (요한복음 4:14)",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
                scrollAxis: Axis.horizontal,
                // 가로로 흐름
                crossAxisAlignment: CrossAxisAlignment.center,
                blankSpace: 50.0,
                // 텍스트가 한 바퀴 돌고 다음 텍스트가 나올 때까지의 여백
                velocity: 50.0,
                // 흐르는 속도 (클수록 빠름)
                pauseAfterRound: const Duration(seconds: 1),
                // 한 바퀴 돌고 잠시 멈춤
                startPadding: 10.0,
                // 시작할 때 약간의 여백
                accelerationDuration: const Duration(seconds: 1),
                // 처음에 부드럽게 출발
                accelerationCurve: Curves.linear,
                decelerationDuration: const Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),
            SizedBox(height: 16 * Util.getScaleHeight(context)), // [수정]
            const Divider(height: 1),
            SizedBox(height: 16 * Util.getScaleHeight(context)), // [수정]
            AnimatedSize(
              // 부드럽게 열리고 닫히는 애니메이션 효과
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Column(
                children: [
                  Text(
                    "한동의 지난 30년은 하나님의 일하심의 역사였습니다. 이제 한동은 새로운 변화의 다음 30년을 준비하는 전환점에 서 있습니다.\n\n제31대 총학생회 후보 ‘FLOW’는 이 시기에 하나님께서 행하실 일을 “예비하고, 드러내며, 흘려보내는” 총학생회가 되고자 합니다. ‘FLOW’의 핵심은 하나님의 일하심을 준비하고, 드러내며, 흘려보내는 것입니다. 우리는 공동체의 연합을 통해 새로운 변화를 일으키며, 하나님의 때와 방법 속에서 한동의 정체성을 새롭게 세워갈 것입니다.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Colors.black87,
                      fontSize: 12 * Util.getScaleHeight(context),
                    ),
                    maxLines: _isMissionExpanded ? null : 4,
                    overflow:
                        _isMissionExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // --- [더보기 / 접기 버튼] ---
            // SizedBox(height: 8 * Util.getScaleHeight(context)), // 텍스트와 버튼 사이 간격
            GestureDetector(
              onTap: () {
                setState(() {
                  _isMissionExpanded = !_isMissionExpanded; // 상태 토글
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // 버튼 중앙 정렬
                children: [
                  Text(
                    _isMissionExpanded ? "접기" : "더 보기",
                    style: TextStyle(
                      fontSize: 12 * Util.getScaleHeight(context),
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _isMissionExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 18 * Util.getScaleHeight(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 섹션 제목 헬퍼 ---
  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: Colors.black87,
      fontFamily: 'HelveticaRounded',
    );

    final subtitleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.black54,
      fontSize: 11.5,
    ); // [수정]

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle?.copyWith(
            fontSize:
                (titleStyle.fontSize ?? 22) *
                Util.getScaleHeight(context), // [수정]
          ),
        ),
        SizedBox(height: 3 * Util.getScaleHeight(context)), // [수정]
        Text(
          subtitle,
          style: subtitleStyle?.copyWith(
            fontSize:
                (subtitleStyle.fontSize ?? 11.5) *
                Util.getScaleHeight(context), // [수정]
          ),
        ),
        SizedBox(height: 15 * Util.getScaleHeight(context)), // [수정]
      ],
    );
  }

  // --- [수정] 2. 4대 가치 (CategoryGrid) ---
  Widget _buildCategoryGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                context: context,
                icon: Icons.groups_outlined,
                // 연합
                title: "연합",
                subtitle: "한동 공동체의 연합을 통해 완성될 하나님의 FLOW",
                color: Colors.orange.shade700,
                onTap:
                    () => _showMascot(
                      'assets/images/mascot_union.gif',
                    ), // 연합 마스코트
              ),
            ),
            SizedBox(width: 16 * Util.getScaleHeight(context)), // [유지] 너비 간격
            Expanded(
              child: _buildCategoryCard(
                context: context,
                icon: Icons.handshake_outlined,
                // 동행
                title: "동행",
                subtitle: "하나님과 동행함을 통해 완성될 하나님의 FLOW",
                color: Colors.pink.shade600,
                onTap:
                    () => _showMascot(
                      'assets/images/mascot_accompaniment.gif',
                    ), // 동행 마스코트
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * Util.getScaleHeight(context)), // [유지] 높이 간격
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                context: context,
                icon: Icons.flag_outlined,
                // 사명
                title: "사명",
                subtitle: "각자의 사명을 통하여 완성될 하나님의 FLOW",
                color: Colors.green.shade700,
                onTap:
                    () => _showMascot(
                      'assets/images/mascot_mission.gif',
                    ), // 사명 마스코트
              ),
            ),
            SizedBox(width: 16 * Util.getScaleHeight(context)), // [유지] 너비 간격
            Expanded(
              child: _buildCategoryCard(
                context: context,
                icon: Icons.check_circle_outline,
                // 순종
                title: "순종",
                subtitle: "한 사람의 순종을 통하여 완성될 하나님의 FLOW",
                color: Colors.blue.shade800,
                onTap:
                    () => _showMascot(
                      'assets/images/mascot_obedience.gif',
                    ), // 순종 마스코트
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle, // 부제목 추가
    required Color color,
    required VoidCallback onTap,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: Colors.black54);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(20.0 * Util.getScaleHeight(context)), // [수정]
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32 * Util.getScaleHeight(context), color: color),
              // [수정]
              SizedBox(height: 12 * Util.getScaleHeight(context)),
              // [수정]
              Text(
                title,
                style: titleStyle?.copyWith(
                  fontSize:
                      (titleStyle.fontSize ?? 22) *
                      Util.getScaleHeight(context), // [수정]
                ),
              ),
              SizedBox(height: 4 * Util.getScaleHeight(context)),
              // [수정]
              Text(
                subtitle,
                style: subtitleStyle?.copyWith(
                  fontSize:
                      (subtitleStyle.fontSize ?? 12) *
                      Util.getScaleHeight(context), // [수정]
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- [신규] 3. 3대 비전 ---
  Widget _buildVisionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildVisionCard(
          context,
          title: "FLOW in Our Life",
          subtitle: "우리의 삶 가운데 흘러가기를",
          description:
              "하나님의 일하심이 한동인의 삶에 깊이 스며들길 소망합니다. 신앙이 생활이 되고, 배움이 예배가 되는 공동체를 세우겠습니다.",
        ),
        SizedBox(height: 16 * Util.getScaleHeight(context)), // [수정]
        _buildVisionCard(
          context,
          title: "FLOW in Handong",
          subtitle: "한동 가운데 흘러가기를",
          description:
              "한동의 시작처럼, 하나님께서 주신 흐름이 캠퍼스 안에 계속되길 바랍니다. 갈대상자가 물결에 흘러 하나님의 계획을 이뤘듯, 우리의 삶도 순종의 흐름이 되길 바랍니다. 그 속에서 서로를 존중하고 세워주는 공동체 문화를 만들어가겠습니다.",
        ),
        SizedBox(height: 16 * Util.getScaleHeight(context)), // [수정]
        _buildVisionCard(
          context,
          title: "FLOW in All Fields",
          subtitle: "모든 분야와 영역 가운데 흘러가기를",
          description:
              "배움의 울타리를 넘어 모든 분야와 영역 가운데서도 하나님의 뜻이 흘러가길 바랍니다. 각자의 자리에서 주님의 뜻을 실천하며, 세상 속에 하나님의 사랑을 전하는 한동인이 되도록 돕겠습니다.",
        ),
      ],
    );
  }

  Widget _buildVisionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: kPrimaryColor,
      fontWeight: FontWeight.w900,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.black54,
      fontStyle: FontStyle.italic,
    );
    final descStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.3, color: Colors.black87);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(10.0 * Util.getScaleHeight(context)), // [수정]
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: titleStyle?.copyWith(
                fontSize:
                    (titleStyle.fontSize ?? 22) *
                    Util.getScaleHeight(context), // [수정]
              ),
            ),
            Text(
              subtitle,
              style: subtitleStyle?.copyWith(
                fontSize:
                    (subtitleStyle.fontSize ?? 12) *
                    Util.getScaleHeight(context), // [수정]
              ),
            ),
            SizedBox(height: 16 * Util.getScaleHeight(context)), // [수정]
            Text(
              description,
              style: descStyle?.copyWith(
                fontSize:
                    (descStyle.fontSize ?? 12) *
                    Util.getScaleHeight(context), // [수정]
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. FLOW 소식 (LinksCard) ---
  Widget _buildLinksCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          15.0 * Util.getScaleHeight(context),
        ), // [수정]
        side: BorderSide(color: kPrimaryColor.withAlpha(100), width: 1.0),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 3 * Util.getScaleHeight(context), // [수정]
          ),
          _buildLinkListTile(
            context,
            icon: FontAwesomeIcons.instagram,
            title: "공식 인스타그램",
            subtitle: "가장 빠른 캠프 소식",
            onTap:
                () => _launchURL(
                  "https://www.instagram.com/flow_hgu?igsh=ZnBmcXY2NXl4b3J4",
                ),
            isHighlighted: false,
          ),
          Divider(
            height: 1 * Util.getScaleHeight(context), // [수정]
            indent: 72 * Util.getScaleHeight(context), // [유지] 너비 간격
            endIndent: 25 * Util.getScaleHeight(context), // [유지] 너비 간격
          ),
          _buildLinkListTile(
            context,
            icon: FontAwesomeIcons.solidEnvelope,
            // 아이콘 변경
            title: "문의 메일 보내기",
            // 타이틀 변경
            subtitle: "캠프에 의견을 보내주세요",
            // 부제목 변경
            onTap: () {
              // 팝업 띄우기
              showDialog(
                context: context,
                builder: (context) {
                  return const ContactDialog(); // lib/widgets/contact_dialog.dart
                },
              );
            },
            isHighlighted: false,
          ),
          Divider(
            height: 1 * Util.getScaleHeight(context), // [수정]
            indent: 72 * Util.getScaleHeight(context), // [유지] 너비 간격
            endIndent: 25 * Util.getScaleHeight(context), // [유지] 너비 간격
          ),
          _buildLinkListTile(
            context,
            icon: FontAwesomeIcons.solidFilePdf,
            title: "전체 공약집 PDF",
            subtitle: "상세한 공약 내용을 확인하세요",
            onTap:
                () => _launchURL(
                  "https://drive.google.com/file/d/1kMvLe1MQ4NsgLoMae_4dzAOH9CygiKfA/view?usp=sharing",
                ),
            isHighlighted: false,
          ),
          SizedBox(
            height: 3 * Util.getScaleHeight(context), // [수정]
          ),
        ],
      ),
    );
  }

  // --- 6. 공약 테스트 카드 ---
  Widget _buildPledgeTestCard(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor,
      clipBehavior: Clip.antiAlias,
      child: _buildLinkListTile(
        context,
        icon: Icons.quiz_outlined,
        title: "나에게 맞는 공약 찾기",
        subtitle: "간단한 테스트로 확인해보세요!",
        onTap: () => context.go('/admin-inquiries'),
        isHighlighted: true,
      ),
    );
  }

  // ListTile 헬퍼
  Widget _buildLinkListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    final Color contentColor = isHighlighted ? Colors.white : kPrimaryColor;
    final Color subtitleColor =
        isHighlighted ? Colors.white.withOpacity(0.9) : Colors.black54;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 30 * Util.getScaleHeight(context), // [유지] 너비 간격
        vertical: 10 * Util.getScaleHeight(context), // [유지] 높이 간격
      ),
      leading: Icon(
        icon,
        color: contentColor,
        size: 33 * Util.getScaleHeight(context),
      ),
      // [수정]
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isHighlighted ? Colors.white : Colors.black87,
          fontSize: 15 * Util.getScaleHeight(context), // [수정]
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isHighlighted ? Colors.white : Colors.black87,
          fontSize: 12 * Util.getScaleHeight(context), // [수정]
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16 * Util.getScaleHeight(context), // [수정]
        color: contentColor,
      ),
      onTap: onTap,
      horizontalTitleGap: 30 * Util.getScaleHeight(context), // [유지] 너비 간격
    );
  }

  // --- 7. 푸터 섹션 ---
  Widget _buildFooter(BuildContext context, Color primaryColor) {
    final bodySmallStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.black54);

    final footerTextStyle = TextStyle(
      color: Colors.black54,
      fontSize: 12 * Util.getScaleHeight(context), // [수정]
    );

    return Container(
      color: Colors.grey.shade100,
      // 흰색이 아닌 옅은 회색
      padding: EdgeInsets.symmetric(
        vertical: 40.0 * Util.getScaleHeight(context), // [유지] 높이 간격
        horizontal: 24.0 * Util.getScaleWidth(context), // [유지] 너비 간격
      ),
      margin: EdgeInsets.only(top: 32.0 * Util.getScaleHeight(context)),
      // [유지] 높이 간격
      child: MobileLayoutWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              "assets/images/logo_blue.png",
              width: 150 * Util.getScaleHeight(context), // [유지] 너비 간격
            ),
            Text(
              "제31대 총학생회 선거운동본부 기호 3번",
              style: bodySmallStyle?.copyWith(
                fontSize:
                    (bodySmallStyle.fontSize ?? 12) *
                    Util.getScaleHeight(context), // [수정]
              ),
            ),
            SizedBox(height: 24 * Util.getScaleHeight(context)), // [유지] 높이 간격
            Row(
              children: [
                _buildSocialIcon(
                  FontAwesomeIcons.instagram,
                  "https://www.instagram.com/flow_hgu?igsh=ZnBmcXY2NXl4b3J4",
                ),
                SizedBox(width: 20 * Util.getScaleHeight(context)),
                // [유지] 너비 간격
                _buildSocialIcon(
                  FontAwesomeIcons.solidFilePdf,
                  "https://drive.google.com/file/d/1kMvLe1MQ4NsgLoMae_4dzAOH9CygiKfA/view?usp=sharing",
                ),
              ],
            ),
            SizedBox(height: 32 * Util.getScaleHeight(context)), // [유지] 높이 간격
            Text(
              "© 2025 FLOW Election Campaign. All rights reserved.",
              style: footerTextStyle,
            ),
            SizedBox(height: 8 * Util.getScaleHeight(context)), // [유지] 높이 간격
            Text(
              "선거운동본부: 학관 1층 대형룸 | E-mail: flow.31sg@gmail.com",
              style: footerTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  // 푸터 SNS 아이콘 헬퍼
  Widget _buildSocialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(30 * Util.getScaleHeight(context)),
      // [수정]
      child: CircleAvatar(
        radius: 22 * Util.getScaleHeight(context), // [수정]
        backgroundColor: Colors.grey.shade200,
        child: FaIcon(
          icon,
          size: 20 * Util.getScaleHeight(context), // [수정]
          color: Colors.black87,
        ),
      ),
    );
  }
}
