import 'dart:ui' as ui;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/tempo_template.dart';

abstract class TempoCuePlayer {
  Future<void> playCue({
    required TempoCueSettings settings,
    required bool accent,
  });
}

class SystemTempoCuePlayer implements TempoCuePlayer {
  const SystemTempoCuePlayer();

  @override
  Future<void> playCue({
    required TempoCueSettings settings,
    required bool accent,
  }) async {
    if (settings.audible || settings.spoken) {
      await SystemSound.play(
        accent ? SystemSoundType.alert : SystemSoundType.click,
      );
    }
    if (settings.spoken) {
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isNotEmpty) {
        await SemanticsService.sendAnnouncement(
          views.first,
          accent ? 'Accent cue' : 'Tempo cue',
          ui.TextDirection.ltr,
        );
      }
    }
    if (settings.vibration) {
      if (accent) {
        await HapticFeedback.heavyImpact();
      } else {
        await HapticFeedback.lightImpact();
      }
    }
  }
}

final tempoCuePlayerProvider = Provider<TempoCuePlayer>(
  (ref) => const SystemTempoCuePlayer(),
);
