import 'package:flutter/material.dart';
import '../../widgets/comfort_avatar.dart';
import 'customization_screen.dart';

/// STEP 1 · 시작·안내
/// 실제 모습을 반영하라는 안내 없이, 편안한 마음으로 시작할 수 있도록
/// 돕는 것을 목표로 한 화면입니다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _EyebrowBadge(),
                const SizedBox(height: 28),

                // 편안함을 주는 아바타 — 이 화면의 시각적 중심
                const ComfortAvatar(size: 180),

                const SizedBox(height: 32),
                Text(
                  '오늘, 나를 닮지 않아도 괜찮은\n캐릭터를 만들어볼게요',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 14),
                Text(
                  '사진을 올리거나 실제 모습을 따라 할 필요는 없어요.\n'
                  '지금 이 순간 마음이 편안해지는 모습이면 충분합니다.\n'
                  '언제든 건너뛰거나 다시 시작할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomizationScreen()),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('시작하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EyebrowBadge extends StatelessWidget {
  const _EyebrowBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFD9A24B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'STEP 1 · 시작 · 안내',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
