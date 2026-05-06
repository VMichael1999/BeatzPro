import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'components/search_item.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '../../widgets/modified_text_field.dart';
import '../../widgets/premium_surface.dart';
import '/ui/navigator.dart';
import 'search_screen_controller.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.put(SearchScreenController());
    final settingsScreenController = Get.find<SettingsScreenController>();
    final topPadding = context.isLandscape ? 50.0 : 80.0;
    return Scaffold(
      backgroundColor: PremiumColors.ink,
      resizeToAvoidBottomInset: false,
      body: PremiumBackdrop(
        child: Obx(
          () => Row(
            children: [
              settingsScreenController.isBottomNavBarEnabled.isFalse
                  ? Container(
                      width: 60,
                      color:
                          Theme.of(context).navigationRailTheme.backgroundColor,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: topPadding),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .color,
                              ),
                              onPressed: () {
                                Get.nestedKey(ScreenNavigationSetup.id)!
                                    .currentState!
                                    .pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(
                      width: 15,
                    ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: topPadding, left: 5, right: 18),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "search".tr,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      PremiumGlass(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 2),
                        borderRadius: 24,
                        child: ModifiedTextField(
                          textCapitalization: TextCapitalization.sentences,
                          controller:
                              searchScreenController.textInputController,
                          textInputAction: TextInputAction.search,
                          onChanged: searchScreenController.onChanged,
                          onSubmitted: (val) {
                            if (val.contains("https://")) {
                              searchScreenController
                                  .filterLinks(Uri.parse(val));
                              searchScreenController.reset();
                              return;
                            }
                            Get.toNamed(
                                ScreenNavigationSetup.searchResultScreen,
                                id: ScreenNavigationSetup.id,
                                arguments: val);
                            searchScreenController.addToHistryQueryList(val);
                          },
                          autofocus: settingsScreenController
                              .isBottomNavBarEnabled.isFalse,
                          cursorColor:
                              Theme.of(context).textTheme.bodySmall!.color,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search_rounded),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              focusColor: Colors.white,
                              hintText: "searchDes".tr,
                              suffix: IconButton(
                                onPressed: searchScreenController.reset,
                                icon: const Icon(Icons.close),
                                splashRadius: 16,
                                iconSize: 19,
                              )),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: const [
                            _TrendChip(label: "Electronic"),
                            _TrendChip(label: "Pop"),
                            _TrendChip(label: "Focus"),
                            _TrendChip(label: "Trending"),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Obx(() {
                          final isEmpty = searchScreenController
                                  .suggestionList.isEmpty ||
                              searchScreenController.textInputController.text ==
                                  "";
                          final list = isEmpty
                              ? searchScreenController.historyQuerylist.toList()
                              : searchScreenController.suggestionList.toList();
                          return ListView(
                              padding:
                                  const EdgeInsets.only(top: 5, bottom: 400),
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              children: searchScreenController.urlPasted.isTrue
                                  ? [
                                      InkWell(
                                        onTap: () {
                                          searchScreenController.filterLinks(
                                              Uri.parse(searchScreenController
                                                  .textInputController.text));
                                          searchScreenController.reset();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10.0),
                                          child: SizedBox(
                                            width: double.maxFinite,
                                            height: 60,
                                            child: Center(
                                                child: Text(
                                              "urlSearchDes".tr,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            )),
                                          ),
                                        ),
                                      )
                                    ]
                                  : list
                                      .map((item) => SearchItem(
                                          queryString: item,
                                          isHistoryString: isEmpty))
                                      .toList());
                        }),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall!
            .copyWith(color: PremiumColors.muted),
      ),
    );
  }
}
