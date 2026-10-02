import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:beatzpro/ui/screens/Home/home_screen_controller.dart';

import '../utils/beatz_design.dart';
import 'beatz/beatz_icon.dart';

/// Bottom navigation of the redesign: four destinations, always with a name.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const _items = [
    ('home', 'home'),
    ('search', 'search'),
    ('lib', 'library'),
    ('gear', 'settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    final colors = context.beatz;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Obx(() {
      final selected = homeScreenController.tabIndex.toInt();
      return Container(
        decoration: BoxDecoration(
          color: colors.bg,
          border: Border(top: BorderSide(color: colors.line)),
        ),
        padding: EdgeInsets.fromLTRB(4, 6, 4, 8 + bottomInset),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selected == i,
                  label: _items[i].$2.tr,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () =>
                        homeScreenController.onBottonBarTabSelected(i),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BeatzIcon(_items[i].$1,
                                color:
                                    selected == i ? colors.ink : colors.muted),
                            const SizedBox(height: 3),
                            Text(
                              _items[i].$2.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: selected == i
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color:
                                    selected == i ? colors.ink : colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
