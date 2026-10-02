import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:palette_generator/palette_generator.dart';

import 'beatz_design.dart';

class ThemeController extends GetxController {
  final primaryColor = Colors.deepPurple[400].obs;
  final textColor = Colors.white24.obs;
  final themedata = Rxn<ThemeData>();
  late Brightness systemBrightness;

  ThemeController() {
    systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    primaryColor.value = Color(Hive.box('appPrefs').get("themePrimaryColor"));

    changeThemeModeType(
        ThemeType.values[Hive.box('appPrefs').get("themeModeType")]);

    _listenSystemBrightness();

    super.onInit();
  }

  void _listenSystemBrightness() {
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    platformDispatcher.onPlatformBrightnessChanged = () {
      systemBrightness = platformDispatcher.platformBrightness;
      changeThemeModeType(
          ThemeType.values[Hive.box('appPrefs').get("themeModeType")],
          sysCall: true);
    };
  }

  void changeThemeModeType(dynamic value, {bool sysCall = false}) {
    if (value == ThemeType.system) {
      themedata.value = _createThemeData(
          null,
          systemBrightness == Brightness.light
              ? ThemeType.light
              : ThemeType.dark);
    } else {
      if (sysCall) return;
      themedata.value = _createThemeData(
          value == ThemeType.dynamic
              ? _createMaterialColor(primaryColor.value!)
              : null,
          value);
    }
  }

  void setTheme(ImageProvider imageProvider) async {
    PaletteGenerator generator =
        await PaletteGenerator.fromImageProvider(imageProvider);
    //final colorList = generator.colors;
    final paletteColor = generator.dominantColor ??
        generator.darkMutedColor ??
        generator.darkVibrantColor ??
        generator.lightMutedColor ??
        generator.lightVibrantColor;
    primaryColor.value = paletteColor!.color;
    textColor.value = paletteColor.bodyTextColor;
    // printINFO(paletteColor.color.computeLuminance().toString());0.11 ref
    if (paletteColor.color.computeLuminance() > 0.10) {
      primaryColor.value = paletteColor.color.withLightness(0.10);
      textColor.value = Colors.white54;
    }
    final primarySwatch = _createMaterialColor(primaryColor.value!);
    themedata.value = _createThemeData(primarySwatch, ThemeType.dynamic,
        textColor: textColor.value,
        titleColorSwatch: _createMaterialColor(textColor.value));
    Hive.box('appPrefs').put("themePrimaryColor", (primaryColor.value!).value);
  }

  /// Every [ThemeType] renders the "Onda" design: dark, light, or the dynamic
  /// palette that follows the colour of the current song ([primaryColor]).
  ThemeData _createThemeData(MaterialColor? primarySwatch, ThemeType themeType,
      {MaterialColor? titleColorSwatch, Color? textColor}) {
    final colors = themeType == ThemeType.light
        ? BeatzColors.light
        : themeType == ThemeType.dynamic && primaryColor.value != null
            ? BeatzColors.tinted(primaryColor.value!)
            : BeatzColors.dark;
    final overlay = colors.isDark ? Brightness.light : Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
          statusBarIconBrightness: overlay,
          statusBarBrightness: colors.isDark ? Brightness.dark : Brightness.light,
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: colors.bg,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: overlay,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false),
    );
    return _beatzTheme(colors);
  }

  ThemeData _beatzTheme(BeatzColors c) {
    final brightness = c.isDark ? Brightness.dark : Brightness.light;
    final base = ThemeData(
      useMaterial3: false,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      primaryColor: c.bg,
      primaryColorDark: c.bg,
      primaryColorLight: c.raised,
      cardColor: c.surface,
      dividerColor: c.line,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.ink,
        onPrimary: c.bg,
        secondary: c.surface,
        onSecondary: c.ink,
        error: const Color(0xFFE5484D),
        onError: Colors.white,
        surface: c.bg,
        onSurface: c.ink,
      ),
      iconTheme: IconThemeData(color: c.ink),
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: c.ink, linearTrackColor: c.line),
      textTheme: TextTheme(
        titleLarge: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: c.ink),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
        titleSmall: TextStyle(color: c.muted),
        bodyLarge: TextStyle(color: c.ink),
        bodyMedium: TextStyle(color: c.muted),
        bodySmall: TextStyle(color: c.muted),
        labelMedium: TextStyle(
            fontWeight: FontWeight.w800, fontSize: 20, color: c.ink),
        labelSmall: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: c.muted),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.bg,
        selectedIconTheme: IconThemeData(color: c.ink),
        unselectedIconTheme: IconThemeData(color: c.muted),
        selectedLabelTextStyle: TextStyle(
            color: c.ink, fontWeight: FontWeight.w800, fontSize: 14),
        unselectedLabelTextStyle:
            TextStyle(color: c.muted, fontWeight: FontWeight.w700),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.raised,
        modalBackgroundColor: c.raised,
        modalBarrierColor: Colors.black54,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      sliderTheme: SliderThemeData(
        inactiveTrackColor: c.line,
        activeTrackColor: c.ink,
        valueIndicatorColor: c.raised,
        thumbColor: c.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusColor: c.ink,
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: c.ink)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      extensions: [c],
    );
    return base.copyWith(
        textTheme: GoogleFonts.nunitoSansTextTheme(base.textTheme));
  }

  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

extension ColorWithHSL on Color {
  HSLColor get hsl => HSLColor.fromColor(this);

  Color withSaturation(double saturation) {
    return hsl.withSaturation(clampDouble(saturation, 0.0, 1.0)).toColor();
  }

  Color withLightness(double lightness) {
    return hsl.withLightness(clampDouble(lightness, 0.0, 1.0)).toColor();
  }

  Color withHue(double hue) {
    return hsl.withHue(clampDouble(hue, 0.0, 360.0)).toColor();
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

enum ThemeType {
  dynamic,
  system,
  dark,
  light,
}
