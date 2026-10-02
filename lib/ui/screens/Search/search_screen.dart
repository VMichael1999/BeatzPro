import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/navigator.dart';
import '/ui/utils/beatz_design.dart';
import '/ui/widgets/beatz/beatz_icon.dart';
import '/ui/widgets/beatz/beatz_widgets.dart';
import 'search_screen_controller.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.put(SearchScreenController());
    final colors = context.beatz;
    final isDesktop = GetPlatform.isDesktop;

    void open(String query) {
      Get.toNamed(ScreenNavigationSetup.searchResultScreen,
          id: ScreenNavigationSetup.id, arguments: query);
      searchScreenController.addToHistryQueryList(query);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isDesktop)
                    BeatzIconButton(
                      icon: 'back',
                      iconSize: 24,
                      tooltip: 'Volver',
                      onPressed: () => Get.nestedKey(ScreenNavigationSetup.id)!
                          .currentState!
                          .pop(),
                    ),
                  Expanded(
                    child: BeatzSearchField(
                      controller: searchScreenController.textInputController,
                      hint: "searchDes".tr,
                      autofocus: isDesktop,
                      onChanged: searchScreenController.onChanged,
                      onSubmitted: open,
                      onClear: searchScreenController.reset,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  final isEmpty = searchScreenController
                          .suggestionList.isEmpty ||
                      searchScreenController.textInputController.text == "";
                  final list = isEmpty
                      ? searchScreenController.historyQuerylist.toList()
                      : searchScreenController.suggestionList.toList();
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 5, bottom: 120),
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    itemCount: list.length,
                    itemBuilder: (context, index) => InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => open(list[index]),
                      child: SizedBox(
                        height: 52,
                        child: Row(
                          children: [
                            Icon(
                              isEmpty
                                  ? Icons.history_rounded
                                  : Icons.search_rounded,
                              size: 20,
                              color: colors.muted,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                list[index],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    TextStyle(fontSize: 15, color: colors.ink),
                              ),
                            ),
                            if (isEmpty)
                              BeatzIconButton(
                                icon: 'x',
                                tooltip: 'Quitar del historial',
                                color: colors.muted,
                                onPressed: () => searchScreenController
                                    .removeQueryFromHistory(list[index]),
                              ),
                            Tooltip(
                              message: 'Usar en la búsqueda',
                              child: InkResponse(
                                onTap: () => searchScreenController
                                    .suggestionInput(list[index]),
                                radius: 24,
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(Icons.north_west_rounded,
                                      size: 20, color: colors.muted),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
