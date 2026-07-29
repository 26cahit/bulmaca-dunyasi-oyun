import 'package:flutter/material.dart';

import 'art_literature_screen.dart';
import 'geography_screen.dart';
import 'history_screen.dart';
import 'mixed_knowledge_screen.dart';
import 'science_screen.dart';
import 'sports_screen.dart';

class KnowledgeHomeScreen extends StatelessWidget {
  const KnowledgeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;

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
          'Bilgi Dünyası',
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
                    Icon(Icons.public, color: Colors.amber, size: 58),
                    SizedBox(height: 8),
                    Text(
                      'Bilgini Test Et',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Farklı kategorilerde soruları çöz ve bilgini geliştir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _KnowledgeCard(
                width: screenWidth,
                icon: Icons.public,
                title: 'Coğrafya',
                subtitle: '25.000+ Coğrafya Sorusu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GeographyScreen()),
                  );
                },
              ),

              const SizedBox(height: 12),

              _KnowledgeCard(
                width: screenWidth,
                icon: Icons.account_balance,
                title: 'Tarih',
                subtitle: '30.000+ Tarih Sorusu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),

              const SizedBox(height: 12),

              _KnowledgeCard(
                width: screenWidth,
                icon: Icons.science,
                title: 'Bilim',
                subtitle: '35.000+ Bilim Sorusu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScienceScreen()),
                  );
                },
              ),

              const SizedBox(height: 12),

              _KnowledgeCard(
                width: screenWidth,
                icon: Icons.palette,
                title: 'Sanat ve Edebiyat',
                subtitle: '20.000+ Sanat ve Edebiyat Sorusu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ArtLiteratureScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _KnowledgeCard(
                width: screenWidth,
                icon: Icons.sports_soccer,
                title: 'Spor',
                subtitle: '20.000+ Spor Sorusu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SportsScreen()),
                  );
                },
              ),

              const SizedBox(height: 12),

              _KnowledgeCard(
                width: screenWidth,
                icon: Icons.shuffle,
                title: 'Karışık Bilgi',
                subtitle: '150.000+ Karışık Genel Kültür Sorusu',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MixedKnowledgeScreen(),
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

class _KnowledgeCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _KnowledgeCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool compact = width < 360;

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
