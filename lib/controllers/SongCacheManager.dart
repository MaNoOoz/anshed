import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SongCacheManager {
  final BaseCacheManager _cacheManager = DefaultCacheManager();

  // Download and cache song, including caching its metadata
  Future<void> downloadAndCacheSong(String fileId) async {
    final songUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
    try {
      final file = await _cacheManager.getSingleFile(songUrl);

      // Here, you could store additional song metadata if needed
      // e.g., song title, artist, etc. But for now, we just cache the file
      print('Song downloaded and cached at: ${file.path}');
    } catch (e) {
      print('Error downloading or caching song: $e');
    }
  }

  // Retrieve cached song file info
  Future<FileInfo?> getCachedSong(String fileId) async {
    final songUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
    try {
      return await _cacheManager.getFileFromCache(songUrl);
    } catch (e) {
      print('Error retrieving cached song: $e');
      return null;
    }
  }

  // Check if the song exists in the cache
  Future<bool> isSongCached(String fileId) async {
    final songUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
    final cachedFile = await _cacheManager.getFileFromCache(songUrl);
    return cachedFile != null;
  }
}
