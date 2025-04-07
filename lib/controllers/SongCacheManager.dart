import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> downloadAndSaveSongToLocation(
      String fileId, String saveDirectoryPath, String fileExtension) async {
    final songUrl = 'https://drive.google.com/uc?export=download&id=$fileId';

    try {
      // Create the directory if it doesn't exist
      final saveDirectory = Directory(saveDirectoryPath);
      if (!await saveDirectory.exists()) {
        await saveDirectory.create(recursive: true);
      }

      // File path for the song
      final filePath = '${saveDirectory.path}/$fileId.$fileExtension';

      // Download the file and save it to the specified location
      final response = await HttpClient().getUrl(Uri.parse(songUrl));
      final file = await response.close().then((res) async {
        final file = File(filePath);
        await res.pipe(file.openWrite());
        return file;
      });

      print('Song downloaded and saved at: ${file.path}');
    } catch (e) {
      print('Error downloading or saving song: $e');
    }
  } // Retrieve cached song file info

  Future<FileInfo?> getCachedSong(String fileId) async {
    final songUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
    try {
      return await _cacheManager.getFileFromCache(songUrl);
    } catch (e) {
      print('Error retrieving cached song: $e');
      return null;
    }
  }

  Future<String?> getCachedSongPath(String fileId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileId.mp3';
      final file = File(filePath);

      if (await file.exists()) {
        return file.path;
      }
    } catch (e) {
      Logger().e('Failed to check cached song: $e');
    }
    return null;
  }

  Future<List<File>> getAllCachedFiles() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(
        '${tempDir.path}/libCachedImageData'); // DefaultCacheManager's folder structure may vary
    final List<File> files = [];

    if (await cacheDir.exists()) {
      await for (var entity
          in cacheDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          files.add(entity);
        }
      }
    }
    return files;
  }

  // Check if the song exists in the cache
  Future<bool> isSongCached(String fileId) async {
    final songUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
    final cachedFile = await _cacheManager.getFileFromCache(songUrl);
    return cachedFile != null;
  }
}
