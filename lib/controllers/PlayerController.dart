import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';
import '../widgets/PlayerModal.dart';
import 'SongCacheManager.dart';
import 'SongService.dart';

enum CustomPlayerState {
  idle,
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}

class AudioPlayerController extends GetxController {
  // Dependencies
  final SongService _songService;
  final SongCacheManager _songCacheManager;

  // Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  AudioPlayer get audioPlayer => _audioPlayer;
  final RxList<MediaItem> _mediaPlaylist = RxList<MediaItem>([]);

  List<MediaItem> get mediaPlaylist => _mediaPlaylist;

  // Reactive State
  final Rx<CustomPlayerState> _playerState = CustomPlayerState.idle.obs;
  final RxList<Song> _playlist = RxList<Song>([]);
  final Rx<MediaItem?> _currentMediaItem = Rx<MediaItem?>(null);

  set currentMediaItem(MediaItem? item) => _currentMediaItem.value = item;
  final RxInt _currentIndex = 0.obs;
  final RxDouble _volume = 1.0.obs;
  final RxBool _isMuted = false.obs;

  // Properties
  CustomPlayerState get playerState => _playerState.value;

  List<Song> get playlist => _playlist;

  MediaItem? get currentMediaItem => _currentMediaItem.value;

  int get currentIndex => _currentIndex.value;
  double get volume => _volume.value;

  bool get isMuted => _isMuted.value;

  bool get hasNext => _currentIndex.value < _playlist.length - 1;

  bool get hasPrevious => _currentIndex.value > 0;

  // Constructor
  AudioPlayerController(this._songService, this._songCacheManager);

