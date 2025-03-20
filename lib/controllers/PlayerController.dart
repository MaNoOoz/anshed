import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../models/song.dart';
import 'AdController.dart';

class PlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();
  final DefaultCacheManager cacheManager = DefaultCacheManager();
  final String jsonCacheKey = 'cachedSongs';
  final String prefsKey = 'downloadedSongs';
  final AdController adController = Get.put(AdController());

  // Observables
  // Observables
  var currentSong = Rxn<Song>();
  var _allSongs = <Song>[].obs;
  final _downloadedSongs = <Song>[].obs;

  var currentIndex = 0.obs;
  var volume = 1.0.obs;
  var isLoading = false.obs;

// Reactive list for filtered songs

  // Getters
  List<Song> get songs => _allSongs;

  List<Song> get downloadedSongs => _downloadedSongs;

  Song? get current => currentSong.value;

  int get index => currentIndex.value;

  double get vol => volume.value;

  bool get loading => isLoading.value;

  // Cache management
  final Map<String, String> _cachedPaths = {};
  final _preloadQueue = <String>{};

  @override
  void onInit() {
    super.onInit();
    Logger().e('Songs length: ${_allSongs.length}');
    Logger().e('Songs length after adding test: ${songs.length}');

    loadCachedSongs();
    fetchMusicUrls();
    _initListeners();

    // songs.assignAll(_allSongs); // Initialize with all songs

    player.setVolume(volume.value);
    ever(volume, (value) => player.setVolume(value));
  }

  @override
  void onReady() {
    super.onReady();
    Logger().e('onReady : Songs length after adding test: ${songs.length}');

    songs.assignAll(_allSongs); // Initialize with all songs
    songs.sort((a, b) =>
        b.updatedAt.toString().compareTo(a.updatedAt.toString())); // Sort
  }

  Future<void> checkfornewsongs(context) async {
    Logger().e(
        "Pressed songList ${_allSongs.length} and downloadedSongs ${_downloadedSongs.length}");
    await fetchMusicUrls();
    // Check for new songs to download
    if (_allSongs.length > _downloadedSongs.length || _allSongs.isEmpty) {
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
    } else if (_allSongs.length == _downloadedSongs.length) {
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
    _allSongs.clear();
    _downloadedSongs.clear();
    _cachedPaths.clear();
    _preloadQueue.clear();
  }

  deleteSong(int currentIndex) {
    _allSongs.removeAt(currentIndex);
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

        _allSongs.value = cachedSongs;
        _downloadedSongs.value = cachedSongs;
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
          _allSongs.value = fetchedSongs;
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

    if (index < 0 || index >= _allSongs.length || isLoading.value) return;

    try {
      isLoading.value = true;
      currentIndex.value = index;
      currentSong.value = _allSongs[index];

      final song = _allSongs[index];

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
            'total': _allSongs.length,
          },
        );

        await player.setAudioSource(
          AudioSource.file(
            audioPath,
            tag: mediaItem,
          ),
          preload: false, // Don't preload the entire file
        );

        player.stop();

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
            'total': _allSongs.length,
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

  Future<void> playSong2(int index) async {
    Logger().e('playSong at $index');

    if (index < 0 || index >= _allSongs.length || isLoading.value) return;

    try {
      isLoading.value = true;
      currentIndex.value = index;
      currentSong.value = _allSongs[index];

      final song = _allSongs[index];

      // Start loading audio source immediately
      final audioPathFuture = _getAudioPath(song.url);

      // Handle artwork URL (cache if online, use cached version if offline)
      Uri? artworkUri = await _getCachedArtworkUri(song.artworkUrl);

      String? audioPath = await audioPathFuture;

      if (audioPath != null) {
        await _playLocalSong(song, audioPath, artworkUri, index);
      } else {
        await _playRemoteSong(song, artworkUri, index);
      }

      _preloadNextSong(index);
    } catch (e) {
      Logger().e('Error playing song: $e');
      _showErrorSnackbar("حدث خطأ أثناء تشغيل الأغنية");
    } finally {
      isLoading.value = false;
    }
  }

  Future<Uri?> _getCachedArtworkUri(String? artworkUrl) async {
    if (artworkUrl == null || artworkUrl.isEmpty) return null;

    final cacheManager = DefaultCacheManager();
    final fileInfo = await cacheManager.getFileFromCache(artworkUrl);

    if (fileInfo != null) {
      // Artwork is already cached, use the cached file
      return Uri.file(fileInfo.file.path); // Use file.path
    } else {
      // Artwork is not cached, try to download it (if online)
      try {
        final file = await cacheManager.downloadFile(artworkUrl);
        return Uri.file(file.file.path); // Use file.path
      } catch (e) {
        Logger().e('Error caching artwork: $e');
        return null; // Return null if artwork cannot be downloaded (offline)
      }
    }
  }

  Future<void> _playLocalSong(
      Song song, String audioPath, Uri? artworkUri, int index) async {
    final mediaItem = _createMediaItem(song, artworkUri, index);

    await player.setAudioSource(
      AudioSource.file(
        audioPath,
        tag: mediaItem,
      ),
      preload: false, // Don't preload the entire file
    );

    player.stop();
    player.play();
  }

  Future<void> _playRemoteSong(Song song, Uri? artworkUri, int index) async {
    final mediaItem = _createMediaItem(song, artworkUri, index);

    await player.setAudioSource(
      AudioSource.uri(
        Uri.parse(song.url),
        tag: mediaItem,
      ),
      preload: false, // Don't preload the entire file
    );

    player.play();
  }

  MediaItem _createMediaItem(Song song, Uri? artworkUri, int index) {
    return MediaItem(
      id: song.url,
      album: 'أناشيد الثورة السورية',
      title: song.name,
      artUri: artworkUri ?? Uri.parse('assets/s.png'),
      artist: song.artist,
      displayTitle: song.name,
      displaySubtitle: 'أناشيد الثورة السورية',
      extras: {
        'index': index,
        'total': _allSongs.length,
      },
    );
  }

  void _preloadNextSong(int currentIndex) {
    int nextIndex = currentIndex + 1;
    if (nextIndex < _allSongs.length) {
      // Preload the next song
      _getAudioPath(_allSongs[nextIndex].url);
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
    if (currentIndex.value < _allSongs.length - 1) {
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
    if (index < 0 || index >= _allSongs.length) return;
    try {
      final song = _allSongs[index];
      if (_downloadedSongs.any((s) => s.url == song.url)) {
        showSuccessSnackbar('${song.name} متوفر بالفعل للتشغيل دون إنترنت');
        return;
      }

      await _downloadAndCacheFile(song.url);
      _downloadedSongs.add(song);
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
      for (var i = 0; i < _allSongs.length; i++) {
        if (!_downloadedSongs.any((s) => s.url == _allSongs[i].url)) {
          await downloadSong(i);
        }
      }
      if (areListsEqual(_allSongs, _downloadedSongs)) {
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

  // Future<void> _preCacheSong(String url) async {
  //   if (!_preloadQueue.contains(url) && !_cachedPaths.containsKey(url)) {
  //     _preloadQueue.add(url);
  //     await _getAudioPath(url);
  //     _preloadQueue.remove(url);
  //   }
  // }

  // Future<void> _preloadNextSong(int currentIndex) async {
  //   if (currentIndex >= _allSongs.length - 1) return;
  //
  //   try {
  //     final nextSong = _allSongs[currentIndex + 1];
  //     if (!_preloadQueue.contains(nextSong.url)) {
  //       _preloadQueue.add(nextSong.url);
  //       await _getAudioPath(nextSong.url);
  //       _preloadQueue.remove(nextSong.url);
  //     }
  //   } catch (e) {
  //     Logger().e('Error preloading next song: $e');
  //   }
  // }

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
