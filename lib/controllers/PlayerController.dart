import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../models/song.dart';

class PlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  final DefaultCacheManager cacheManager = DefaultCacheManager();
  final String jsonCacheKey = 'cachedSongs';
  final String prefsKey = 'downloadedSongs';

  // Observables
  var currentSong = Rxn<Song>();
  var _currentArt = Rxn<String>();
  var songList = <Song>[].obs;
  var downloadedSongs = <Song>[].obs;
  var currentIndex = 0.obs;
  var volume = 1.0.obs;
  var isLoading = false.obs;
// Reactive list for filtered songs
  RxList<Song> filteredSongs = <Song>[].obs;

  // Getters
  List<Song> get songs => songList;

  List<Song> get downloaded => downloadedSongs;

  Song? get current => currentSong.value;

  String? get currentArt => _currentArt.value;

  int get index => currentIndex.value;

  double get vol => volume.value;

  bool get loading => isLoading.value;

  // Cache management
  final Map<String, String> _cachedPaths = {};
  final _preloadQueue = <String>{};

  @override
  void onInit() {
    super.onInit();
    Logger().e('Songs length: ${songList.length}');

    Logger().e('Songs length after adding test: ${songs.length}');


    loadCachedSongs();
    fetchMusicUrls();
    _initListeners();
    filteredSongs.assignAll(songList); // Initialize with all songs

    player.setVolume(volume.value);
    ever(volume, (value) => player.setVolume(value));
  }
  @override
  void onReady() {
    super.onReady();
    Logger().e('onReady : Songs length after adding test: ${songs.length}');

    // Additional logic after the widget is rendered
    filteredSongs.assignAll(songList); // Initialize with all songs

  }
