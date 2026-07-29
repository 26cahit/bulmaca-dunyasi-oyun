import 'package:flutter/material.dart';
import 'attention_test_screen.dart';
import 'number_logic_screen.dart';
import 'logic_questions_screen.dart';
import 'quick_intelligence_screen.dart';
import 'mixed_test_screen.dart';

class IntelligenceHomeScreen extends StatelessWidget {
  const IntelligenceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text(
          'Zeka Dünyası',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.psychology, color: Colors.amber, size: 58),
                    SizedBox(height: 8),
                    Text(
                      'Zihnini Test Et',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Mantık, dikkat ve zeka sorularını çöz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _IntelligenceCard(
                width: screenWidth,
                icon: Icons.calculate_rounded,
                title: 'Sayı Mantığı',
                subtitle: 'Sayı örüntülerini çöz',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NumberLogicScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _IntelligenceCard(
                width: screenWidth,
                icon: Icons.visibility_rounded,
                title: 'Dikkat Testi',
                subtitle: 'Detayları ne kadar hızlı görüyorsun?',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttentionTestScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _IntelligenceCard(
                width: screenWidth,
                icon: Icons.extension_rounded,
                title: 'Mantık Soruları',
                subtitle: 'Doğru bağlantıyı kur',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LogicQuestionsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _IntelligenceCard(
                width: screenWidth,
                icon: Icons.timer_rounded,
                title: 'Hızlı Zeka',
                subtitle: 'Süre bitmeden doğru cevabı bul',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuickIntelligenceScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _IntelligenceCard(
                width: screenWidth,
                icon: Icons.emoji_events_rounded,
                title: 'Karışık Test',
                subtitle: 'Tüm zeka kategorilerinden sorular',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MixedTestScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntelligenceCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _IntelligenceCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = width < 360;

    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 18,
            vertical: compact ? 15 : 18,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 48 : 54,
                height: compact ? 48 : 54,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.amber, size: compact ? 27 : 31),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: compact ? 13 : 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
