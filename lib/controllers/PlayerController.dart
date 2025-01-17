import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/song.dart';

class PlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  final DefaultCacheManager cacheManager = DefaultCacheManager();
  final String jsonCacheKey = 'cachedSongs';
  final String prefsKey = 'downloadedSongs';

  // Observables
  final _songs = <Song>[].obs;
  final _downloadedSongs = <String>{}.obs;
  final _currentSong = Rxn<Song>();
  final _currentIndex = 0.obs;
  final _volume = 1.0.obs;
  final _isLoading = false.obs;
  final _isDownloading = false.obs;

  // Getters
  List<Song> get songs => _songs;
  Set<String> get downloadedSongs => _downloadedSongs;
  Song? get currentSong => _currentSong.value;
  int get currentIndex => _currentIndex.value;
  double get volume => _volume.value;
  bool get isLoading => _isLoading.value;
  bool get isDownloading => _isDownloading.value;

  // Cache management
  final Map<String, String> _cachedPaths = {};
  final _preloadQueue = <String>{};

  @override
  void onInit() {
    super.onInit();
    _loadDownloadedSongs();
    _initPlayer();
    fetchSongs();

    // Handle song completion
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        nextSong();
      }
    });
  }

  void _initPlayer() {
    player.setVolume(_volume.value);
    ever(_volume, (value) => player.setVolume(value));
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= _songs.length || _isLoading.value) return;

    try {
      _isLoading.value = true;
      _currentIndex.value = index;
      _currentSong.value = _songs[index];

      final song = _songs[index];

      // Start loading audio source immediately
      final audioPathFuture = _getAudioPath(song.url);

      // Handle artwork URL
      Uri? artworkUri;
      if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
        artworkUri = Uri.parse(song.artworkUrl!);
      }

      String? audioPath = await audioPathFuture;

      if (audioPath != null) {
        final mediaItem = MediaItem(
          id: song.url,
          album: 'أناشيد الثورة السورية',
          title: song.name,
          artUri: artworkUri, // Can be null
          displayTitle: song.name,
          displaySubtitle: 'أناشيد الثورة السورية',
          extras: {
            'index': index,
            'total': _songs.length,
          },
        );

        await player.setAudioSource(
          AudioSource.file(
            audioPath,
            tag: mediaItem,
          ),
          preload: false, // Don't preload the entire file
        );

        // Start playing immediately while preloading next song in background
        player.play();
        _preloadNextSong(index);
      } else {
        final mediaItem = MediaItem(
          id: song.url,
          album: 'أناشيد الثورة السورية',
          title: song.name,
          artUri: artworkUri, // Can be null
          displayTitle: song.name,
          displaySubtitle: 'أناشيد الثورة السورية',
          extras: {
            'index': index,
            'total': _songs.length,
          },
        );

        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(song.url),
            tag: mediaItem,
          ),
          preload: false, // Don't preload the entire file
        );

        player.play();
      }
    } catch (e) {
      Logger().e('Error playing song: $e');
      _showErrorSnackbar("حدث خطأ أثناء تشغيل الأغنية");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> togglePlayPause() async {
    try {
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (e) {
      Logger().e('Error toggling play/pause: $e');
    }
  }

  Future<void> nextSong() async {
    if (_currentIndex.value < _songs.length - 1) {
      await playSong(_currentIndex.value + 1);
    }
  }

  Future<void> previousSong() async {
    if (_currentIndex.value > 0) {
      await playSong(_currentIndex.value - 1);
    }
  }

  void setVolume(double newVolume) {
    _volume.value = newVolume;
    player.setVolume(newVolume);
  }

  // Download Management ======================================

  Future<void> downloadSong(int index) async {
    if (index < 0 || index >= _songs.length) return;

    try {
      final song = _songs[index];
      if (_downloadedSongs.contains(song.url)) {
        showSuccessSnackbar("${song.name} متوفر بالفعل للتشغيل دون إنترنت");
        return;
      }

      _isDownloading.value = true;
      final path = await _downloadAndCacheFile(song.url);

      if (path.isNotEmpty) {
        _downloadedSongs.add(song.url);
        await _saveDownloadedSongs();
        showSuccessSnackbar("تم تحميل ${song.name} بنجاح");
      }
    } catch (e) {
      _showErrorSnackbar("فشل تحميل الأغنية");
      Logger().e('Error downloading song: $e');
    } finally {
      _isDownloading.value = false;
    }
  }

  Future<void> downloadAllSongs() async {
    try {
      _isDownloading.value = true;
      for (var i = 0; i < _songs.length; i++) {
        if (!_downloadedSongs.contains(_songs[i].url)) {
          await downloadSong(i);
        }
      }
      showSuccessSnackbar("تم تحميل جميع الأغاني بنجاح");
    } finally {
      _isDownloading.value = false;
    }
  }

  // Cache Management ========================================

  Future<String?> _getAudioPath(String url) async {
    // Check memory cache first
    if (_cachedPaths.containsKey(url)) {
      return _cachedPaths[url];
    }

    // Check disk cache
    try {
      final file = await cacheManager.getSingleFile(url);
      _cachedPaths[url] = file.path;
      return file.path;
    } catch (e) {
      Logger().e('Error getting audio path: $e');
      return null;
    }
  }

  Future<void> _preCacheSong(String url) async {
    if (!_preloadQueue.contains(url) && !_cachedPaths.containsKey(url)) {
      _preloadQueue.add(url);
      await _getAudioPath(url);
      _preloadQueue.remove(url);
    }
  }

  Future<void> _preloadNextSong(int currentIndex) async {
    if (currentIndex >= _songs.length - 1) return;

    try {
      final nextSong = _songs[currentIndex + 1];
      if (!_preloadQueue.contains(nextSong.url)) {
        _preloadQueue.add(nextSong.url);
        await _getAudioPath(nextSong.url);
        _preloadQueue.remove(nextSong.url);
      }
    } catch (e) {
      Logger().e('Error preloading next song: $e');
    }
  }

  Future<String> _downloadAndCacheFile(String url) async {
    try {
      final file = await cacheManager.getSingleFile(url);
      _cachedPaths[url] = file.path;
      return file.path;
    } catch (e) {
      Logger().e('Error downloading file: $e');
      return '';
    }
  }

  // Persistence ============================================

  Future<void> _loadDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedUrls = prefs.getStringList(prefsKey) ?? [];
      _downloadedSongs.addAll(downloadedUrls);
    } catch (e) {
      Logger().e('Error loading downloaded songs: $e');
    }
  }

  Future<void> _saveDownloadedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefsKey, _downloadedSongs.toList());
    } catch (e) {
      Logger().e('Error saving downloaded songs: $e');
    }
  }

  // UI Feedback ===========================================

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      "خطأ",
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
      "نجاح",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  Future<void> fetchSongs() async {
    try {
      _isLoading.value = true;

      final query = QueryBuilder<ParseObject>(ParseObject('Song'))
        ..orderByDescending('updatedAt');

      final response = await query.query();

      if (response.success && response.results != null) {
        final fetchedSongs = response.results!
            .map((result) => Song.fromParseObject(result as ParseObject))
            .toList();

        _songs.value = fetchedSongs;

        // Pre-cache first few songs
        for (var i = 0; i < min(3, fetchedSongs.length); i++) {
          _preCacheSong(fetchedSongs[i].url);
        }
      } else {
        _showErrorSnackbar("تحقق من إتصالك بالأنترنت");
        Logger().e('Failed to load songs: ${response.error?.message}');
      }
    } catch (e) {
      _showErrorSnackbar("حدث خطأ أثناء جلب الأغاني");
      Logger().e('Error fetching songs: $e');
    } finally {
      _isLoading.value = false;
    }
  }
}
