import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';
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
  final currentMediaItem =
      Rx<MediaItem?>(null); // Observable for the current media item
  void setCurrentMediaItem(int index) {
    currentMediaItem.value = mediaPlaylist[index];
  }

  List<MediaItem> get mediaPlaylist => _mediaPlaylist;

  // Reactive State
  final Rx<CustomPlayerState> _playerState = CustomPlayerState.idle.obs;
  final RxList<Song> _playlist = RxList<Song>([]);

  final RxInt _currentIndex = 0.obs;
  final RxDouble _volume = 1.0.obs;
  final RxBool _isMuted = false.obs;

  // Properties
  CustomPlayerState get playerState => _playerState.value;

  List<Song> get playlist => _playlist;

  RxInt get currentIndex => _currentIndex;

  double get volume => _volume.value;

  bool get isMuted => _isMuted.value;

  bool get hasNext => _currentIndex.value < _playlist.length - 1;

  bool get hasPrevious => _currentIndex.value > 0;

// Inside AudioPlayerController
  final RxString title = ''.obs; // Reactive property for title

  void updateTitle() {
    title.value = currentMediaItem.value?.title ?? 'No Title';
  }

  // Constructor
  AudioPlayerController(this._songService, this._songCacheManager);

  @override
  void onInit() {
    super.onInit();
    _initAudioPlayer();
    _initialize();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> _initialize() async {
    await createAudioSourcesFromApi();
  }

  void _initAudioPlayer() {
    // Update _currentIndex and currentMediaItem when song changes
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < mediaPlaylist.length) {
        _currentIndex.value = index;
        currentMediaItem.value = mediaPlaylist[index];
        updateTitle();
        Logger().i("Title Updated: ${title.value}");
        Logger().i(
            'Current index updated: $_currentIndex, Media item: ${currentMediaItem.value?.title}');
      } else {
        Logger().w('Invalid index: $index');
      }
    });

    // Set initial values
    if (mediaPlaylist.isNotEmpty) {
      _currentIndex.value = 0;
      currentMediaItem.value = mediaPlaylist[0];
    }
  }

  Future<void> setCurrentIndex(int index) async {
    try {
      await audioPlayer.seek(Duration.zero, index: index);
      currentIndex.value = index;
      title.value = mediaPlaylist[index].title;
      Logger().i('Switched to: ${mediaPlaylist[index].title}');
    } catch (e) {
      Logger().e('Failed to set current index: $e');
    }
  }

  void goToNext() {
    if (hasNext) {
      setCurrentIndex(_currentIndex.value + 1);
      _audioPlayer.seekToNext();
    } else {
      Logger().w('No next track available');
    }
  }

  void goToPrevious() {
    if (hasPrevious) {
      setCurrentIndex(_currentIndex.value - 1);
      _audioPlayer.seekToPrevious();
    } else {
      Logger().w('No previous track available');
    }
  }

  Future<void> createAudioSourcesFromApi() async {
    Logger().i('Creating audio sources from API...');
    try {
      final sources = <AudioSource>[];

      // Fetch songs from API
      final apiSongs = await _songService.fetchSongs();
      apiSongs.sort((a, b) => a.artist.compareTo(b.artist));

      if (apiSongs.isEmpty) {
        Logger().w('No songs returned from API.');
        _playerState.value = CustomPlayerState.error;
        return;
      }

      for (final song in apiSongs) {
        // Construct the Google Drive download URL
        final fileUrl =
            'https://drive.google.com/uc?export=download&id=${song.fileId}';

        // Add to audio sources
        sources.add(AudioSource.uri(
          Uri.parse(fileUrl), // Use the constructed URL
          tag: MediaItem(
            id: song.fileId,
            title: song.title,
            artist: song.artist,
            album: song.album,
            // duration: Duration(milliseconds: song.duration!),
            // artUri: Uri.parse(song.artUrl!), // Cover art URL
            genre: song.genre, // Add other metadata if needed
          ),
        ));
      }
      _mediaPlaylist.value = convertPlaylistToMediaItems(apiSongs);

      if (sources.isNotEmpty) {
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: sources),
          initialIndex: 0,
        );
        Logger().i('Audio sources created from API. Total: ${sources.length}');
      } else {
        Logger().w('No valid audio sources found.');
        _playerState.value = CustomPlayerState.error;
      }
    } catch (e) {
      Logger().e('Error creating audio sources from API: $e');
      _playerState.value = CustomPlayerState.error;
    }
  }

  // Function to convert playlist to MediaItem list
  List<MediaItem> convertPlaylistToMediaItems(List<Song> playlist) {
    return playlist.map((song) {
      return MediaItem(
        id: song.fileId,
        // Unique identifier for the audio file
        title: song.title,
        // Song title
        artist: song.artist,
        // Song artist
        album: song.album,
        // Song album
        // duration: Duration(milliseconds: song.duration), // Convert duration from ms
        // artUri: Uri.parse(song.art_url), // Album art URL (cover art)
        genre: song.genre, // Optional: Include genre if needed
      );
    }).toList();
  }

  Future<void> clearPlaylist() async {
    Logger().d('clearPlaylist  ');

    await _songCacheManager.getAllCachedFiles().then((files) {
      for (var file in files) {
        Logger().d('file  ${file.path}');

        file.delete();
      }
    });
    Logger().i('Playlist cleared ${_songCacheManager.getAllCachedFiles()}');
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

  void setVolume(double value) async {
    _volume.value = value;
    await _audioPlayer.setVolume(value);
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

  void _handlePlaybackCompletion() {
    Logger().i('Playback completed.');
    if (_audioPlayer.hasNext) {
      _audioPlayer.seekToNext();
    } else {
      _audioPlayer.stop();
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
