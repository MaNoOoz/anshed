import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:logger/logger.dart';

import '../models/song.dart';
import '../widgets/PlayerModal.dart';
import 'SongCacheManager.dart';
import 'SongService.dart';

enum LoadingState { idle, loading, success, error }

class AudioPlayerController extends GetxController {
  final RxInt currentIndex = (-1).obs;
  final RxBool hasInitializedPlaylist = false.obs;
  final RxDouble _volume = 1.0.obs;
  final AudioPlayer audioPlayer = AudioPlayer();
  final SongService _songService = SongService();
  final SongCacheManager _songCacheManager = SongCacheManager();

  final Rx<LoadingState> loadingState = Rx<LoadingState>(LoadingState.idle);
  final Rx<List<Song>> _playlist = Rx<List<Song>>([]);
  final List<AudioSource> _audioSources = [];
  final Rx<MediaItem?> currentMediaItem = Rx<MediaItem?>(null);

  final RxInt downloadedCount = 0.obs;
  final RxInt totalSongs = 0.obs;
  final RxString currentSongName = ''.obs;
  final RxString currentSongSize = ''.obs;

  double get volume => _volume.value;

  bool get isMuted => _volume.value == 0.0;

  List<Song> get playlist => _playlist.value;

  bool get isPlaying => audioPlayer.playing;

  bool get hasNext => audioPlayer.hasNext;

  bool get hasPrevious => audioPlayer.hasPrevious;

  @override
  void onInit() {
    super.onInit();
    Future.microtask(() async => await init());
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }

  Future<void> init() async {
    _initializeAudioPlayer();
    await loadInitialPlaylist();
    final cachedSongs = await _songCacheManager.getAllCachedFiles();
    if (cachedSongs.isEmpty) await askUserTodownloadSongs();
    audioPlayer.setVolume(_volume.value);
  }

  Future<void> askUserTodownloadSongs() async {
    if (playlist.isEmpty) {
      return await Get.defaultDialog(
          title: 'Download Songs',
          content: Column(children: [
            Text('Do you want to download the songs?'),
            ElevatedButton(
              child: Text('Download'),
              onPressed: () async {
                await loadInitialPlaylist();
                Get.back();
              },
            ),
          ]));
    }
  }

  void setVolume(double value) {
    _volume.value = value.clamp(0.0, 1.0);
    audioPlayer.setVolume(_volume.value);
  }

  void _initializeAudioPlayer() {
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        Logger().i('processingState: ${currentIndex.value}');

        _handlePlaybackCompletion();
        update();
      }
    });

    audioPlayer.currentIndexStream.listen((index) {
      currentIndex.value = index ?? -1;
      if (index != null && index < _audioSources.length) {
        currentMediaItem.value =
            (_audioSources[index] as UriAudioSource).tag as MediaItem;
      }
    });

    audioPlayer.volumeStream.listen((value) => _volume.value = value);
  }

  Future<void> loadInitialPlaylist({bool cacheSongs = true}) async {
    if (hasInitializedPlaylist.value) return;
    try {
      loadingState.value = LoadingState.loading;
      final songs = await _songService.fetchSongs();
      // Sort songs alphabetically based on the artist's name
      songs.sort((a, b) => a.artist.compareTo(b.artist));
      _playlist.value = songs;

      if (cacheSongs) await _cacheSongs(songs);
      _playlist.value = songs;
      await _createAudioSources();
      loadingState.value = LoadingState.success;
      hasInitializedPlaylist.value = true;
      update();
    } catch (e) {
      loadingState.value = LoadingState.error;
      Logger().e('Error loading playlist: $e');
      Get.snackbar('Error', 'Failed to load playlist: ${e.toString()}');
      update();
    }
  }

  Future<bool> isSongCached(String fileId) async =>
      await _songCacheManager.isSongCached(fileId);

  Future<void> _cacheSongs(List<Song> songs) async {
    downloadedCount.value = 0;
    totalSongs.value = songs.length;
    for (final song in songs) {
      currentSongName.value = song.title;
      currentSongSize.value = "5";
      if (!await _songCacheManager.isSongCached(song.fileId)) {
        await _songCacheManager.downloadAndCacheSong(song.fileId);
      }
      downloadedCount.value++;
    }
  }

  Future<void> _createAudioSources() async {
    _audioSources.clear();
    for (final song in _playlist.value) {
      final file = await _songCacheManager.getCachedSong(song.fileId);
      if (file != null) {
        _audioSources.add(AudioSource.uri(
          Uri.file(file.file.path),
          tag: song.toMediaItem(),
        ));
      }
    }
    await audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: _audioSources),
      preload: true,
    );

    // Debug: Print the order of songs in the playlist and corresponding audio sources
    for (int i = 0; i < _playlist.value.length; i++) {
      Logger().i('Playlist[$i]: ${_playlist.value[i].title}');
    }
    for (int i = 0; i < _audioSources.length; i++) {
      final tag = (_audioSources[i] as UriAudioSource).tag as MediaItem;
      Logger().i('AudioSources[$i]: ${tag.title}');
    }
  }

  Future<void> playPlaylist(List<Song> songs, {int? startIndex}) async {
    try {
      if (!hasInitializedPlaylist.value) await loadInitialPlaylist();
      if (_audioSources.isEmpty)
        throw Exception('Playlist is empty. Failed to play.');
      int indexToPlay = startIndex ?? currentIndex.value;
      if (indexToPlay < 0 || indexToPlay >= _audioSources.length)
        throw Exception('Invalid index: $indexToPlay');
      currentIndex.value = indexToPlay;
      await audioPlayer.seek(Duration.zero, index: indexToPlay);
      currentMediaItem.value =
          (_audioSources[indexToPlay] as UriAudioSource).tag as MediaItem;
      await play();
    } catch (e) {
      Get.snackbar('Error', 'Failed to play: ${e.toString()}');
    }
  }

  Future<void> play() async {
    try {
      await audioPlayer.stop();
      await audioPlayer.play();
      update();
    } catch (e) {
      Get.snackbar('Error', 'Play failed: ${e.toString()}');
    }
  }

  Future<void> pause() async {
    try {
      await audioPlayer.pause();
      update();
    } catch (e) {
      Get.snackbar('Error', 'Pause failed: ${e.toString()}');
    }
  }

  void _handlePlaybackCompletion() {
    Logger().i('_handlePlaybackCompletion: ${currentIndex.value}');

    if (hasNext) {
      audioPlayer.seekToNext();
    } else {
      pause();
    }
  }

  void showPlayerModal() {
    if (!(Get.isBottomSheetOpen ?? false)) {
      Get.bottomSheet(SafeArea(child: PlayerModal()),
          backgroundColor: Colors.transparent, isDismissible: true);
    }
  }

  Future<void> recoverFromError() async {
    try {
      await audioPlayer.stop();
      await _createAudioSources();
      if (currentIndex.value >= 0) {
        await playPlaylist(_playlist.value, startIndex: currentIndex.value);
      }
    } catch (e) {
      Logger().e('Recovery failed: $e');
    }
  }
}
