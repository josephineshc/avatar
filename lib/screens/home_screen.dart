import 'package:flutter/material.dart';
import '../../widgets/comfort_avatar.dart';
import 'customization_screen.dart';

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

                const ComfortAvatar(size: 180),

                const SizedBox(height: 32),
                Text(
                  '아바타 커스텀',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22),
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
        'STEP 1 · 시작',
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
