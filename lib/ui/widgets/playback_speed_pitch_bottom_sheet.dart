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

    final speedPresets = [0.75, 0.9, 1.0, 1.1, 1.25, 1.5, 2.0];
    final pitchPresets = [0.8, 0.9, 1.0, 1.1, 1.2];

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

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
                  label: const Text("Reset"),
                );
              }),
            ],
          ),
          const Divider(height: 20),

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
          const SizedBox(height: 10),

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
          const SizedBox(height: 6),

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
                "Vocal Pitch (Key Shift)",
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
          const SizedBox(height: 10),

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
          const SizedBox(height: 6),

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
    );
  }
}
