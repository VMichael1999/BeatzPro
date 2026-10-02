import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:beatzpro/ui/widgets/modification_list.dart';

import '../screens/Artists/artist_screen_controller.dart';
import '../screens/Search/search_result_screen_controller.dart';
import 'beatz/beatz_widgets.dart';
import 'list_widget.dart';
import 'loader.dart';
import 'sort_widget.dart';

class SeparateTabItemWidget extends StatelessWidget {
  const SeparateTabItemWidget(
      {super.key,
      required this.items,
      required this.title,
      this.isCompleteList = true,
      this.isResultWidget = true,
      this.hideTitle = false,
      this.topPadding = 0,
      this.scrollController,
      this.artistControllerTag});

  /// tag for accessing Artist controller inst, [artistControllerTag] only valid for Artist screen
  final String? artistControllerTag;
  final List<dynamic> items;
  final String title;
  final bool isCompleteList;
  final double topPadding;
  final bool isResultWidget;
  final bool hideTitle;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final artistController =
        Get.isRegistered<ArtistScreenController>(tag: artistControllerTag)
            ? Get.find<ArtistScreenController>(tag: artistControllerTag)
            : null;
    final searchResController = Get.isRegistered<SearchResultScreenController>()
        ? Get.find<SearchResultScreenController>()
        : null;
    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        children: [
          if (!hideTitle)
            Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 10),
              child: BeatzSectionTitle(
                title.toLowerCase().removeAllWhitespace.tr,
                action: isCompleteList ? null : "viewAll".tr,
                onAction: isCompleteList
                    ? null
                    : () => searchResController!.viewAllCallback(title),
              ),
            ),
          isCompleteList
              ? Obx(() => SortWidget(
                    tag: "${title}_$artistControllerTag",
                    isAdditionalOperationRequired: artistController != null &&
                        (title == "Songs" || title == "Videos"),
                    isSearchFeatureRequired: artistController != null,
                    titleLeftPadding: 9,
                    itemCountTitle:
                        "${isResultWidget ? (searchResController?.separatedResultContent[title] ?? []).length : (artistController?.sepataredContent[title] != null ? artistController?.sepataredContent[title]['results'] : []).length} ${"items".tr}",
                    requiredSortTypes: buildSortTypeSet(title == 'Albums' || title == "Singles", title == "Songs" || title == "Videos"),
                    onSort: (type, ascending) {
                      isResultWidget
                          ? searchResController!.onSort(type, ascending, title)
                          : artistController?.onSort(type, ascending, title);
                    },
                    onSearch: artistController?.onSearch,
                    onSearchClose: artistController?.onSearchClose,
                    onSearchStart: artistController?.onSearchStart,
                    startAdditionalOperation:
                        artistController?.startAdditionalOperation,
                    selectAll: artistController?.selectAll,
                    performAdditionalOperation:
                        artistController?.performAdditionalOperation,
                    cancelAdditionalOperation:
                        artistController?.cancelAdditionalOperation,
                  ))
              : const SizedBox.shrink(),
          isCompleteList
              ? isResultWidget
                  ? GetX<SearchResultScreenController>(builder: (controller) {
                      if (controller.isSeparatedResultContentFetced.isTrue) {
                        return ListWidget(
                          controller.separatedResultContent[title],
                          title,
                          isCompleteList,
                          scrollController: scrollController,
                        );
                      } else {
                        return const Expanded(
                            child: Center(child: LoadingIndicator()));
                      }
                    })
                  : (artistController!.isArtistContentFetced.isTrue
                      ? Obx(() =>
                          (artistController.additionalOperationMode.value ==
                                  OperationMode.none
                              ? ListWidget(
                                  items,
                                  title,
                                  isCompleteList,
                                  isArtistSongs: true,
                                  scrollController: scrollController,
                                )
                              : ModificationList(
                                  mode: artistController
                                      .additionalOperationMode.value,
                                  artistScreenController: artistController,
                                )))
                      : const Expanded(
                          child: Center(child: LoadingIndicator())))
              : ListWidget(
                  items,
                  title,
                  isCompleteList,
                  scrollController: scrollController,
                ),
        ],
      ),
    );
  }
}
