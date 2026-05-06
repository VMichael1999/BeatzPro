///Custom

import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLyricUI extends LyricUI {
  final Color primaryColor;
  final Color highlightColor;
  final double fontSize;
  final double highlightFontSize;

  CustomLyricUI({
    required this.primaryColor,
    required this.highlightColor,
    required this.fontSize,
    required this.highlightFontSize,
  });

  @override
  TextStyle getPlayingExtTextStyle() {
    return GoogleFonts.acme(
      color: highlightColor,
      fontSize: highlightFontSize,
      shadows: [
        // Shadow(blurRadius: 10.0, color: Colors.white, offset: Offset(0, 0)),
        // Shadow(blurRadius: 20.0, color: Colors.white, offset: Offset(0, 0)),
      ],
    );
  }

  @override
  TextStyle getPlayingMainTextStyle() {
    return GoogleFonts.acme(
      color: highlightColor,
      fontSize: highlightFontSize,
      fontWeight: FontWeight.bold,
      shadows: [
        // Shadow(blurRadius: 10.0, color: Colors.white, offset: Offset(0, 0)),
        // Shadow(blurRadius: 20.0, color: Colors.white, offset: Offset(0, 0)),
      ],
    );
  }

  @override
  TextStyle getOtherMainTextStyle() {
    return GoogleFonts.acme(
      color: primaryColor,
      fontSize: fontSize,
      shadows: [
        // Shadow(blurRadius: 5.0, color: Colors.white, offset: Offset(0, 0)),
      ],
    );
  }

  @override
  TextStyle getOtherExtTextStyle() {
    return GoogleFonts.acme(
      color: primaryColor.withOpacity(0.7),
      fontSize: fontSize - 2,
      shadows: [
        // Shadow(blurRadius: 5.0, color: Colors.white, offset: Offset(0, 0)),
      ],
    );
  }

  @override
  double getInlineSpace() {
    return 20.0;
  }

  @override
  double getLineSpace() {
    return 10.0;
  }

  @override
  LyricAlign getLyricHorizontalAlign() {
    return LyricAlign.CENTER;
  }

  @override
  double getPlayingLineBias() {
    return 0.5;
  }
}