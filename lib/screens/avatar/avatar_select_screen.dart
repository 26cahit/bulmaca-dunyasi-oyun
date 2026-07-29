import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/avatar.dart';
import '../../../providers/player_provider.dart';
import '../../../utils/responsive.dart';
import 'dart:io';

import '../../../services/image_picker_service.dart';

class AvatarSelectScreen extends StatelessWidget {
  const AvatarSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Avatar Seç",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: r.font(30),
          ),
        ),
      ),
      body: GridView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: r.horizontalPadding,
          vertical: r.mediumGap,
        ),
        itemCount: avatars.length + 1,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: r.isSmallPhone
              ? 2
              : r.isMediumPhone
              ? 3
              : 4,
          crossAxisSpacing: r.mediumGap,
          mainAxisSpacing: r.mediumGap,
          childAspectRatio: r.isSmallPhone
              ? 0.90
              : r.isMediumPhone
              ? 0.95
              : 1.00,
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return InkWell(
              borderRadius: BorderRadius.circular(
                r.clampWidth(.06, min: 18, max: 28),
              ),
              onTap: () async {
                final String? source = await showModalBottomSheet<String>(
                  context: context,
                  backgroundColor: const Color(0xFF1E293B),
                  builder: (_) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.photo,
                              color: Colors.white,
                            ),
                            title: const Text(
                              "Galeriden Seç",
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () => Navigator.pop(context, "gallery"),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            title: const Text(
                              "Kamera",
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () => Navigator.pop(context, "camera"),
                          ),
                        ],
                      ),
                    );
                  },
                );

                File? image;

                if (source == "gallery") {
                  image = await ImagePickerService.pickImageFromGallery();
                }

                if (source == "camera") {
                  image = await ImagePickerService.pickImageFromCamera();
                }

                if (image == null) return;

                await player.saveCustomAvatar(image);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(
                    r.clampWidth(.06, min: 18, max: 28),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                      size: r.font(42),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Galeriden\nSeç",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: r.font(15),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final avatar = avatars[index - 1];

          final bool selected = player.avatar == avatar.emoji;

          return InkWell(
            borderRadius: BorderRadius.circular(
              r.clampWidth(.06, min: 18, max: 28),
            ),
            onTap: () async {
              await player.saveAvatar(avatar.emoji);

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.amber.withValues(alpha: .18)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(
                      r.clampWidth(.06, min: 18, max: 28),
                    ),
                    border: Border.all(
                      color: selected ? Colors.amber : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(r.smallGap),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FittedBox(
                          child: Text(
                            avatar.emoji,
                            style: TextStyle(fontSize: r.font(62)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: _SelectedAvatarBadge(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectedAvatarBadge extends StatelessWidget {
  const _SelectedAvatarBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
        child: Icon(Icons.check, color: Color(0xFF0F172A), size: 18),
      ),
    );
  }
}
