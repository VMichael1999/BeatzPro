import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../widgets/custom_lyricui.dart';
import '../widgets/custom_progress.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/loader.dart';
import '../../utils/helper.dart';
import '../widgets/up_next_queue.dart';
import '/ui/player/player_controller.dart';
import '../screens/Settings/settings_screen_controller.dart';
import '/ui/utils/theme_controller.dart';
import '/ui/widgets/songinfo_bottom_sheet.dart';
import '../widgets/image_widget.dart';
import '../widgets/sliding_up_panel.dart';

class Player extends StatefulWidget {
  const Player({super.key});

  @override
  PlayerState createState() => PlayerState();
}

class PlayerState extends State<Player> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Worker? _playbackStateWorker;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // Customize the duration as needed
      vsync: this,
    );
    final playerController = Get.find<PlayerController>();
    _syncPlaybackAnimations(playerController.buttonState.value);
    _playbackStateWorker = ever<PlayButtonState>(
      playerController.buttonState,
      _syncPlaybackAnimations,
    );
  }

  @override
  void dispose() {
    _playbackStateWorker?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _syncPlaybackAnimations(PlayButtonState state) {
    final controller = _controller;
    if (controller == null) return;
    if (state == PlayButtonState.playing) {
      if (!controller.isAnimating) {
        controller.repeat();
      }
    } else {
      controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    printINFO("player");
    final size = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final PlayerController playerController = Get.find<PlayerController>();
    final ThemeController themeController = Get.find<ThemeController>();
    final isTinyHeight = size.height < 650;
    final isCompactHeight = size.height < 750;
    final horizontalPadding = size.width < 360 ? 18.0 : 25.0;
    final availableWidth = size.width - (horizontalPadding * 2);
    final maxArtworkByHeight = size.height *
        (isTinyHeight
            ? 0.28
            : isCompactHeight
                ? 0.32
                : 0.36);
    final playerArtImageSize = math.max(
      190.0,
      math.min(360.0, math.min(availableWidth, maxArtworkByHeight)),
    );
    final collapsedPanelHeight = 65.0 + safeArea.bottom;
    final controlsBottomGap =
        collapsedPanelHeight + (isTinyHeight ? 10.0 : 14.0);
    final lyricsPanelHeight = math.max(
      isTinyHeight ? 245.0 : 285.0,
      math.min(
        isTinyHeight
            ? size.height * 0.38
            : isCompactHeight
                ? size.height * 0.43
                : size.height * 0.46,
        playerArtImageSize * (isTinyHeight ? 1.55 : 1.82),
      ),
    );
    final List<Color> colors = [
      Colors.black,
      Theme.of(context).primaryColor.withLightness(0.4),
      Theme.of(context).primaryColor.withLightness(0.6),
      Theme.of(context).primaryColor.withLightness(0.7),
    ];

    final List<int> duration = [900, 700, 600, 800, 500];

    return Scaffold(
      body: SlidingUpPanel(
        minHeight: 65 + Get.mediaQuery.padding.bottom,
        maxHeight: size.height,
        isDraggable: !GetPlatform.isDesktop,
        collapsed: InkWell(
          onTap: () {
            if (GetPlatform.isDesktop) {
              playerController.homeScaffoldkey.currentState!.openEndDrawer();
            }
          },
          child: GlassContainer(
            borderRadius: 0,
            blur: 16,
            opacity: 0.12,
            borderOpacity: 0.08,
            color: Theme.of(context)
                .bottomSheetTheme
                .modalBarrierColor
                ?.withValues(alpha: 0.72),
            child: Column(
              children: [
                SizedBox(
                  height: 65,
                  child: Center(
                    child: Icon(
                      color: Theme.of(context).textTheme.titleMedium!.color,
                      Icons.keyboard_arrow_up_rounded,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        panelBuilder: (ScrollController sc, onReorderStart, onReorderEnd) {
          playerController.scrollController = sc;
          return Stack(
            children: [
              UpNextQueue(
                onReorderEnd: onReorderEnd,
                onReorderStart: onReorderStart,
              ),
              Positioned(
                bottom: 60,
                right: 15,
                child: SizedBox(
                  height: 60,
                  width: 60,
                  child: FittedBox(
                    child: FloatingActionButton(
                      heroTag: null,
                      focusElevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      elevation: 0,
                      onPressed: playerController.shuffleQueue,
                      child: const Icon(Icons.shuffle),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        body: Stack(
          children: [
            Obx(
              () => SizedBox.expand(
                child: playerController.currentSong.value != null
                    ? CachedNetworkImage(
                        errorWidget: (context, url, error) {
                          final imgFile = File(
                              "${Get.find<SettingsScreenController>().supportDirPath}/thumbnails/${playerController.currentSong.value!.id}.png");
                          if (imgFile.existsSync()) {
                            themeController.setTheme(FileImage(imgFile));
                            return Image.file(imgFile, cacheHeight: 200);
                          }
                          return const SizedBox.shrink();
                        },
                        memCacheHeight: 200,
                        imageBuilder: (context, imageProvider) {
                          Get.find<SettingsScreenController>()
                                      .themeModetype
                                      .value ==
                                  ThemeType.dynamic
                              ? themeController.setTheme(imageProvider)
                              : null;
                          return Image(
                            image: imageProvider,
                            fit: BoxFit.fitHeight,
                          );
                        },
                        imageUrl: playerController.currentSong.value!.artUri
                            .toString(),
                        cacheKey:
                            "${playerController.currentSong.value!.id}_song",
                      )
                    : Container(),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.84),
                      Theme.of(context).primaryColor.withValues(alpha: 0.92),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Column(
                children: [
                  Obx(
                    () {
                      final topGap = safeArea.top +
                          (playerController.showLyricsflag.value
                              ? (isCompactHeight ? 8.0 : 36.0)
                              : (isTinyHeight
                                  ? 6.0
                                  : isCompactHeight
                                      ? 18.0
                                      : 42.0));
                      return SizedBox(height: topGap);
                    },
                  ),
                  Obx(
                    () => playerController.currentSong.value != null &&
                            playerController.showLyricsflag.isFalse
                        ? const SizedBox.shrink()
                        // CupertinoSlidingSegmentedControl hidden temporarily.
                        // ? Padding(
                        //     padding: const EdgeInsets.only(bottom: 12.0),
                        //     child: _mediaModeSegment(playerController),
                        //   )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => playerController.currentSong.value != null
                        ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 0.98, end: 1)
                                      .animate(
                                    CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: playerController.showLyricsflag.value
                                ? _buildLyricsExperience(
                                    playerController,
                                    height: lyricsPanelHeight,
                                    compact: isCompactHeight,
                                  )
                                : playerController.mediaMode.value ==
                                        PlayerMediaMode.video
                                    ? _buildVideoSurface(
                                        playerController,
                                        playerArtImageSize,
                                      )
                                    : _buildLiquidArtworkPanel(
                                        playerController,
                                        playerArtImageSize,
                                      ),
                          )
                        : Container(),
                  ),
                  Obx(
                    () => SizedBox(
                      height: playerController.showLyricsflag.isTrue
                          ? (isTinyHeight ? 3 : 6)
                          : (isTinyHeight ? 10 : 16),
                    ),
                  ),
                  Obx(
                    () => SizedBox(
                      height: playerController.showLyricsflag.isTrue
                          ? 0
                          : (isTinyHeight ? 6 : 10),
                    ),
                  ),
                  Obx(() {
                    final showLyrics = playerController.showLyricsflag.value;

                    return Visibility(
                      visible: _shouldShowVisualizer() &&
                          playerController.currentSong.value != null &&
                          !showLyrics,
                      child: _buildMusicVisualizer(colors, duration),
                    );
                  }),
                  SizedBox(height: isTinyHeight ? 6 : 10),
                  Obx(
                    () => playerController.showLyricsflag.isFalse
                        ? _buildTrackInfoPanel(playerController)
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => SizedBox(
                      height: playerController.showLyricsflag.isTrue
                          ? (isTinyHeight ? 4 : 8)
                          : (isTinyHeight ? 12 : 18),
                    ),
                  ),
                  GetX<PlayerController>(builder: (controller) {
                    return CustomProgressBar(
                      currentSliderValue: controller
                              .progressBarStatus.value.current.inSeconds
                              .toDouble() /
                          60,
                      maxValue: controller
                              .progressBarStatus.value.total.inSeconds
                              .toDouble() /
                          60,
                      onChanged: (value) {
                        controller
                            .seek(Duration(seconds: (value * 60).toInt()));
                      },
                    );
                  }),
                  Obx(
                    () => SizedBox(
                      height: playerController.showLyricsflag.isTrue
                          ? (isTinyHeight ? 10 : 14)
                          : (isTinyHeight ? 18 : 28),
                    ),
                  ),
                  if (_shouldShowPlayerControls())
                    _buildMinimalTransportControls(
                      playerController,
                      isTinyHeight: isTinyHeight,
                    ),
                  Obx(
                    () => SizedBox(
                      height: playerController.showLyricsflag.isTrue
                          ? (isTinyHeight ? 8 : 10)
                          : (isTinyHeight ? 14 : 20),
                    ),
                  ),
                  _buildVolumeGlassSlider(playerController),
                  Obx(
                    () => SizedBox(
                      height: playerController.showLyricsflag.isTrue
                          ? (isTinyHeight ? 4 : 6)
                          : (isTinyHeight ? 10 : 14),
                    ),
                  ),
                  _buildBottomPlayerActions(playerController),
                  SizedBox(
                    height: controlsBottomGap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _mediaModeSegment(PlayerController playerController) {
    final isCompactWidth = MediaQuery.of(context).size.width < 370;
    final horizontalPadding = isCompactWidth ? 12.0 : 18.0;
    return CupertinoSlidingSegmentedControl<PlayerMediaMode>(
      groupValue: playerController.mediaMode.value,
      backgroundColor: Colors.black.withValues(alpha: 0.45),
      thumbColor: Theme.of(context).primaryColor.withLightness(0.45),
      padding: const EdgeInsets.all(4),
      children: {
        PlayerMediaMode.music: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: const Text(
            "Canción",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        PlayerMediaMode.video: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          child: const Text(
            "Video",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      },
      onValueChanged: (value) {
        if (value != null) {
          playerController.setMediaMode(value);
        }
      },
    );
  }

  bool _shouldShowPlayerControls() {
    return true;
  }

  bool _shouldShowVisualizer() {
    return false;
  }

  Widget _buildLyricsExperience(
    PlayerController playerController, {
    required double height,
    required bool compact,
  }) {
    final song = playerController.currentSong.value;
    if (song == null) return const SizedBox.shrink();

    return SizedBox(
      key: ValueKey("lyrics-${song.id}"),
      height: height,
      child: Column(
        children: [
          Container(
            width: 78,
            height: 6,
            margin: EdgeInsets.only(bottom: compact ? 10 : 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: ImageWidget(
                  song: song,
                  size: compact ? 54 : 62,
                  isPlayerArtImage: true,
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontSize: compact ? 18 : 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist ?? "NA",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: compact ? 13 : 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Obx(
                () => GlassButton(
                  icon: playerController.isCurrentSongFav.isFalse
                      ? Icons.star_border_rounded
                      : Icons.star_rounded,
                  size: compact ? 40 : 44,
                  iconSize: compact ? 22 : 25,
                  color: playerController.isCurrentSongFav.isFalse
                      ? Colors.white
                      : Theme.of(context).colorScheme.secondary,
                  onPressed: playerController.toggleFavourite,
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              GlassButton(
                icon: Icons.more_horiz_rounded,
                size: compact ? 40 : 44,
                iconSize: compact ? 23 : 26,
                onPressed: () => _showSongInfoSheet(playerController),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          _buildLyricsModeControl(playerController, compact: compact),
          SizedBox(height: compact ? 8 : 10),
          Expanded(
            child: GlassContainer(
              width: double.infinity,
              borderRadius: 24,
              opacity: 0.10,
              blur: 18,
              borderOpacity: 0.12,
              fakeLiquidGlass: false,
              color: Colors.black.withValues(alpha: 0.36),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.18),
                            Colors.black.withValues(alpha: 0.06),
                            Colors.black.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Obx(
                      () {
                        if (playerController.isLyricsLoading.isTrue) {
                          return const Center(child: LoadingIndicator());
                        }

                        final syncedLyrics =
                            playerController.lyrics["synced"]?.toString() ?? "";
                        final plainLyrics = playerController
                                .lyrics["plainLyrics"]
                                ?.toString() ??
                            "";
                        final shouldShowPlain =
                            playerController.lyricsMode.toInt() == 1 ||
                                syncedLyrics.trim().isEmpty;

                        if (shouldShowPlain) {
                          return _buildPlainLyricsText(
                            plainLyrics,
                            compact: compact,
                          );
                        }

                        return IgnorePointer(
                          child: LyricsReader(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: compact ? 18 : 26,
                            ),
                            lyricUi: CustomLyricUI(
                              primaryColor:
                                  Colors.white.withValues(alpha: 0.32),
                              highlightColor:
                                  Colors.white.withValues(alpha: 0.94),
                              fontSize: compact ? 22 : 25,
                              highlightFontSize: compact ? 25 : 29,
                            ),
                            position: playerController
                                .progressBarStatus.value.current.inMilliseconds,
                            model: LyricsModelBuilder.create()
                                .bindLyricToMain(syncedLyrics)
                                .getModel(),
                            emptyBuilder: () => _buildPlainLyricsText(
                              plainLyrics,
                              compact: compact,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.72),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.transparent,
                            Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.72),
                          ],
                          stops: const [0, 0.18, 0.50, 0.82, 1],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsModeControl(
    PlayerController playerController, {
    required bool compact,
  }) {
    return Obx(
      () {
        final syncedLyrics =
            playerController.lyrics["synced"]?.toString().trim() ?? "";
        final hasSyncedLyrics = syncedLyrics.isNotEmpty;

        return Align(
          alignment: Alignment.center,
          child: GlassContainer(
            padding: const EdgeInsets.all(3),
            borderRadius: 22,
            opacity: 0.08,
            blur: 14,
            borderOpacity: 0.10,
            fakeLiquidGlass: false,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: playerController.lyricsMode.value,
              backgroundColor: Colors.black.withValues(alpha: 0.18),
              thumbColor: Colors.white.withValues(alpha: 0.18),
              padding: EdgeInsets.zero,
              children: {
                0: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 6 : 7,
                  ),
                  child: Text(
                    'synced'.tr,
                    style: TextStyle(
                      color: hasSyncedLyrics
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.42),
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 6 : 7,
                  ),
                  child: Text(
                    'plain'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              },
              onValueChanged: (value) {
                if (value != null) {
                  playerController.changeLyricsMode(value);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackInfoPanel(PlayerController playerController) {
    return Obx(() {
      final song = playerController.currentSong.value;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song?.title ?? "NA",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  song?.artist ?? "NA",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GlassButton(
            icon: playerController.isCurrentSongFav.isFalse
                ? Icons.star_border_rounded
                : Icons.star_rounded,
            size: 38,
            iconSize: 20,
            color: playerController.isCurrentSongFav.isFalse
                ? Colors.white
                : Theme.of(context).colorScheme.secondary,
            onPressed: playerController.toggleFavourite,
          ),
          const SizedBox(width: 8),
          GlassButton(
            icon: Icons.more_horiz_rounded,
            size: 38,
            iconSize: 22,
            onPressed: () => _showSongInfoSheet(playerController),
          ),
        ],
      );
    });
  }

  Widget _buildPlainLyricsText(
    String plainLyrics, {
    required bool compact,
  }) {
    final normalizedLyrics = plainLyrics.trim();
    final hasLyrics = normalizedLyrics.isNotEmpty && normalizedLyrics != "NA";

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: 6,
        vertical: compact ? 18 : 28,
      ),
      child: Text(
        hasLyrics ? normalizedLyrics : "lyricsNotAvailable".tr,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: hasLyrics ? 0.82 : 0.68),
              fontSize: compact ? 21 : 25,
              height: 1.22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
      ),
    );
  }

  Widget _buildMinimalTransportControls(
    PlayerController playerController, {
    required bool isTinyHeight,
  }) {
    return GetX<PlayerController>(builder: (controller) {
      final buttonState = controller.buttonState.value;
      final isPlaying = buttonState == PlayButtonState.playing;
      final isLastSong = controller.currentQueue.isEmpty ||
          (controller.currentQueue.last.id == controller.currentSong.value?.id);
      final isFirstSong = controller.currentQueue.isEmpty ||
          (controller.currentQueue.first.id ==
              controller.currentSong.value?.id);
      final playSize = isTinyHeight ? 64.0 : 72.0;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GlassButton(
            icon: Icons.fast_rewind_rounded,
            size: isTinyHeight ? 48 : 54,
            iconSize: isTinyHeight ? 28 : 32,
            onPressed: isFirstSong ? null : controller.prev,
          ),
          buttonState == PlayButtonState.loading
              ? GlassContainer(
                  height: playSize,
                  width: playSize,
                  borderRadius: playSize / 2,
                  opacity: 0.18,
                  blur: 12,
                  fakeLiquidGlass: false,
                  alignment: Alignment.center,
                  child: const LoadingIndicator(dimension: 24),
                )
              : GlassButton(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: playSize,
                  iconSize: isTinyHeight ? 38 : 44,
                  isPrimary: true,
                  onPressed: () {
                    if (buttonState == PlayButtonState.paused) {
                      controller.play();
                    } else if (buttonState == PlayButtonState.playing) {
                      controller.pause();
                    }
                  },
                ),
          GlassButton(
            icon: Icons.fast_forward_rounded,
            size: isTinyHeight ? 48 : 54,
            iconSize: isTinyHeight ? 28 : 32,
            onPressed: isLastSong ? null : controller.next,
          ),
        ],
      );
    });
  }

  Widget _buildVolumeGlassSlider(PlayerController playerController) {
    return Obx(() {
      final volume = playerController.volume.value / 100;
      return SizedBox(
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Colors.white.withValues(alpha: 0.86),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.26),
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: volume.clamp(0.0, 1.0),
                  onChanged: (value) {
                    playerController.setVolume((value * 100).toInt());
                  },
                ),
              ),
            ),
            Positioned(
              left: 0,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: playerController.mute,
                icon: Icon(
                  volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_down_rounded,
                  color: Colors.white.withValues(alpha: 0.82),
                  size: 18,
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Icon(
                Icons.volume_up_rounded,
                color: Colors.white.withValues(alpha: 0.82),
                size: 18,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBottomPlayerActions(PlayerController playerController) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GlassButton(
          icon: Icons.queue_music_rounded,
          size: 40,
          iconSize: 20,
          onPressed: () {
            playerController.playerPanelController.open();
          },
        ),
        Obx(
          () => GlassButton(
            icon: playerController.isLoopModeEnabled.value
                ? Icons.repeat_one_rounded
                : Icons.all_inclusive_rounded,
            size: 40,
            iconSize: 20,
            color: playerController.isLoopModeEnabled.value
                ? Theme.of(context).colorScheme.secondary
                : null,
            onPressed: playerController.toggleLoopMode,
          ),
        ),
        Obx(
          () => GlassButton(
            icon: playerController.showLyricsflag.isTrue
                ? Icons.music_note_rounded
                : Icons.chat_bubble_outline_rounded,
            size: 40,
            iconSize: 18,
            color: playerController.showLyricsflag.isTrue
                ? Theme.of(context).colorScheme.secondary
                : null,
            onPressed: playerController.showLyrics,
          ),
        ),
      ],
    );
  }

  void _showSongInfoSheet(PlayerController playerController) {
    final currentSong = playerController.currentSong.value;
    if (currentSong == null) return;
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      isScrollControlled: true,
      context: playerController.homeScaffoldkey.currentState!.context,
      barrierColor: Colors.transparent.withAlpha(100),
      builder: (context) => SongInfoBottomSheet(
        currentSong,
        calledFromPlayer: true,
      ),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }

  Widget _buildLiquidArtworkPanel(
    PlayerController playerController,
    double panelSize,
  ) {
    final song = playerController.currentSong.value;
    if (song == null) return const SizedBox.shrink();

    return GlassContainer(
      height: panelSize,
      width: panelSize,
      borderRadius: 30,
      opacity: 0.16,
      blur: 12,
      borderOpacity: 0.10,
      fakeLiquidGlass: false,
      padding: const EdgeInsets.all(10),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Theme.of(context).primaryColor.withValues(alpha: 0.14),
          Colors.black.withValues(alpha: 0.30),
        ],
      ),
      shadows: [
        BoxShadow(
          color:
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.22),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
      ],
      child: InkWell(
        key: ValueKey(song.id),
        borderRadius: BorderRadius.circular(24),
        onLongPress: () => _showSongInfoSheet(playerController),
        onTap: () {},
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: "player-art-${song.id}",
                child: ImageWidget(
                  size: panelSize,
                  song: song,
                  isPlayerArtImage: true,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.22),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: GlassButton(
                  icon: Icons.search_rounded,
                  size: 42,
                  iconSize: 20,
                  onPressed: playerController.showLyrics,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSurface(
    PlayerController playerController,
    double playerArtImageSize,
  ) {
    return Obx(() {
      final controller = playerController.videoController.value;
      final error = playerController.videoError.value;

      if (playerController.isVideoLoading.isTrue) {
        return _videoFrame(
          playerArtImageSize,
          const Center(child: LoadingIndicator()),
        );
      }

      if (error != null) {
        return _videoFrame(
          playerArtImageSize,
          Center(
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        );
      }

      if (controller == null || !controller.value.isInitialized) {
        return _videoFrame(
          playerArtImageSize,
          const Center(child: Icon(Icons.play_circle_outline, size: 54)),
        );
      }

      return _videoFrame(
        playerArtImageSize,
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      );
    });
  }

  Widget _videoFrame(double size, Widget child) {
    return Container(
      height: size,
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildMusicVisualizer(List<Color> colors, List<int> duration) {
    final controller = _controller;
    if (controller == null) return const SizedBox.shrink();

    return SizedBox(
      height: 50,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(30, (index) {
              final speed = duration[index % duration.length] / 1000;
              final phase = (controller.value * speed + index * 0.13) % 1;
              final normalized = phase <= 0.5 ? phase * 2 : (1 - phase) * 2;
              return Container(
                width: 3,
                height: 6 + normalized * 44,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
