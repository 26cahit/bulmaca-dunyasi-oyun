import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/player_provider.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://ggmcwhdpvjbukycgnrur.supabase.co',
    publishableKey: 'sb_publishable_HBl-YNV69PtF1NPX50vAEA_MwervWqB',
  );

  await MobileAds.instance.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerProvider()..loadPlayer(),
      child: const BulmacaDunyasi(),
    ),
  );
}

class BulmacaDunyasi extends StatefulWidget {
  const BulmacaDunyasi({super.key});

  @override
  State<BulmacaDunyasi> createState() => _BulmacaDunyasiState();
}

class _BulmacaDunyasiState extends State<BulmacaDunyasi> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Bulmaca Dünyası",
      home: const SplashScreen(),
    );
  }
}
