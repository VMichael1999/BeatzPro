import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/widgets/animated_screen_transition.dart';
import '../Library/library_combined.dart';
import '../../widgets/side_nav_bar.dart';
import '../Library/library.dart';
import '../Search/search_screen.dart';
import '../Settings/settings_screen_controller.dart';
import '/ui/player/player_controller.dart';
import '/ui/widgets/create_playlist_dialog.dart';
import '../../navigator.dart';
import '../../widgets/content_list_widget.dart';
import '../../widgets/quickpickswidget.dart';
import '../../widgets/shimmer_widgets/home_shimmer.dart';
import 'home_screen_controller.dart';
import '/models/media_Item_builder.dart';
import '/models/playlist.dart';
import '/ui/utils/beatz_design.dart';
import '/ui/widgets/beatz/beatz_icon.dart';
import '/ui/widgets/beatz/beatz_widgets.dart';
import '/ui/widgets/image_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final HomeScreenController homeScreenController =
        Get.find<HomeScreenController>();
    final SettingsScreenController settingsScreenController =
        Get.find<SettingsScreenController>();

    return Scaffold(
        floatingActionButton: Obx(
          () => (homeScreenController.tabIndex.value == 0 ||
                      homeScreenController.tabIndex.value == 2) &&
                  settingsScreenController.isBottomNavBarEnabled.isFalse
              ? Obx(
                  () => Padding(
                    padding: EdgeInsets.only(
                        bottom: playerController.playerPanelMinHeight.value),
                    child: SizedBox(
                      height: 60,
                      width: 60,
                      child: FittedBox(
                        child: FloatingActionButton(
                            heroTag: null,
                            focusElevation: 0,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(14))),
                            elevation: 0,
                            onPressed: () async {
                              if (homeScreenController.tabIndex.value == 2) {
                                showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const CreateNRenamePlaylistPopup());
                              } else {
                                Get.toNamed(ScreenNavigationSetup.searchScreen,
                                    id: ScreenNavigationSetup.id);
                              }
                              // file:///data/user/0/com.example.beatzpro/cache/libCachedImageData/
                              //file:///data/user/0/com.example.beatzpro/cache/just_audio_cache/
                            },
                            child: Icon(homeScreenController.tabIndex.value == 2
                                ? Icons.add
                                : Icons.search_rounded)),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        body: Obx(
          () => Row(
            children: <Widget>[
              // create a navigation rail
              settingsScreenController.isBottomNavBarEnabled.isFalse
                  ? const SideNavBar()
                  : const SizedBox(
                      width: 0,
                    ),
              //const VerticalDivider(thickness: 1, width: 2),
              Expanded(
                child: Obx(() => AnimatedScreenTransition(
                    enabled: settingsScreenController
                        .isTransitionAnimationDisabled.isFalse,
                    resverse: homeScreenController.reverseAnimationtransiton,
                    horizontalTransition:
                        settingsScreenController.isBottomNavBarEnabled.isTrue,
                    child: Center(
                      key: ValueKey<int>(homeScreenController.tabIndex.value),
                      child: const Body(),
                    ))),
              ),
            ],
          ),
        ));
  }
}

class Body extends StatelessWidget {
  const Body({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    final settingsScreenController = Get.find<SettingsScreenController>();
    final colors = context.beatz;
    if (homeScreenController.tabIndex.value == 0) {
      return SafeArea(
        bottom: false,
        child: Obx(
          () => homeScreenController.networkError.isTrue
              ? Column(
                  children: [
                    const _HomeHeader(),
                    Expanded(
                      child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BeatzIcon('radio', size: 32, color: colors.muted),
                              const SizedBox(height: 12),
                              Text(
                                "networkError1".tr,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colors.ink),
                              ),
                              const SizedBox(height: 14),
                              Material(
                                color: colors.ink,
                                borderRadius: BorderRadius.circular(24),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap:
                                      homeScreenController.loadContentFromNetwork,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 12),
                                    child: Text(
                                      "retry".tr,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: colors.bg),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                      ),
                    )
                  ],
                )
              : Obx(() {
                  final items = homeScreenController.isContentFetched.value
                      ? [
                          const _ContinueListening(),
                          Obx(() => QuickPicksWidget(
                              content: homeScreenController.quickPicks.value)),
                          ...getWidgetList(homeScreenController.middleContent),
                          ...getWidgetList(
                            homeScreenController.fixedContent,
                          )
                        ]
                      : [const HomeShimmer()];
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) =>
                        index == 0 ? const _HomeHeader() : items[index - 1],
                  );
                }),
        ),
      );
    } else if (homeScreenController.tabIndex.value == 1) {
      return settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const SearchScreen()
          : const SongsLibraryWidget();
    } else if (homeScreenController.tabIndex.value == 2) {
      return settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const CombinedLibrary()
          : const PlaylistNAlbumLibraryWidget(isAlbumContent: false);
    } else if (homeScreenController.tabIndex.value == 3) {
      return settingsScreenController.isBottomNavBarEnabled.isTrue
          ? const SettingsScreen(isBottomNavActive: true)
          : const PlaylistNAlbumLibraryWidget();
    } else if (homeScreenController.tabIndex.value == 4) {
      return const LibraryArtistWidget();
    } else if (homeScreenController.tabIndex.value == 5) {
      return const SettingsScreen();
    } else {
      return Center(
        child: Text("${homeScreenController.tabIndex.value}"),
      );
    }
  }

  List<Widget> getWidgetList(dynamic list) {
    return list
        .map((content) => ContentListWidget(content: content))
        .whereType<Widget>()
        .toList();
  }
}


class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.beatz;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("home".tr,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: colors.ink)),
          BeatzIconButton(
            icon: 'radio',
            tooltip: 'Historial',
            background: colors.surface,
            onPressed: () => Get.toNamed(
                ScreenNavigationSetup.playlistNAlbumScreen,
                id: ScreenNavigationSetup.id,
                arguments: [
                  false,
                  Playlist(
                      title: "recentlyPlayed".tr,
                      playlistId: "LIBRP",
                      thumbnailUrl: "",
                      isCloudPlaylist: false),
                  false
                ]),
          ),
        ],
      ),
    );
  }
}

/// "Sigue escuchando": the last three songs of the recently played list.
class _ContinueListening extends StatelessWidget {
  const _ContinueListening();

  @override
  Widget build(BuildContext context) {
    final player = Get.find<PlayerController>();
    final tileWidth = (MediaQuery.of(context).size.width - 36 - 20) / 3;
    final colors = context.beatz;
    return FutureBuilder<Box>(
      future: Hive.openBox("LIBRP"),
      builder: (context, snapshot) {
        final box = snapshot.data;
        if (box == null) return const SizedBox.shrink();
        return ValueListenableBuilder<Box>(
          valueListenable: box.listenable(),
          builder: (context, box, _) {
            final songs = box.values
                .toList()
                .reversed
                .take(3)
                .map((e) => MediaItemBuilder.fromJson(e))
                .toList();
            if (songs.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BeatzSectionTitle('Sigue escuchando'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < songs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => player.pushSongToQueue(songs[i]),
                          child: SizedBox(
                            width: tileWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ImageWidget(size: tileWidth, song: songs[i]),
                                const SizedBox(height: 6),
                                Text(songs[i].title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        height: 1.25,
                                        color: colors.ink)),
                                Text(songs[i].artist ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12, color: colors.muted)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
