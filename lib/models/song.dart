import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Song {
  String url;
  String name;
  String? artist;
  DateTime? createdAt;
  DateTime? updatedAt;

  Song({
    required this.url,
    required this.name,
    this.artist,
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
      // Use 'Name' to match the JSON
      artist: obj.get<String>('artist'),
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
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
}
