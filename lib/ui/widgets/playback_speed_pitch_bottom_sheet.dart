import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../player/player_controller.dart';

class PlaybackSpeedPitchBottomSheet extends StatelessWidget {
  const PlaybackSpeedPitchBottomSheet({super.key});

  static const List<double> speedPresets = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0
  ];

  static const List<double> pitchPresets = [
    0.8,
    0.9,
    1.0,
    1.1,
    1.2,
    1.3
  ];

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + Get.mediaQuery.padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header with Title & Reset Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Playback Speed & Pitch",
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
                    ),
                    onPressed: isModified
                        ? () => playerController.resetSpeedAndPitch()
                        : null,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Reset"),
                  );
                }),
              ],
            ),
            const Divider(height: 20),

            // Speed Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Speed",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
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

            // Speed Presets Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                  children: speedPresets.map((speed) {
                    final isSelected =
                        (playerController.playbackSpeed.value - speed).abs() <
                            0.02;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
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
            const SizedBox(height: 8),

            // Speed Continuous Slider
            Obx(
              () => Slider(
                value: playerController.playbackSpeed.value.clamp(0.5, 2.0),
                min: 0.5,
                max: 2.0,
                divisions: 30,
                label:
                    "${playerController.playbackSpeed.value.toStringAsFixed(2)}x",
                onChanged: (value) {
                  playerController.setPlaybackSpeed(
                      double.parse(value.toStringAsFixed(2)));
                },
              ),
            ),

            const SizedBox(height: 12),

            // Pitch Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pitch (Key Modulation)",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
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
                          ? "Normal (1.0x)"
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

            // Pitch Presets Chips
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
                    if (pitch == 0.8) label = "Deep";

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
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
            const SizedBox(height: 8),

            // Pitch Continuous Slider
            Obx(
              () => Slider(
                value: playerController.playbackPitch.value.clamp(0.7, 1.3),
                min: 0.7,
                max: 1.3,
                divisions: 24,
                label:
                    "${playerController.playbackPitch.value.toStringAsFixed(2)}x",
                onChanged: (value) {
                  playerController.setPlaybackPitch(
                      double.parse(value.toStringAsFixed(2)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
