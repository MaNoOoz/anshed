import 'package:just_audio_background/just_audio_background.dart';

class Song {
  final String title;
  final String artist;
  final String fileId;
  final int? duration; // in milliseconds
  final String? album;
  final String? artUrl;
  final String? genre;
  final int? trackNumber;

  const Song({
    required this.title,
    required this.artist,
    required this.fileId,
    this.duration,
    this.album,
    this.artUrl,
    this.genre,
    this.trackNumber,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title']?.toString() ?? 'Unknown Title',
      artist: json['artist']?.toString() ?? 'Unknown Artist',
      fileId: json['file_id']?.toString() ?? '',
      duration: _parseDuration(json['duration']),
      album: json['album']?.toString(),
      artUrl: json['art_url']?.toString(),
      genre: json['genre']?.toString(),
      trackNumber: _parseTrackNumber(json['track_number']),
    );
  }

  static int? _parseDuration(dynamic duration) {
    if (duration == null) return null;
    if (duration is int) return duration;
    if (duration is String) return int.tryParse(duration);
    return null;
  }

  static int? _parseTrackNumber(dynamic trackNumber) {
    if (trackNumber == null) return null;
    if (trackNumber is int) return trackNumber;
    if (trackNumber is String) return int.tryParse(trackNumber);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'file_id': fileId,
      'duration': duration,
      'album': album,
      'art_url': artUrl,
      'genre': genre,
      'track_number': trackNumber,
    };
  }

  String get downloadUrl =>
      "https://drive.google.com/uc?export=download&id=$fileId";

  Duration get durationAsDuration =>
      duration != null ? Duration(milliseconds: duration!) : Duration.zero;

  MediaItem toMediaItem() {
    return MediaItem(
      id: fileId,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      duration: durationAsDuration,
      // trackNumber: trackNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          fileId == other.fileId;

  @override
  int get hashCode => fileId.hashCode;

  @override
  String toString() {
    return 'Song{title: $title, artist: $artist, fileId: $fileId}';
  }
}
