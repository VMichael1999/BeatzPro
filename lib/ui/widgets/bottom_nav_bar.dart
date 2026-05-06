import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:beatzpro/ui/screens/Home/home_screen_controller.dart';
import 'premium_surface.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: PremiumColors.ink.withOpacity(0.92),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
            boxShadow: [
              BoxShadow(
                color: PremiumColors.violet.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, -8),
              )
            ],
          ),
          child: NavigationBar(
              onDestinationSelected:
                  homeScreenController.onBottonBarTabSelected,
              selectedIndex: homeScreenController.tabIndex.toInt(),
              backgroundColor: Colors.transparent,
              indicatorColor: PremiumColors.violet.withOpacity(0.22),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  selectedIcon: const Icon(Icons.home),
                  icon: const Icon(Icons.home_outlined),
                  label: modifyNgetlabel('home'.tr),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.search),
                  label: modifyNgetlabel('search'.tr),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.library_music),
                  label: modifyNgetlabel('library'.tr),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings),
                  label: modifyNgetlabel('settings'.tr),
                ),
              ]),
        ));
  }

  String modifyNgetlabel(String label) {
    if (label.length > 9) {
      return "${label.substring(0, 8)}..";
    }
    return label;
  }
}
