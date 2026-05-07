import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:newton_particles/newton_particles.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:video_player/video_player.dart';
import '../widgets/buttonplay_animation.dart';
import '../widgets/custom_lyricui.dart';
import '../widgets/custom_progress.dart';
import '../widgets/loader.dart';
import '../../utils/helper.dart';
import '../widgets/up_next_queue.dart';
import '/ui/player/player_controller.dart';
import '../screens/Settings/settings_screen_controller.dart';
import '/ui/utils/theme_controller.dart';
import '/ui/widgets/marqwee_widget.dart';
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
            ? 0.26
            : isCompactHeight
                ? 0.30
                : 0.34);
    final playerArtImageSize = math.max(
      170.0,
      math.min(320.0, math.min(availableWidth, maxArtworkByHeight)),
    );
    final collapsedPanelHeight = 65.0 + safeArea.bottom;
    final controlsBottomGap =
        collapsedPanelHeight + (isTinyHeight ? 10.0 : 14.0);
    final playButtonRadius = isTinyHeight
        ? 28.0
        : isCompactHeight
            ? 31.0
            : 34.0;
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
          child: Container(
            color: Theme.of(context).bottomSheetTheme.modalBarrierColor,
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
                color: Theme.of(context).primaryColor.withValues(alpha: 0.90),
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
                    () => playerController.showLyricsflag.value
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: ToggleSwitch(
                              minWidth: 90.0,
                              cornerRadius: 20.0,
                              activeBgColors: [
                                [
                                  Theme.of(context)
                                      .primaryColor
                                      .withLightness(0.4)
                                ],
                                [
                                  Theme.of(context)
                                      .primaryColor
                                      .withLightness(0.4)
                                ],
                              ],
                              activeFgColor: Colors.white,
                              inactiveBgColor:
                                  Theme.of(context).colorScheme.secondary,
                              inactiveFgColor: Colors.white,
                              initialLabelIndex:
                                  playerController.lyricsMode.value,
                              totalSwitches: 2,
                              labels: ['synced'.tr, 'plain'.tr],
                              radiusStyle: true,
                              onToggle: playerController.changeLyricsMode,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Obx(
                    () => playerController.currentSong.value != null
                        ? Stack(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Stack(
                                  key: ValueKey(
                                      playerController.currentSong.value),
                                  children: [
                                    Obx(() => Opacity(
                                          opacity: playerController
                                                  .showLyricsflag.isTrue
                                              ? 0.0
                                              : 1.0,
                                          child: playerController
                                                      .mediaMode.value ==
                                                  PlayerMediaMode.video
                                              ? _buildVideoSurface(
                                                  playerController,
                                                  playerArtImageSize,
                                                )
                                              : RippleAnimation(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withLightness(0.4),
                                                  minRadius:
                                                      playerArtImageSize / 2 +
                                                          10,
                                                  repeat: playerController
                                                          .buttonState.value ==
                                                      PlayButtonState.playing,
                                                  ripplesCount: 6,
                                                  child: AnimatedBuilder(
                                                    animation: _controller!,
                                                    builder: (context, child) {
                                                      return Transform.rotate(
                                                        angle:
                                                            _controller!.value *
                                                                2 *
                                                                3.1416,
                                                        child: child,
                                                      );
                                                    },
                                                    child: InkWell(
                                                      key: ValueKey(
                                                          playerController
                                                              .currentSong
                                                              .value),
                                                      onLongPress: () {
                                                        showModalBottomSheet(
                                                          constraints:
                                                              const BoxConstraints(
                                                                  maxWidth:
                                                                      500),
                                                          shape:
                                                              const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .vertical(
                                                              top: Radius
                                                                  .circular(
                                                                      10.0),
                                                            ),
                                                          ),
                                                          isScrollControlled:
                                                              true,
                                                          context:
                                                              playerController
                                                                  .homeScaffoldkey
                                                                  .currentState!
                                                                  .context,
                                                          barrierColor: Colors
                                                              .transparent
                                                              .withAlpha(100),
                                                          builder: (context) =>
                                                              SongInfoBottomSheet(
                                                            playerController
                                                                .currentSong
                                                                .value!,
                                                            calledFromPlayer:
                                                                true,
                                                          ),
                                                        ).whenComplete(() =>
                                                            Get.delete<
                                                                SongInfoController>());
                                                      },
                                                      onTap: () {
                                                        playerController
                                                            .showLyrics();
                                                      },
                                                      child: Container(
                                                        height:
                                                            playerArtImageSize,
                                                        width:
                                                            playerArtImageSize,
                                                        clipBehavior:
                                                            Clip.antiAlias,
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: ImageWidget(
                                                          size:
                                                              playerArtImageSize,
                                                          song: playerController
                                                              .currentSong
                                                              .value!,
                                                          isPlayerArtImage:
                                                              true,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        )),
                                    Obx(
                                      () =>
                                          playerController.showLyricsflag.isTrue
                                              ? Stack(
                                                  children: [
                                                    Positioned.fill(
                                                      child: Newton(
                                                        activeEffects: [
                                                          RainEffect(
                                                            particleConfiguration:
                                                                ParticleConfiguration(
                                                              shape:
                                                                  CircleShape(),
                                                              size: const Size(
                                                                  5, 5),
                                                              color:
                                                                  const SingleParticleColor(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            effectConfiguration:
                                                                const EffectConfiguration(),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        playerController
                                                            .showLyrics();
                                                      },
                                                      child: Container(
                                                        height:
                                                            playerArtImageSize *
                                                                1.2,
                                                        width:
                                                            playerArtImageSize *
                                                                1.2,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.5),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(15),
                                                        ),
                                                        child: Stack(
                                                          children: [
                                                            Obx(
                                                              () => playerController
                                                                      .isLyricsLoading
                                                                      .isTrue
                                                                  ? const Center(
                                                                      child:
                                                                          LoadingIndicator())
                                                                  : playerController
                                                                              .lyricsMode
                                                                              .toInt() ==
                                                                          1
                                                                      ? Center(
                                                                          child:
                                                                              SingleChildScrollView(
                                                                            physics:
                                                                                const BouncingScrollPhysics(),
                                                                            padding:
                                                                                EdgeInsets.symmetric(
                                                                              horizontal: 0,
                                                                              vertical: playerArtImageSize / 3.5,
                                                                            ),
                                                                            child:
                                                                                Obx(
                                                                              () => Text(
                                                                                playerController.lyrics["plainLyrics"] == "NA" ? "lyricsNotAvailable".tr : playerController.lyrics["plainLyrics"],
                                                                                textAlign: TextAlign.center,
                                                                                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                                                                      fontSize: 20,
                                                                                      color: Theme.of(context).primaryColor.withLightness(0.4),
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      : IgnorePointer(
                                                                          child:
                                                                              LyricsReader(
                                                                            padding:
                                                                                const EdgeInsets.only(left: 5, right: 5),
                                                                            lyricUi:
                                                                                CustomLyricUI(
                                                                              primaryColor: Theme.of(context).primaryColor.withLightness(0.2),
                                                                              highlightColor: Theme.of(context).primaryColor.withLightness(0.4),
                                                                              fontSize: 25,
                                                                              highlightFontSize: 28,
                                                                            ),
                                                                            position:
                                                                                playerController.progressBarStatus.value.current.inMilliseconds,
                                                                            model:
                                                                                LyricsModelBuilder.create().bindLyricToMain(playerController.lyrics['synced'].toString()).getModel(),
                                                                            emptyBuilder: () =>
                                                                                Center(
                                                                              child: Text(
                                                                                "syncedLyricsNotAvailable".tr,
                                                                                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                                                                      fontSize: 20,
                                                                                      color: Theme.of(context).primaryColor.withLightness(0.4),
                                                                                    ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                            ),
                                                            IgnorePointer(
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              15),
                                                                  gradient:
                                                                      LinearGradient(
                                                                    begin: Alignment
                                                                        .topCenter,
                                                                    end: Alignment
                                                                        .bottomCenter,
                                                                    colors: [
                                                                      Theme.of(
                                                                              context)
                                                                          .primaryColor
                                                                          .withValues(
                                                                              alpha: 0.90),
                                                                      Colors
                                                                          .transparent,
                                                                      Colors
                                                                          .transparent,
                                                                      Colors
                                                                          .transparent,
                                                                      Theme.of(
                                                                              context)
                                                                          .primaryColor
                                                                          .withValues(
                                                                              alpha: 0.90),
                                                                    ],
                                                                    stops: const [
                                                                      0,
                                                                      0.2,
                                                                      0.5,
                                                                      0.8,
                                                                      1
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Container(),
                  ),
                  SizedBox(height: isTinyHeight ? 10 : 16),
                  SizedBox(height: isTinyHeight ? 6 : 10),
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
                  Obx(() {
                    return MarqueeWidget(
                      child: Text(
                        playerController.currentSong.value != null
                            ? playerController.currentSong.value!.title
                            : "NA",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    );
                  }),
                  SizedBox(height: isTinyHeight ? 6 : 10),
                  GetX<PlayerController>(builder: (controller) {
                    return MarqueeWidget(
                      child: Text(
                        playerController.currentSong.value != null
                            ? controller.currentSong.value!.artist!
                            : "NA",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  }),
                  SizedBox(height: isTinyHeight ? 10 : 20),
                  GetX<PlayerController>(builder: (controller) {
                    return CustomProgressBar(
                      // Aquí se usa la barra de progreso personalizada
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
                  if (_shouldShowPlayerControls())
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: playerController.toggleFavourite,
                          icon: Obx(() => Icon(
                                playerController.isCurrentSongFav.isFalse
                                    ? Icons.favorite_border_rounded
                                    : Icons.favorite_rounded,
                                color: Theme.of(context)
                                    .primaryColor
                                    .withLightness(0.5),
                              )),
                        ),
                        _previousButton(playerController, context),
                        CircleAvatar(
                          radius: playButtonRadius,
                          child: _playButton(),
                        ),
                        _nextButton(playerController, context),
                        Obx(() {
                          return IconButton(
                            onPressed: playerController.toggleLoopMode,
                            icon: Icon(
                              Icons.all_inclusive,
                              color: playerController.isLoopModeEnabled.value
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withLightness(0.5)
                                  : Theme.of(context)
                                      .textTheme
                                      .titleLarge!
                                      .color,
                            ),
                          );
                        }),
                      ],
                    ),
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

  Widget _playButton() {
    return GetX<PlayerController>(builder: (controller) {
      final buttonState = controller.buttonState.value;
      bool isPlaying = buttonState == PlayButtonState.playing;

      return PlayButton(
        isPlaying: isPlaying,
        playIcon: Icon(Icons.play_arrow,
            color: Theme.of(context).primaryColor.withLightness(0.5), size: 40),
        pauseIcon: Icon(Icons.pause,
            color: Theme.of(context).primaryColor.withLightness(0.5), size: 40),
        onPressed: () {
          if (buttonState == PlayButtonState.paused) {
            controller.play(); // Cambiar a estado de reproducción
          } else if (buttonState == PlayButtonState.playing) {
            controller.pause(); // Cambiar a estado de pausa
          }
        },
      );
    });
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

  Widget _previousButton(
      PlayerController playerController, BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.skip_previous_rounded,
        color: Theme.of(context).primaryColor.withLightness(0.5),
      ),
      iconSize: 30,
      onPressed: playerController.prev,
    );
  }

  Widget _nextButton(PlayerController playerController, BuildContext context) {
    return Obx(() {
      final isLastSong = playerController.currentQueue.isEmpty ||
          (playerController.currentQueue.last.id ==
              playerController.currentSong.value?.id);
      return IconButton(
        icon: Icon(
          Icons.skip_next_rounded,
          color: Theme.of(context).primaryColor.withLightness(0.5),
        ),
        iconSize: 30,
        onPressed: isLastSong ? null : playerController.next,
      );
    });
  }
}
