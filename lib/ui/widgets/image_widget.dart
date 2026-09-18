import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../screens/Settings/settings_screen_controller.dart';
import '/models/artist.dart';
import '../../models/album.dart';
import '../../models/playlist.dart';

class ImageWidget extends StatelessWidget {
  const ImageWidget({
    super.key,
    this.song,
    this.playlist,
    this.album,
    this.artist,
    required this.size,
    this.isPlayerArtImage = false,
  });
  final MediaItem? song;
  final Playlist? playlist;
  final Album? album;
  final bool isPlayerArtImage;
  final Artist? artist;
  final double size;

  @override
  Widget build(BuildContext context) {
    String imageUrl = song != null
        ? song!.artUri.toString()
        : playlist != null
            ? playlist!.thumbnailUrl
            : album != null
                ? album!.thumbnailUrl
                : artist != null
                    ? artist!.thumbnailUrl
                    : "";
    // String cacheKey = song != null
    //     ? "${song!.id}_song"
    //     : playlist != null
    //         ? "${playlist!.playlistId}_playlist"
    //         : album != null
    //             ? "${album!.browseId}_album"
    //             : artist != null
    //                 ? "${artist!.browseId}_artist"
    //                 : "";

    final String supportDir =
        Get.find<SettingsScreenController>().supportDirPath;
    final File? localThumbFile =
        (song != null) ? File("$supportDir/thumbnails/${song!.id}.png") : null;
    final bool hasLocalFile =
        localThumbFile != null && localThumbFile.existsSync();

    final bool isLocalUri = imageUrl.startsWith("file://") ||
        (imageUrl.startsWith("/") && !imageUrl.startsWith("http"));
    final File? localArtFile = isLocalUri
        ? File(imageUrl.startsWith("file://")
            ? Uri.parse(imageUrl).toFilePath()
            : imageUrl)
        : null;
    final bool hasLocalArt = localArtFile != null && localArtFile.existsSync();

    Widget buildCachedImage() {
      if (imageUrl.isEmpty || isLocalUri) {
        return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: artist != null ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: artist != null ? null : BorderRadius.circular(10),
            ),
            child: Image.asset(
                "assets/icons/${song != null ? "song" : artist != null ? "artist" : "album"}.png"));
      }

      return CachedNetworkImage(
        height: size,
        width: size,
        fadeInDuration: const Duration(milliseconds: 100),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheHeight: isPlayerArtImage
            ? 500
            : (size > 0 ? (size * 2).toInt().clamp(80, 400) : 180),
        memCacheWidth: isPlayerArtImage
            ? 500
            : (size > 0 ? (size * 2).toInt().clamp(80, 400) : 180),
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) {
          return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: artist != null ? BoxShape.circle : BoxShape.rectangle,
                borderRadius:
                    artist != null ? null : BorderRadius.circular(10),
              ),
              child: Image.asset(
                  "assets/icons/${song != null ? "song" : artist != null ? "artist" : "album"}.png"));
        },
        progressIndicatorBuilder: ((_, __, ___) => Shimmer.fromColors(
            baseColor: Colors.grey[500]!,
            highlightColor: Colors.grey[300]!,
            enabled: true,
            direction: ShimmerDirection.ltr,
            child: Container(
              decoration: BoxDecoration(
                shape:
                    artist != null ? BoxShape.circle : BoxShape.rectangle,
                borderRadius:
                    artist != null ? null : BorderRadius.circular(10),
                color: Colors.white54,
              ),
            ))),
      );
    }

    return Container(
      height: size,
      width: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: artist != null ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: artist != null ? null : BorderRadius.circular(5),
      ),
      child: hasLocalFile
          ? Image.file(
              localThumbFile,
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error,
                  StackTrace? stackTrace) {
                return buildCachedImage();
              },
            )
          : (hasLocalArt
              ? Image.file(
                  localArtFile,
                  height: size,
                  width: size,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object error,
                      StackTrace? stackTrace) {
                    return buildCachedImage();
                  },
                )
              : buildCachedImage()),
    );
  }
}
