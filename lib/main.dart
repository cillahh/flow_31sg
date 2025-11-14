import 'package:firebase_core/firebase_core.dart';
import 'package:flow/screens/home_screen.dart';
import 'package:flow/screens/pledge_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/admin_inquiry_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// [업데이트] 로고 색상(파란색)과 흰색 배경으로 변경
const Color kPrimaryColor = Color(0xFF3759BB); // 로고 포인트 컬러
const Color kBackgroundColor = Color(0xFFFFFFFF); // 흰색 배경

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // [추가] 익명으로라도 Firebase Auth에 로그인 시도
  // Firestore 보안 규칙을 통과하기 위해 필요할 수 있음
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint("익명 로그인 실패 (무시 가능): $e");
  }

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  // errorBuilder: (context, state) => const NotFoundScreen(),
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/pledges',
      builder: (BuildContext context, GoRouterState state) {
        return const PledgeTestScreen();
      },
    ),
    GoRoute(
      path: '/pledge-test',
      builder: (BuildContext context, GoRouterState state) {
        return const PledgeTestScreen();
      },
    ),
    GoRoute(
      path: '/admin-inquiries',
      builder: (context, state) => const AdminInquiryScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaryColor,
        brightness: Brightness.light, // 라이트 모드
        background: kBackgroundColor,
        onBackground: Colors.black87, // 흰 배경 위의 텍스트는 검은색
        surface: Colors.white,
        onSurface: Colors.black87,
        primary: kPrimaryColor,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: kBackgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 3, // 앱바 그림자
        backgroundColor: Colors.white, // 앱바 배경은 파란색
        foregroundColor: kPrimaryColor, // 앱바 텍스트/아이콘은 흰색
      ),
      cardTheme: CardThemeData(
        elevation: 1, // 그림자 약하게
        shadowColor: Colors.black12, // 그림자 색
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        color: Colors.white, // 카드 배경은 흰색
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      // [업데이트] 기본 텍스트 색상을 검은색 계열로
      textTheme: ThemeData(brightness: Brightness.light)
          .textTheme
          .apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      )
          .copyWith(
        // Card 내부가 아닌, 배경 위에 직접 쓰이는 제목들
        headlineSmall: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black87),
        bodyLarge: const TextStyle(color: Colors.black54),
      ),
    );

    return MaterialApp.router(
      title: 'FLOW 총학생회 선거 캠프',
      theme: theme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}