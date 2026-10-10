import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../player/player_controller.dart';

class PlaybackSpeedPitchBottomSheet extends StatelessWidget {
  const PlaybackSpeedPitchBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Combined 1-Tap Sound Profiles
    final soundProfiles = [
      {
        "name": "Original",
        "speed": 1.0,
        "pitch": 1.0,
        "icon": Icons.music_note_rounded,
      },
      {
        "name": "Slowed + Reverb",
        "speed": 0.80,
        "pitch": 0.80,
        "icon": Icons.water_drop_rounded,
      },
      {
        "name": "Nightcore",
        "speed": 1.25,
        "pitch": 1.20,
        "icon": Icons.bolt_rounded,
      },
      {
        "name": "Deep Bass",
        "speed": 0.90,
        "pitch": 0.80,
        "icon": Icons.graphic_eq_rounded,
      },
      {
        "name": "Sped Up",
        "speed": 1.30,
        "pitch": 1.0,
        "icon": Icons.fast_forward_rounded,
      },
      {
        "name": "Chilled Out",
        "speed": 0.80,
        "pitch": 0.85,
        "icon": Icons.nightlight_round,
      },
    ];

    final speedPresets = [0.75, 0.80, 0.85, 0.9, 1.0, 1.1, 1.25, 1.5, 2.0];
    final pitchPresets = [0.75, 0.8, 0.85, 0.9, 1.0, 1.1, 1.15, 1.2, 1.25];

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Speed & Vocal Pitch",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  final isModified = playerController.playbackSpeed.value != 1.0 ||
                      playerController.playbackPitch.value != 1.0;
                  return TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isModified
                          ? theme.colorScheme.secondary
                          : theme.disabledColor,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: isModified
                        ? () => playerController.resetSpeedAndPitch()
                        : null,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text("Reset All"),
                  );
                }),
              ],
            ),
            const Divider(height: 16),

            // 0. Quick Sound Profiles Section (1-Tap Presets)
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  "Quick Sound Vibes",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () {
                  final currentSpeed = playerController.playbackSpeed.value;
                  final currentPitch = playerController.playbackPitch.value;

                  return Row(
                    children: soundProfiles.map((profile) {
                      final targetSpeed = profile["speed"] as double;
                      final targetPitch = profile["pitch"] as double;
                      final isSelected =
                          (currentSpeed - targetSpeed).abs() < 0.03 &&
                              (currentPitch - targetPitch).abs() < 0.03;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            playerController.setPlaybackSpeed(targetSpeed);
                            playerController.setPlaybackPitch(targetPitch);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.secondary
                                  : (isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.secondary
                                    : (isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.08)),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  profile["icon"] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  profile["name"] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // 1. Playback Speed Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Playback Speed (Tempo)",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Obx(
                  () => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${playerController.playbackSpeed.value.toStringAsFixed(2)}x",
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Speed Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                  children: speedPresets.map((speed) {
                    final isSelected =
                        (playerController.playbackSpeed.value - speed).abs() <
                            0.02;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text("${speed}x"),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.secondary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            playerController.setPlaybackSpeed(speed);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Speed Stepper & Slider
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                  onPressed: () {
                    final current = playerController.playbackSpeed.value;
                    final next = (current - 0.05).clamp(0.5, 2.0);
                    playerController
                        .setPlaybackSpeed(double.parse(next.toStringAsFixed(2)));
                  },
                ),
                Expanded(
                  child: Obx(
                    () => Slider(
                      value: playerController.playbackSpeed.value.clamp(0.5, 2.0),
                      min: 0.5,
                      max: 2.0,
                      divisions: 30,
                      activeColor: theme.colorScheme.secondary,
                      label:
                          "${playerController.playbackSpeed.value.toStringAsFixed(2)}x",
                      onChanged: (value) {
                        playerController.setPlaybackSpeed(
                            double.parse(value.toStringAsFixed(2)));
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                  onPressed: () {
                    final current = playerController.playbackSpeed.value;
                    final next = (current + 0.05).clamp(0.5, 2.0);
                    playerController
                        .setPlaybackSpeed(double.parse(next.toStringAsFixed(2)));
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Vocal Pitch Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Vocal Pitch (Key Modulation)",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Obx(
                  () => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      playerController.playbackPitch.value == 1.0
                          ? "Original (1.0x)"
                          : "${playerController.playbackPitch.value.toStringAsFixed(2)}x",
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Pitch Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                  children: pitchPresets.map((pitch) {
                    final isSelected =
                        (playerController.playbackPitch.value - pitch).abs() <
                            0.02;
                    String label = "${pitch}x";
                    if (pitch == 1.0) label = "Normal";
                    if (pitch == 1.2) label = "Nightcore";
                    if (pitch == 0.85) label = "Slowed";
                    if (pitch == 0.8) label = "Deep Bass";

                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: theme.colorScheme.secondary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodyMedium?.color,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            playerController.setPlaybackPitch(pitch);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Pitch Stepper & Slider
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 22),
                  onPressed: () {
                    final current = playerController.playbackPitch.value;
                    final next = (current - 0.05).clamp(0.7, 1.3);
                    playerController
                        .setPlaybackPitch(double.parse(next.toStringAsFixed(2)));
                  },
                ),
                Expanded(
                  child: Obx(
                    () => Slider(
                      value: playerController.playbackPitch.value.clamp(0.7, 1.3),
                      min: 0.7,
                      max: 1.3,
                      divisions: 24,
                      activeColor: theme.colorScheme.secondary,
                      label:
                          "${playerController.playbackPitch.value.toStringAsFixed(2)}x",
                      onChanged: (value) {
                        playerController.setPlaybackPitch(
                            double.parse(value.toStringAsFixed(2)));
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                  onPressed: () {
                    final current = playerController.playbackPitch.value;
                    final next = (current + 0.05).clamp(0.7, 1.3);
                    playerController
                        .setPlaybackPitch(double.parse(next.toStringAsFixed(2)));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
