import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/ui/screens/Search/search_screen_controller.dart';
import '/ui/widgets/premium_surface.dart';

import '../../../navigator.dart';

class SearchItem extends StatelessWidget {
  final String queryString;
  final bool isHistoryString;
  const SearchItem(
      {super.key, required this.queryString, required this.isHistoryString});

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.find<SearchScreenController>();
    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 10, right: 8),
      padding: EdgeInsets.zero,
      borderRadius: 10,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 14, right: 12),
        onTap: () {
          Get.toNamed(ScreenNavigationSetup.searchResultScreen,
              id: ScreenNavigationSetup.id, arguments: queryString);
          searchScreenController.addToHistryQueryList(queryString);
          // for Desktop searchbar
          if (GetPlatform.isDesktop) {
            searchScreenController.focusNode.unfocus();
          }
        },
        leading: Container(
          height: 38,
          width: 38,
          decoration: const BoxDecoration(
            gradient: PremiumColors.accentGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isHistoryString ? Icons.history : Icons.search,
            color: Colors.white,
            size: 20,
          ),
        ),
        minLeadingWidth: 20,
        dense: true,
        title: Text(queryString),
        trailing: SizedBox(
          width: 80,
          child: Row(
            children: [
              isHistoryString
                  ? IconButton(
                      iconSize: 18,
                      splashRadius: 18,
                      visualDensity: const VisualDensity(horizontal: -2),
                      onPressed: () {
                        searchScreenController
                            .removeQueryFromHistory(queryString);
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).textTheme.titleMedium!.color,
                      ),
                    )
                  : const SizedBox(
                      width: 40,
                    ),
              IconButton(
                iconSize: 20,
                splashRadius: 18,
                visualDensity: const VisualDensity(horizontal: -2),
                onPressed: () {
                  searchScreenController.suggestionInput(queryString);
                },
                icon: Icon(
                  Icons.north_west,
                  color: Theme.of(context).textTheme.titleMedium!.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
