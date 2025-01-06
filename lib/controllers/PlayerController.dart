import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/song.dart';

class PlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  var currentSong = ''.obs;
  var currentSongName = ''.obs;
  var isPlaying = false.obs;
  var isPaused = false.obs;
  var songList = <Song>[].obs;
  var downloadedSongs = <String>{}.obs; // Set of downloaded song URLs
  var currentIndex = 0.obs;

  final DefaultCacheManager cacheManager = DefaultCacheManager();

  @override
  void onInit() async {
    super.onInit();
    await _checkFirstTimeUser();
    await _fetchMusicUrls();
    _initListeners();
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime || await _hasNewSongs()) {
      _showDownloadDialog();
      await prefs.setBool('isFirstTime', false); // Mark as not first time
    }
  }

  Future<bool> _hasNewSongs() async {
    final cachedUrls = <String>{};
    for (var song in songList) {
      var file = await cacheManager.getFileFromCache(song.url);
      if (file != null) {
        cachedUrls.add(song.url);
      }
    }
    final serverUrls = songList.map((song) => song.url).toSet();
    return !cachedUrls.containsAll(serverUrls);
  }

  Future<void> _fetchMusicUrls() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Song'));
    final response = await query.query();

    if (response.success && response.results != null) {
      songList.value = response.results!
          .map((result) => Song.fromParseObject(result as ParseObject))
          .toList();
      await _checkDownloadedSongs();
    } else {
      Logger().e('Failed to load songs: ${response.error?.message}');
    }
  }

  Future<void> _checkDownloadedSongs() async {
    for (var song in songList) {
      var file = await cacheManager.getFileFromCache(song.url);
      if (file != null) {
        downloadedSongs.add(song.url); // Mark as downloaded
      }
    }
  }

  void _showDownloadDialog() {
    Get.defaultDialog(
      title: 'Download Songs',
      middleText: 'Would you like to download all songs for offline use?',
      confirm: ElevatedButton(
        onPressed: () {
          downloadAllSongs();
          Get.back();
        },
        child: Text('Download All'),
      ),
      cancel: ElevatedButton(
        onPressed: Get.back,
        child: Text('Cancel'),
      ),
    );
  }

  Future<void> downloadAllSongs() async {
    for (var song in songList) {
      await _downloadAndCacheFile(song.url);
    }
    Logger().d('All songs downloaded');
  }

  Future<String> _downloadAndCacheFile(String url) async {
    try {
      var file = await cacheManager.getSingleFile(url);
      downloadedSongs.add(url); // Update downloaded songs
      return file.path;
    } catch (e) {
      Logger().e('Error downloading file: $e');
      return '';
    }
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= songList.length) return;
    currentIndex.value = index;
    final song = songList[index];
    String filePath = await _downloadAndCacheFile(song.url);
    await player.setFilePath(filePath);
    await player.play();
    currentSong.value = song.url;
    currentSongName.value = song.name;
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
    currentIndex.value = (currentIndex.value - 1 + songList.length) % songList.length;
    playSong(currentIndex.value);
  }

  @override
  void onClose() async {
    await player.dispose();
    super.onClose();
  }
}
