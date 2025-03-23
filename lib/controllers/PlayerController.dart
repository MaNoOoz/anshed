import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import '../models/song.dart';

class PlayerController extends GetxController {
  final AudioPlayer _player = AudioPlayer();
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final Map<String, String> _cachedPaths = <String, String>{};
  final RxInt _downloadProgress = 0.obs;
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  final String _jsonCacheKey = 'cachedSongs';

  // Observables
  final RxList<Song> _allSongs = <Song>[].obs;
  final Rx<Song?> _currentSong = Rx<Song?>(null);
  final RxInt _currentIndex = 0.obs; // Changed initial value to 0
  final RxDouble _volume = 1.0.obs;
  final RxBool _isLoading = false.obs;
  final Rx<PlayerState> _playerState =
      Rx(PlayerState(false, ProcessingState.idle));

  // Getters
  AudioPlayer get player => _player;

  List<Song> get songs => _allSongs;

  Song? get currentSong =>
      _currentIndex.value >= 0 && _currentIndex.value < _allSongs.length
          ? _allSongs[_currentIndex.value]
          : null; //derived from the current index
  int get currentIndex => _currentIndex.value;

  double get volume => _volume.value;

  bool get isLoading => _isLoading.value;
  RxBool _shuffleModeEnabled = false.obs;

  bool get shuffleMode => _shuffleModeEnabled.value;

  PlayerState get playerState => _playerState.value;

  double get vol => _volume.value;

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  void onInit() {
    super.onInit();
    _initPlayer();
    _loadCachedSongs();
    _fetchMusicUrls();
  }

  void _initPlayer() {
    _player.setVolume(_volume.value);
    _volume.listen((v) => _player.setVolume(v));

    _player.playerStateStream.listen((state) {
      _playerState.value = state;
    });

    _listenToShuffle();

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _allSongs.length) {
        _currentIndex.value = index;
        _currentSong.value = _allSongs[index];
      }
    });
  }

  void _listenToShuffle() {
    _player.shuffleModeEnabledStream.listen((data) {
      _shuffleModeEnabled = data.obs;
    });
  }

  void setVolume(double newVolume) {
    _volume.value = newVolume;
    _player.setVolume(newVolume);
  }

  void setShuffleMode(bool on) {
    _shuffleModeEnabled.value = on;
    _player.setShuffleModeEnabled(on);
  }

  Future<void> nextSong() async {
    if (_currentIndex.value < _allSongs.length - 1) {
      await playSong(_currentIndex.value + 1);
    }
  }

  Future<void> playSong(int index) async {
    if (index < 0 || index >= _allSongs.length) return;

    try {
      // Update the current index and current song
      _currentIndex.value = index;
      _currentSong.value = _allSongs[index];
      await _player.seek(Duration.zero, index: index);
      await _player.play();
    } catch (e) {
      _handlePlaybackError(e);
    }
  }

  void _handlePlaybackError(dynamic e) {
    if (e is SocketException) {
      // _showErrorSnackbar("تحقق من اتصال الإنترنت");
    } else {
      // _showErrorSnackbar("فشل التشغيل");
    }
    Logger().e('Playback error: $e');
  }

  Future<void> seekToPosition(Duration position) async {
    try {
      await player.seek(position);
    } catch (e) {
      // _showErrorSnackbar("فشل التحديد");
      Logger().e('Seek error: $e');
    }
  }

  Future<void> previousSong() async {
    if (_currentIndex.value > 0) {
      await playSong(_currentIndex.value - 1);
    }
  }

  Future<void> _loadCachedSongs() async {
    try {
      final file = await _cacheManager.getFileFromCache(_jsonCacheKey);
      if (file != null) {
        final jsonString = await file.file.readAsString();
        _allSongs.value = (jsonDecode(jsonString) as List)
            .map((e) => Song.fromJson(e))
            .toList();
      }
    } catch (e) {
      Logger().e('Error loading cached songs: $e');
    }
  }

  Future<void> _fetchMusicUrls() async {
    try {
      _isLoading.value = true;
      final query = QueryBuilder<ParseObject>(ParseObject('Song'))
        ..orderByDescending('type');
      final response = await query.query();

      if (response.success && response.results != null) {
        final fetchedSongs = response.results!
            .map((result) => Song.fromParseObject(result as ParseObject))
            .toList();

        _allSongs.value = fetchedSongs;
        await _updatePlaylist();
        await _cacheManager.putFile(
          _jsonCacheKey,
          utf8.encode(jsonEncode(fetchedSongs.map((s) => s.toJson()).toList())),
        );
      }
    } catch (e) {
      // _showErrorSnackbar("Failed to load songs");
      Logger().e('Fetch error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _updatePlaylist() async {
    try {
      _playlist = ConcatenatingAudioSource(children: []);

      for (final song in _allSongs) {
        final cachedPath = await _getCachedPath(song.url);
        final artworkUri = await _cacheArtwork(song.artworkUrl);

        _playlist.add(AudioSource.uri(
          Uri.parse(cachedPath ?? song.url),
          tag: MediaItem(
            id: song.url,
            title: song.name,
            artist: song.artist,
            artUri: artworkUri,
            extras: {'songData': song.toJson()},
          ),
        ));
      }

      await _player.setAudioSource(_playlist);
      //update current song if all song changed
      if (_currentIndex.value < _allSongs.length)
        _currentSong.value = _allSongs[_currentIndex.value];
    } catch (e) {
      Logger().e('Playlist error: $e');
      // _showErrorSnackbar("Playlist initialization failed");
    }
  }

  bool isSongCached(String url) {
    return _cachedPaths.containsKey(url);
  }

  Future<String?> _getCachedPath(String url) async {
    try {
      final file = await _cacheManager.getFileFromCache(url);
      return file?.file.path;
    } catch (e) {
      return null;
    }
  }

  Future<Uri?> _cacheArtwork(String? url) async {
    if (url == null) return null;

    try {
      final file = await _cacheManager.getSingleFile(url);
      return Uri.file(file.path);
    } catch (e) {
      return null;
    }
  }

  Future<void> downloadSong(int index) async {
    if (index < 0 || index >= _allSongs.length) return;

    try {
      final song = _allSongs[index];
      await _downloadAndCacheFile(song.url);
      update();
      _showSuccessSnackbar("تم تحميل ${song.name}");
    } catch (e) {
      _showErrorSnackbar("فشل التحميل");
      Logger().e('Download error: $e');
    }
  }

  Future<String> _downloadAndCacheFile(String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      _cachedPaths[url] = file.path;
      return file.path;
    } catch (e) {
      Logger().e('Download error: $e');
      rethrow;
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar('Error', message, backgroundColor: Colors.red);
  }

  Future<void> downloadAllSongs() async {
    if (_allSongs.isEmpty) {
      _showErrorSnackbar("لا توجد أناشيد للتحميل");
      return;
    }

    try {
      _downloadProgress.value = 0;
      final totalSongs = _allSongs.length;

      for (var i = 0; i < totalSongs; i++) {
        if (!_cachedPaths.containsKey(_allSongs[i].url)) {
          await downloadSong(i);
        }
        _downloadProgress.value = ((i + 1) / totalSongs * 100).round();
      }

      _showSuccessSnackbar("تم تحميل جميع الأناشيد بنجاح");
    } catch (e) {
      _showErrorSnackbar("فشل تحميل بعض الأناشيد");
      Logger().e('Download all error: $e');
    } finally {
      _downloadProgress.value = 0;
    }
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar('Success', message, backgroundColor: Colors.green);
  }
}
