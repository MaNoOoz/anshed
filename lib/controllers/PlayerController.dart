import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:convert'; // Import JSON encoding and decoding

import '../models/song.dart';

enum PlayerState {
  loading,
  playing,
  paused,
  stopped,
  error,
}

class PlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  final DefaultCacheManager cacheManager = DefaultCacheManager();
  final String jsonCacheKey = 'cachedSongs'; // Key to store the JSON data

  var currentSong = Rxn<Song>();
  var songList = <Song>[].obs;
  var downloadedSongs = <Song>[].obs;
  var currentIndex = 0.obs;
  var volume = 1.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadCachedSongs();
    fetchMusicUrls();
    _initListeners();
    player.setVolume(volume.value);
    ever(volume, (value) => player.setVolume(value));
  }

  @override
  void onClose() {
    player.dispose();
    super.onClose();
  }

  // Player ================================================

  void setVolume(double newVolume) {
    volume.value = newVolume;
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songList.length) return;
    try {
      currentIndex.value = index;
      currentSong.value = songList[index];
      final song = songList[index];
      String filePath = await _downloadAndCacheFile(song.url);
      await player.setFilePath(filePath);
      await player.play();
    } catch (e) {
      Logger().e('Error playing song: $e');
    }
  }

  Future<void> pause() async {
    try {
      await player.pause();
    } catch (e) {
      Logger().e('Error pausing song: $e');
    }
  }

  Future<void> nextSong() async {
    if (songList.isEmpty) return;
    currentIndex.value = (currentIndex.value + 1) % songList.length;
    await playSong(currentIndex.value);
  }

  Future<void> previousSong() async {
    if (songList.isEmpty) return;
    currentIndex.value =
        (currentIndex.value - 1 + songList.length) % songList.length;
    await playSong(currentIndex.value);
  }

  // Api ================================================

  Future<void> fetchMusicUrls() async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Song'))
        ..orderByDescending('updatedAt');

      final response = await query.query();

      if (response.success && response.results != null) {
        final fetchedSongs = response.results!
            .map((result) => Song.fromParseObject(result as ParseObject))
            .toList();

        songList.value = fetchedSongs;

        // Cache the JSON data
        await cacheManager.putFile(
          jsonCacheKey,
          utf8.encode(jsonEncode(fetchedSongs.map((song) => song.toJson()).toList())),
          key: jsonCacheKey,
        );
      } else {
        _showErrorSnackbar("تحقق من إتصالك بالأنترنت");
        Logger().e('Failed to load songs: ${response.error?.message}');
      }
    } catch (e) {
      _showErrorSnackbar("حدث خطأ أثناء جلب الأغاني");
      Logger().e('Error fetching music URLs: $e');
    }
  }

  // Cache ================================================

  Future<void> loadCachedSongs() async {
    try {
      var file = await cacheManager.getFileFromCache(jsonCacheKey);
      if (file != null) {
        final jsonString = await file.file.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<Song> cachedSongs = jsonData.map((e) => Song.fromJson(e)).toList();
        downloadedSongs.addAll(cachedSongs);
      }
    } catch (e) {
      Logger().e('Error loading cached songs: $e');
    }
  }

  Future<void> downloadSong(int index) async {
    if (index < 0 || index >= songList.length) return;
    try {
      final song = songList[index];
      await _downloadAndCacheFile(song.url);
      showSuccessSnackbar('${song.name} is now available offline.');
    } catch (e) {
      _showErrorSnackbar("حدث خطأ أثناء تحميل الأغنية");
      Logger().e('Error downloading song: $e');
    }
  }

  Future<String> _downloadAndCacheFile(String url) async {
    try {
      var file = await cacheManager.getSingleFile(url);
      downloadedSongs.add(Song(name: "Offline Song", url: url, updatedAt: DateTime.now()));
      return file.path;
    } catch (e) {
      _showErrorSnackbar("حدث خطأ أثناء تحميل الملف");
      Logger().e('Error downloading file: $e');
      return '';
    }
  }

  // LifeCycle ================================================

  void _initListeners() {
    player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        nextSong();
      }
    });
  }

  // SnackBar ================================================

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      "Error",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  void showSuccessSnackbar(String message) {
    Get.snackbar(
      "Success",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }
}
