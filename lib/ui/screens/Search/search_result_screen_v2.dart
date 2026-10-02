import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:beatzpro/ui/widgets/loader.dart';
import 'package:beatzpro/ui/widgets/search_related_widgets.dart';

import '../../navigator.dart';
import '../../utils/beatz_design.dart';
import '../../widgets/beatz/beatz_widgets.dart';
import '../../widgets/separate_tab_item_widget.dart';
import 'search_result_screen_controller.dart';

class SearchResultScreenBN extends StatefulWidget {
  const SearchResultScreenBN({super.key});

  @override
  State<SearchResultScreenBN> createState() => _SearchResultScreenBNState();
}

class _SearchResultScreenBNState extends State<SearchResultScreenBN> {
  final _controller = Get.find<SearchResultScreenController>();
  late final TextEditingController _field =
      TextEditingController(text: _controller.queryString.value);
  Worker? _queryWorker;

  @override
  void initState() {
    super.initState();
    // the query arrives after the screen is built
    _queryWorker =
        ever<String>(_controller.queryString, (value) => _field.text = value);
  }

  @override
  void dispose() {
    _queryWorker?.dispose();
    _field.dispose();
    super.dispose();
  }

  void _back() => Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: BeatzSearchField(
                  controller: _field,
                  hint: "searchDes".tr,
                  readOnly: true,
                  onTap: _back,
                  onClear: _back,
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (_controller.isResultContentFetced.isTrue &&
                      _controller.railItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("nomatch".tr,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colors.ink)),
                          Text("'${_controller.queryString.value}'",
                              style: TextStyle(color: colors.muted)),
                        ],
                      ),
                    );
                  } else if (_controller.isResultContentFetced.isTrue) {
                    final tabController = _controller.tabController!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(left: 18, top: 6),
                          child: AnimatedBuilder(
                            animation: tabController.animation!,
                            builder: (context, _) => BeatzChips(
                              labels: [
                                "results".tr,
                                ..._controller.railItems.map((item) =>
                                    item.toLowerCase().removeAllWhitespace.tr)
                              ],
                              selected: _controller
                                  .navigationRailCurrentIndex.value,
                              onSelected: (i) =>
                                  _controller.onDestinationSelected(i),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: TabBarView(
                              controller: tabController,
                              children: [
                                const ResultWidget(isv2Used: true),
                                ..._controller.railItems.map((tabName) {
                                  if (tabName == "Songs" ||
                                      tabName == "Videos") {
                                    return SeparateTabItemWidget(
                                      isResultWidget: true,
                                      hideTitle: true,
                                      items: const [],
                                      title: tabName,
                                      isCompleteList: true,
                                      scrollController: _controller
                                          .scrollControllers[tabName],
                                    );
                                  } else {
                                    return SeparateTabItemWidget(
                                      title: tabName,
                                      hideTitle: true,
                                      items: const [],
                                      scrollController:
                                          _controller.scrollControllers[tabName],
                                    );
                                  }
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(child: LoadingIndicator());
                  }
                }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
