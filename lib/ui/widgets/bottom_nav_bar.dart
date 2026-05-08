import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:beatzpro/ui/screens/Home/home_screen_controller.dart';

import 'glass_widgets.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    return Obx(
      () => GlassBottomBar(
        onDestinationSelected: homeScreenController.onBottonBarTabSelected,
        selectedIndex: homeScreenController.tabIndex.toInt(),
        items: [
          GlassBottomBarItem(
            selectedIcon: Icons.home_rounded,
            icon: Icons.home_outlined,
            label: modifyNgetlabel('home'.tr),
          ),
          GlassBottomBarItem(
            selectedIcon: Icons.search_rounded,
            icon: Icons.search,
            label: modifyNgetlabel('search'.tr),
          ),
          GlassBottomBarItem(
            selectedIcon: Icons.library_music_rounded,
            icon: Icons.library_music_outlined,
            label: modifyNgetlabel('library'.tr),
          ),
          GlassBottomBarItem(
            selectedIcon: Icons.settings_rounded,
            icon: Icons.settings_outlined,
            label: modifyNgetlabel('settings'.tr),
          ),
        ],
      ),
    );
  }

  String modifyNgetlabel(String label) {
    if (label.length > 9) {
      return "${label.substring(0, 8)}..";
    }
    return label;
  }
}
