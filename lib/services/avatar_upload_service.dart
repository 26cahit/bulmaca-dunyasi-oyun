import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AvatarUploadService {
  static final _supabase = Supabase.instance.client;

  static Future<String> uploadAvatar(File file) async {
    try {
      final fileName = const Uuid().v4();

      debugPrint("UPLOAD BAŞLADI");

      await _supabase.storage
          .from('avatars')
          .upload(
            "$fileName.jpg",
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _supabase.storage
          .from('avatars')
          .getPublicUrl("$fileName.jpg");

      debugPrint("YÜKLENDİ : $url");

      return url;
    } catch (e) {
      debugPrint("SUPABASE HATASI");
      debugPrint(e.toString());
      rethrow;
    }
  }
}