// Method to filter songs based on search query
  void filterSongs(String query) {
    if (query.isEmpty) {
      // If the query is empty, show all songs
      filteredSongs.assignAll(songs);
    } else {
      // Filter songs that contain the query (case-insensitive)
      filteredSongs.assignAll(
        songs.where((song) => song.name.toLowerCase().contains(query.toLowerCase())).toList(),
      );
    }
  }

  Future<void> checkfornewsongs(context) async {
    Logger().e(
        "Pressed songList ${songList.length} and downloadedSongs ${downloadedSongs.length}");
    await fetchMusicUrls();
    // Check for new songs to download
    if (songList.length > downloadedSongs.length || songList.isEmpty) {
      showDialog(
        context: Get.context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('يوجد أناشيد جديدة'),
            content: Text('يوجد أناشيد جديدة للتحميل'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () async {
                  await downloadAllSongs();
                  Navigator.of(context).pop();
                },
                child: const Text('تحميل'),
              ),
            ],
          );
        },
      );
    } else if (songList.length == downloadedSongs.length) {
      showDialog(
        context: Get.context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('لايوجد أناشيد جديدة'),
            content: Text('لديك جميع الأناشيد'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                },
                child: const Text('حسنا'),
              ),
            ],
          );
        },
      );
    }
  }

  // for tetsing
  deleteAllSongs() {
    songList.clear();
    downloadedSongs.clear();
    _cachedPaths.clear();
    _preloadQueue.clear();
  }

  deleteSong(int currentIndex) {
    songList.removeAt(currentIndex);
    // downloadedSongs.removeAt(currentIndex);
    _cachedPaths.clear();
    _preloadQueue.clear();
  }

  void _initListeners() {
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        nextSong();
      }
    });
  }

  Future<void> loadCachedSongs() async {
    try {
      Logger().e('Loading cached songs...');
      var file = await cacheManager.getFileFromCache(jsonCacheKey);
      if (file != null) {
        final jsonString = await file.file.readAsString();
        Logger().e('Cached JSON Data: $jsonString');
        final List<dynamic> jsonData = jsonDecode(jsonString);
        final List<Song> cachedSongs =
        jsonData.map((e) => Song.fromJson(e)).toList();

        Logger().e('Loaded Cached Songs Count: ${cachedSongs.length}');

        songList.value = cachedSongs;
        downloadedSongs.value = cachedSongs;
      } else {
        Logger().e('No cached songs found.');
      }
    } catch (e) {
      Logger().e('Error loading cached songs: $e');
    }
  }

  Future<void> fetchMusicUrls() async {
    Logger().e('Fetching songs from Parse server...');
    try {
      isLoading.value = true;
      final query = QueryBuilder<ParseObject>(ParseObject('Song'))
        ..orderByDescending('updatedAt');

      final response = await query.query();
      Logger().e('Response received: ${response.results}');

      if (response.success && response.results != null) {
        final fetchedSongs = response.results!
            .map((result) => Song.fromParseObject(result as ParseObject))
            .toList();

        Logger().e('Fetched Songs Count: ${fetchedSongs.length}');

        if (fetchedSongs.isNotEmpty) {
          songList.value = fetchedSongs;
        } else {
          Logger().e('No songs found.');
        }

        // Cache the JSON data
        await cacheManager.putFile(
          jsonCacheKey,
          utf8.encode(
              jsonEncode(fetchedSongs.map((song) => song.toJson()).toList())),
          key: jsonCacheKey,
        );
      } else {
        Logger().e('Failed to load songs: ${response.error?.message}');
        _showErrorSnackbar("تحقق من إتصالك بالأنترنت");
      }
    } catch (e) {
      Logger().e('Error fetching music URLs: $e');
      _showErrorSnackbar("حدث خطأ أثناء جلب  الأناشيد");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playSong(int index) async {
    Logger().e('playSong  at $index');

    if (index < 0 || index >= songList.length || isLoading.value) return;

    try {
      isLoading.value = true;
      currentIndex.value = index;
      currentSong.value = songList[index];

      final song = songList[index];

      // Start loading audio source immediately
      final audioPathFuture = _getAudioPath(song.url);

      // Handle artwork URL
      Uri? artworkUri;
      if (song.artworkUrl != null && song.artworkUrl!.isNotEmpty) {
        artworkUri = Uri.parse(song.artworkUrl!);
        // Cache the artwork image

        await DefaultCacheManager().downloadFile(artworkUri.toString());
      }

      String? audioPath = await audioPathFuture;

      if (audioPath != null) {
        final mediaItem = MediaItem(
          id: song.url,
          album: 'أناشيد الثورة السورية',
          title: song.name,
          artUri: artworkUri,
          artist: song.artist,

          // Can be null
          displayTitle: song.name,
          displaySubtitle: 'أناشيد الثورة السورية',
          extras: {
            'index': index,
            'total': songList.length,
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
          artUri: artworkUri,
          // Can be null
          displayTitle: song.name,
          displaySubtitle: 'أناشيد الثورة السورية',
          extras: {
            'index': index,
            'total': songList.length,
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
      isLoading.value = false;
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
    if (currentIndex.value < songList.length - 1) {
      await playSong(currentIndex.value + 1);
    }
  }

  Future<void> previousSong() async {
    if (currentIndex.value > 0) {
      await playSong(currentIndex.value - 1);
    }
  }

  void setVolume(double newVolume) {
    volume.value = newVolume;
    player.setVolume(newVolume);
  }

  // Download Management ======================================

  Future<void> downloadSong(int index) async {
    if (index < 0 || index >= songList.length) return;
    try {
      final song = songList[index];
      if (downloadedSongs.any((s) => s.url == song.url)) {
        showSuccessSnackbar('${song.name} متوفر بالفعل للتشغيل دون إنترنت');
        return;
      }

      await _downloadAndCacheFile(song.url);
      downloadedSongs.add(song);
      // showSuccessSnackbar('تم تحميل ${song.name} للتشغيل دون إنترنت');
    } catch (e) {
      _showErrorSnackbar("حدث خطأ أثناء تحميل الأغنية");
      Logger().e('Error downloading song: $e');
    }
  }

  bool areListsEqual(List list1, List list2) {
    return list1 == list2;
  }

  Future<void> downloadAllSongs() async {
    Logger().e('downloadAllSongs');
    await fetchMusicUrls();
    try {
      for (var i = 0; i < songList.length; i++) {
        if (!downloadedSongs.any((s) => s.url == songList[i].url)) {
          await downloadSong(i);
        }
      }
      if (areListsEqual(songList, downloadedSongs)) {
        showSuccessSnackbar(' متوفر بالفعل للتشغيل دون إنترنت');
      } else {
        showSuccessSnackbar(' متوفر بالفعل للتشغيل دون إنترنت');
      }
      showSuccessSnackbar("تم تحميل جميع  الأناشيد بنجاح");
    } catch (e) {
      _showErrorSnackbar("حدث خطأ أثناء تحميل  الأناشيد");
      Logger().e('Error downloading all songs: $e');
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
    if (currentIndex >= songList.length - 1) return;

    try {
      final nextSong = songList[currentIndex + 1];
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
      var file = await cacheManager.getSingleFile(url);
      return file.path;
    } catch (e) {
      _showErrorSnackbar("حدث خطأ أثناء تحميل الملف");
      Logger().e('Error downloading file: $e');
      rethrow;
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
}
