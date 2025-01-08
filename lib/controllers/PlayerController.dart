import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../models/song.dart';

class PlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  final DefaultCacheManager cacheManager = DefaultCacheManager();

  var isLoading = false.obs; // Loading indicator
  var currentSong = ''.obs;
  var currentSongName = ''.obs;
  var isPlaying = false.obs;
  var isPaused = false.obs;
  var songList = <Song>[].obs;
  var downloadedSongs = <String>{}.obs;
  var currentIndex = 0.obs;

  var volume = 1.0.obs;

  // Player ================================================

  Future<void> _initializePlayer() async {
    await fetchMusicUrls();
    await _checkNewAndDownloadedSongs();
    _initListeners();

    currentSongName = currentSongName;
    currentIndex.value != -1
        ? songList[currentIndex.value].name
        : 'No song playing';
    isPlaying = isPlaying;
    player.setVolume(volume.value);
    ever(volume, (value) => player.setVolume(value));
  }

  void setVolume(double newVolume) {
    volume.value = newVolume;
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songList.length) return;

    currentIndex.value = index; // Update index first
    currentSongName.value = songList[index].name; // Update song name

    final song = songList[index];
    String filePath = await _downloadAndCacheFile(song.url);

    await player.setFilePath(filePath); // Set the file path for the player
    await player.play(); // Start playback

    currentSong.value = song.url;
    isPlaying.value = true;
    isPaused.value = false;
  }

  void _initListeners() {
    player.playbackEventStream.listen((event) {
      isPlaying.value = player.playing;
    });
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        nextSong();
      }
    });
  }

  Future<void> pause() async {
    await player.pause();
    isPlaying.value = false;
    isPaused.value = true;
  }

  void nextSong() {
    currentIndex.value = (currentIndex.value + 1) % songList.length;
    playSong(currentIndex.value);
  }

  void previousSong() {
    currentIndex.value =
        (currentIndex.value - 1 + songList.length) % songList.length;
    playSong(currentIndex.value);
  }

  // Api ================================================

  Future<void> fetchMusicUrls() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Song'))
      ..orderByAscending('updatedAt'); // Sort by updatedAt in descending order

    final response = await query.query();

    if (response.success && response.results != null) {
      Logger().e('response.success${response.success}');

      final fetchedSongs = response.results!
          .map((result) => Song.fromParseObject(result as ParseObject))
          .toList();

      songList.value = fetchedSongs; // No need to sort locally anymore
    } else {
      Logger().e('Failed to load songs: ${response.error?.message}');
    }
  }

  Future<void> _checkNewAndDownloadedSongs() async {
    final cachedUrls = <String>{};
    for (var song in songList) {
      var file = await cacheManager.getFileFromCache(song.url);
      if (file != null) {
        cachedUrls.add(song.url);
        downloadedSongs.add(song.url);
      }
    }
    final serverUrls = songList.map((song) => song.url).toSet();
    if (!cachedUrls.containsAll(serverUrls)) {
      showDownloadDialog();
    }
  }

  Future<void> downloadAllSongs() async {
    for (var song in songList) {
      if (!downloadedSongs.contains(song.url)) {
        await _downloadAndCacheFile(song.url);
      }
    }
    Logger().d('All songs downloaded');
  }

  Future<void> downloadSong(int index) async {
    if (index < 0 || index >= songList.length) return;
    final song = songList[index];
    await _downloadAndCacheFile(song.url);
    Get.snackbar(
      'Download Complete',
      '${song.name} is now available offline.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  Future<String> _downloadAndCacheFile(String url) async {
    try {
      var file = await cacheManager.getSingleFile(url);
      downloadedSongs.add(url);
      return file.path;
    } catch (e) {
      Logger().e('Error downloading file: $e');
      return '';
    }
  }

  // LifeCycle ================================================

  @override
  void onInit() async {
    super.onInit();
    await _initializePlayer();
  }

  @override
  void onClose() async {
    await player.dispose();
    super.onClose();
  }

  // Dialogs ================================================

  void showDownloadDialog() {
    Get.defaultDialog(
      title: 'Download Songs',
      middleText: 'New songs are available. Would you like to download them?',
      confirm: ElevatedButton(
        onPressed: () {
          downloadAllSongs();
          Get.back();
        },
        child: const Text('Download All'),
      ),
      cancel: ElevatedButton(
        onPressed: Get.back,
        child: const Text('Cancel'),
      ),
    );
  }
}