  @override
  void onInit() {
    super.onInit();
    _initAudioPlayer();
    _loadInitialPlaylist();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  void _initAudioPlayer() {
    _audioPlayer.playerStateStream.listen(_handlePlayerStateChange);
    _audioPlayer.currentIndexStream.listen(_handleIndexChange);
    _audioPlayer.volumeStream.listen(_handleVolumeChange);
  }

  Future<void> _loadInitialPlaylist() async {
    Logger().i('Loading initial playlist...');
    _playerState.value = CustomPlayerState.loading;
    try {
      final songs = await _songService.fetchSongs();

      if (songs.isEmpty) {
        Logger().w('No songs found in API.');
        _playerState.value = CustomPlayerState.error;
        return;
      }

      songs.sort((a, b) => a.artist.compareTo(b.artist));
      _playlist.assignAll(songs);
      final defaultArtUri = await getNotificationArtUriFromAsset();
      _mediaPlaylist.assignAll(songs
          .map((song) => MediaItem(
                id: song.fileId,
                title: song.title,
                artist: song.artist,
                artUri: defaultArtUri,
              ))
          .toList());

      await _cacheSongs(songs);
      await _createAudioSources();

      _playerState.value = CustomPlayerState.ready;

      if (_playlist.isNotEmpty) {
        _currentMediaItem.value = _playlist[0].toMediaItem();
      }

      Logger().i(
          'Initial playlist loaded successfully. Total songs: ${_playlist.length}');
    } catch (e) {
      _playerState.value = CustomPlayerState.error;
      Logger().e('Error loading playlist: $e');
      Get.snackbar('Error', 'Failed to load playlist: $e');
    }
  }
  Future<void> _cacheSongs(List<Song> songs) async {
    Logger().i('Caching ${songs.length} songs...');
    final tasks = <Future>[];
    for (final song in songs) {
      final isCached = await _songCacheManager.isSongCached(song.fileId);
      if (!isCached) {
        tasks.add(_songCacheManager.downloadAndCacheSong(song.fileId));
      }
    }
    await Future.wait(tasks);

    Logger().i('Caching completed.');
  }

  Future<void> _createAudioSources() async {
    Logger().i('Creating audio sources...');
    try {
      final sources = <AudioSource>[];

      for (final song in _playlist) {
        final file = await _songCacheManager.getCachedSong(song.fileId);
        if (file != null) {
          sources.add(AudioSource.uri(Uri.file(file.file.path),
              tag: song.toMediaItem()));
        } else {
          Logger().w('Song not cached: ${song.title}');
        }
      }

      if (sources.isNotEmpty) {
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: sources),
          initialIndex: 0,
        );
        Logger().i('Audio sources created. Total: ${sources.length}');
      } else {
        Logger().w('No audio sources found.');
        _playerState.value = CustomPlayerState.error;
      }
    } catch (e) {
      Logger().e('Error creating audio sources: $e');
      _playerState.value = CustomPlayerState.error;
    }
  }

  Future<void> playPlaylist(List<MediaItem> playlist,
      {int startIndex = 0}) async {
    final audioSources = <AudioSource>[];
    final defaultArtUri = await getNotificationArtUriFromAsset();
    for (var mediaItem in playlist) {
      final cachedFile = await _songCacheManager.getCachedSong(mediaItem.id);

      if (cachedFile != null && cachedFile.file.existsSync()) {
        final fileSize = cachedFile.file.lengthSync();
        if (fileSize > 0) {
          Logger().i('✅ File exists for: ${mediaItem.title}, Size: $fileSize');
          // 👇 Override artUri with local asset for notification
          final updatedMediaItem = mediaItem.copyWith(
            artUri: defaultArtUri,
          );
          audioSources.add(AudioSource.uri(Uri.file(cachedFile.file.path),
              tag: updatedMediaItem));
        } else {
          Logger().e('❌ File is 0 bytes for: ${mediaItem.title}, removing it');
          await cachedFile.file.delete();
        }
      } else {
        Logger().e(
            '❌ Missing file for: ${mediaItem.title}, path: ${cachedFile?.file.path}');
      }
    }

    if (audioSources.isEmpty) {
      Logger().e('🚫 No valid audio sources to play.');
      return;
    }

    await _audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: startIndex,
    );

    await _audioPlayer.play();
    _currentMediaItem.value = playlist[startIndex];
    update();
  }

  // Player Control
  Future<void> play() async {
    if (_playerState.value == CustomPlayerState.ready ||
        _playerState.value == CustomPlayerState.paused) {
      try {
        await _audioPlayer.play();
      } catch (e) {
        Logger().e('Play error: $e');
        Get.snackbar('Error', 'Play failed: $e');
      }
    }
  }

  Future<void> pause() async {
    if (_playerState.value == CustomPlayerState.playing) {
      try {
        await _audioPlayer.pause();
      } catch (e) {
        Logger().e('Pause error: $e');
        Get.snackbar('Error', 'Pause failed: $e');
      }
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      Logger().e('Seek error: $e');
      Get.snackbar('Error', 'Seek failed: $e');
    }
  }

  Future<void> next() async {
    if (hasNext) {
      try {
        await _audioPlayer.seekToNext();
      } catch (e) {
        Logger().e('Next error: $e');
        Get.snackbar('Error', 'Next failed: $e');
      }
    }
  }

  Future<void> previous() async {
    if (hasPrevious) {
      try {
        await _audioPlayer.seekToPrevious();
      } catch (e) {
        Logger().e('Previous error: $e');
        Get.snackbar('Error', 'Previous failed: $e');
      }
    }
  }

  Future<void> playAtIndex(int index) async {
    if (index >= 0 &&
        index < _playlist.length &&
        _playerState.value != CustomPlayerState.error) {
      try {
        _currentIndex.value = index;
        await _audioPlayer.seek(Duration.zero, index: index);
        _currentMediaItem.value = _playlist[index].toMediaItem();
        await play();
      } catch (e) {
        Logger().e('PlayAtIndex error: $e');
        Get.snackbar('Error', 'Failed to play song: $e');
      }
    }
  }

  void setVolume(double value) {
    _volume.value = value;
    _audioPlayer.setVolume(value);
  }

  void toggleMute() {
    _isMuted.value = !_isMuted.value;
    _audioPlayer.setVolume(_isMuted.value ? 0.0 : _volume.value);
  }

  void _handlePlayerStateChange(PlayerState state) {
    switch (state.processingState) {
      case ProcessingState.idle:
        _playerState.value = CustomPlayerState.idle;
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        _playerState.value = CustomPlayerState.loading;
        break;
      case ProcessingState.ready:
        _playerState.value = state.playing
            ? CustomPlayerState.playing
            : CustomPlayerState.paused;
        break;
      case ProcessingState.completed:
        _handlePlaybackCompletion();
        break;
      default:
        _playerState.value = CustomPlayerState.error;
    }
  }

  void _handleIndexChange(int? newIndex) {
    if (newIndex == null || _mediaPlaylist.isEmpty) {
      Logger().w('❗ Null index or empty playlist. Resetting to first song.');
      _audioPlayer.seek(Duration.zero, index: 0);
      _currentIndex.value = 0;
      currentMediaItem = _mediaPlaylist.isNotEmpty ? _mediaPlaylist[0] : null;
      update();
      return;
    }

    if (newIndex >= 0 && newIndex < _mediaPlaylist.length) {
      _currentIndex.value = newIndex;
      final song = _mediaPlaylist[newIndex];
      currentMediaItem = song;
      Logger().i('🎵 Changed to song: ${song.title}');
      update();
    } else {
      Logger().w(
          '⚠️ Invalid index: $newIndex. Playlist length: ${_mediaPlaylist.length}');
    }
  }

  void _handleVolumeChange(double vol) {
    _volume.value = vol;
    _isMuted.value = vol == 0.0;
  }

  void _handlePlaybackCompletion() {
    Logger().i('Playback completed.');
    if (_audioPlayer.hasNext) {
      next();
    } else {
      _audioPlayer.stop();
    }
  }
  void showPlayerModal() {
    if (!(Get.isBottomSheetOpen ?? false)) {
      Get.bottomSheet(
        SafeArea(child: PlayerModal()),
        backgroundColor: Colors.transparent,
        isDismissible: true,
      );
    }
  }

  Future<void> recoverFromError() async {
    try {
      await _audioPlayer.stop();
      await _createAudioSources();
      if (_currentIndex.value >= 0) {
        await playAtIndex(_currentIndex.value);
      }
    } catch (e) {
      Logger().e('Recovery failed: $e');
      _playerState.value = CustomPlayerState.error;
      Get.snackbar('Error', 'Could not recover player.');
    }
  }

  Future<bool> isSongCached(String fileId) async {
    return await _songCacheManager
        .isSongCached(fileId); // assuming _songCacheManager is private
  }

  Future<Uri> getNotificationArtUriFromAsset() async {
    final byteData = await rootBundle.load('assets/s.png');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/default_art.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return Uri.file(file.path);
  }
}
