import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';
import '../widgets/PlayerModal.dart';
import 'SongCacheManager.dart';
import 'SongService.dart';

enum LoadingState { idle, loading, success, error }

class AudioPlayerController extends GetxController {
  // Properties
  final RxInt currentIndex = (-1).obs; // -1 means no song selected
  final RxBool hasInitializedPlaylist = false.obs;

  // Getter for current playlist index
  int? get currentPlaylistIndex =>
      currentIndex.value >= 0 ? currentIndex.value : null;

  final Rx<LoopMode> loopMode = LoopMode.off.obs;
  final RxBool shuffleMode = false.obs;
  final AudioPlayer audioPlayer = AudioPlayer();
  final SongService _songService = SongService();
  final SongCacheManager _songCacheManager = SongCacheManager();

  final Rx<List<Song>> _playlist = Rx<List<Song>>([]);
  final Rx<LoadingState> loadingState = Rx<LoadingState>(LoadingState.idle);
  final List<AudioSource> _audioSources = [];
  final Rx<MediaItem?> currentMediaItem = Rx<MediaItem?>(MediaItem(
    id: '',
    title: '',
    artist: '',
    album: '',
    genre: '',
    artUri: Uri.parse('assets/s.png'),
  ));

  // Getters
  List<Song> get playlist => _playlist.value;

  bool get isPlaying => audioPlayer.playing;

  bool get hasNext => audioPlayer.hasNext;

  bool get hasPrevious => audioPlayer.hasPrevious;

  List<MediaItem> get mediaItems =>
      _playlist.value.map((song) => song.toMediaItem()).toList();

  // Toggle shuffle mode
  void toggleShuffle() {
    shuffleMode.toggle();
    audioPlayer.setShuffleModeEnabled(shuffleMode.value);
    update();
  }

  // Toggle loop mode using Dart's switch expression
  void toggleLoopMode() {
    final newMode = switch (loopMode.value) {
      LoopMode.off => LoopMode.one,
      LoopMode.one => LoopMode.all,
      LoopMode.all => LoopMode.off,
    };
    loopMode.value = newMode;
    audioPlayer.setLoopMode(newMode);
    update();
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAudioPlayer();
    loadInitialPlaylist();
  }

  // Initialize the audio player by listening to state streams
  void _initializeAudioPlayer() {
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handlePlaybackCompletion();
      }
    });

    audioPlayer.currentIndexStream.listen((index) {
      currentIndex.value = index ?? -1;
      if (index != null && index < _audioSources.length) {
        currentMediaItem.value =
            (_audioSources[index] as UriAudioSource).tag as MediaItem;
      }
    });
  }

  Future<bool> isSongCached(String fileId) async {
    return await _songCacheManager.isSongCached(fileId);
  }

  // Load the initial playlist (only once)
  Future<void> loadInitialPlaylist() async {
    if (hasInitializedPlaylist.value) return; // Prevent unnecessary reload

    try {
      loadingState.value = LoadingState.loading;
      final songs = await _songService.fetchSongs();
      await _cacheSongs(songs);
      _playlist.value = songs;
      await _createAudioSources();
      loadingState.value = LoadingState.success;
      hasInitializedPlaylist.value = true;
      update();
    } catch (e) {
      loadingState.value = LoadingState.error;
      Get.snackbar('Error', 'Failed to load playlist: ${e.toString()}');
      update();
    }
  }

  // Cache songs if not already cached
  Future<void> _cacheSongs(List<Song> songs) async {
    await Future.wait(songs.map((song) async {
      if (!await _songCacheManager.isSongCached(song.fileId)) {
        await _songCacheManager.downloadAndCacheSong(song.fileId);
      }
    }));
  }

  // Create audio sources for the player
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
  }

  // Play the given playlist starting at the specified index
  Future<void> playPlaylist(List<Song> songs, int startIndex) async {
    try {
      if (!hasInitializedPlaylist.value) {
        await loadInitialPlaylist();
      }
      if (startIndex < 0 || startIndex >= _audioSources.length) {
        throw Exception('Invalid start index: $startIndex');
      }

      currentIndex.value = startIndex; // Update current index
      await audioPlayer.seek(Duration.zero, index: startIndex);
      currentMediaItem.value =
          (_audioSources[startIndex] as UriAudioSource).tag as MediaItem;
      await play();
      update();
    } catch (e) {
      Get.snackbar('Error', 'Failed to play: ${e.toString()}');
    }
  }

  // Play a specific song in the playlist
  Future<void> playSong(int index) async {
    if (index >= 0 && index < _playlist.value.length) {
      await playPlaylist(_playlist.value, index);
    }
    update();
  }

  // Start playing the current audio
  Future<void> play() async {
    try {
      await audioPlayer.play();
      update();
    } catch (e) {
      Get.snackbar('Error', 'Play failed: ${e.toString()}');
    }
  }

  // Pause playback
  Future<void> pause() async {
    try {
      await audioPlayer.pause();
      update();
    } catch (e) {
      Get.snackbar('Error', 'Pause failed: ${e.toString()}');
    }
  }

  // Seek to a specific position in the current track
  Future<void> seek(Duration position) async {
    try {
      await audioPlayer.seek(position);
      update();
    } catch (e) {
      Get.snackbar('Error', 'Seek failed: ${e.toString()}');
    }
  }

  // Show the player modal if not already open
  void showPlayerModal() {
    if (!(Get.isBottomSheetOpen ?? false)) {
      Get.bottomSheet(
        SafeArea(child: PlayerModal()),
        backgroundColor: Colors.transparent,
        isDismissible: true,
      );
    }
  }

  // Skip to the previous track
  Future<void> skipToPrevious() async {
    try {
      if (hasPrevious) await audioPlayer.seekToPrevious();
      update();
    } catch (e) {
      Get.snackbar('Error', 'Skip failed: ${e.toString()}');
    }
  }

  // Skip to the next track
  Future<void> skipToNext() async {
    try {
      if (hasNext) await audioPlayer.seekToNext();
      update();
    } catch (e) {
      Get.snackbar('Error', 'Skip failed: ${e.toString()}');
    }
  }

  // Handle playback completion by moving to the next track or pausing playback
  void _handlePlaybackCompletion() {
    if (hasNext) {
      audioPlayer.seekToNext();
    } else {
      pause();
    }
    update();
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }

  // Expose streams for position and player state
  Stream<Duration> get positionStream => audioPlayer.positionStream;

  Stream<PlayerState> get playerStateStream => audioPlayer.playerStateStream;
}
