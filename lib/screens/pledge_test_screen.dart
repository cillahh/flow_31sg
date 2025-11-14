import '../widgets/mobile_layout_wrapper.dart';
import 'package:flutter/material.dart';

// (main.dart 라우팅에 추가된 임시 스크린입니다)
class PledgeTestScreen extends StatelessWidget {
  const PledgeTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나에게 맞는 공약 테스트'),
      ),
      body: MobileLayoutWrapper(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  '공약 테스트 페이지',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '이곳에 질문과 선택지를 넣어 테스트 UI를 구성하게 됩니다.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
