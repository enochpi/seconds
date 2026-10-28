import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Turns an off-screen card (wrapped in a RepaintBoundary with [key]) into
/// a PNG and shares or saves it.
class ShareService {
  static const String hashtags = "#7Seconds #7SecondsGame #ReactionTime";

  static const String storeLink =
      "https://play.google.com/store/apps/details?id=com.spartalabs.sevenseconds";

  static Future<Uint8List> capture(GlobalKey key) async {
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 180));

    final cardContext = key.currentContext;

    if (cardContext == null) {
      throw Exception("Share card is not ready yet");
    }

    final boundary = cardContext.findRenderObject() as RenderRepaintBoundary;

    if (boundary.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 180));
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception("Could not convert image");
    }

    return byteData.buffer.asUint8List();
  }

  /// Opens the share sheet with the card image and [text]. Falls back to
  /// text only if the image can't be made. Returns true unless the player
  /// cancelled. Throws if sharing failed completely.
  static Future<bool> shareCard(
    GlobalKey key, {
    required String text,
    String subject = "Can you beat me in 7 Seconds?",
  }) async {
    try {
      final pngBytes = await capture(key);

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/seven_seconds_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await file.writeAsBytes(pngBytes);

      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: subject,
      );

      // Some Android apps report "unavailable" even after sharing, so only
      // an explicit cancel counts as not shared.
      return result.status != ShareResultStatus.dismissed;
    } catch (e) {
      // Image rendering failed (e.g. low memory): share the text instead.
      final result = await Share.share(text, subject: subject);
      return result.status != ShareResultStatus.dismissed;
    }
  }

  /// Saves the card to the photo gallery.
  static Future<void> saveCard(GlobalKey key) async {
    final pngBytes = await capture(key);

    await Gal.putImageBytes(
      pngBytes,
      name: 'seven_seconds_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
