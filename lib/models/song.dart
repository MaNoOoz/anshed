import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Song {
  String url;
  String name;
  String? artist;
  String? artworkUrl; // Optional artwork URL
  DateTime? createdAt;
  DateTime? updatedAt;

  Song({
    required this.url,
    required this.name,
    this.artist,
    this.artworkUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Song.fromParseObject(ParseObject obj) {
    // ParseFile for URL
    ParseFile? file = obj.get<ParseFile>('url');
    // Extract the url from the nested object
    String songUrl = '';
    if (file != null) {
      songUrl = file.url ?? '';
    } else {
      // Handle the case where 'url' is a nested object
      final urlObject = obj.get<Map<String, dynamic>>('url');
      if (urlObject != null && urlObject.containsKey('url')) {
        songUrl = urlObject['url'] as String;
      }
    }

    return Song(
      url: songUrl,
      name: obj.get<String>('Name') ?? '',
      artist: obj.get<String>('artist'),
      artworkUrl: obj.get<String>('artworkUrl'), // Get artwork URL if exists
      createdAt: obj.get<DateTime>('createdAt'),
      updatedAt: obj.get<DateTime>('updatedAt'),
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      name: json['name'],
      url: json['url'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'artworkUrl': artworkUrl, // Add artwork URL to JSON
      'updatedAt': updatedAt?.toIso8601String(),
      'artist': artist,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Song &&
        other.url == url &&  // Compare based on url
        other.name == name;  // Optionally include name for more specific comparison
  }

  @override
  int get hashCode => url.hashCode ^ name.hashCode; // Unique hash based on url and name
}
