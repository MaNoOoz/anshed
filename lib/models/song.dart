import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class Song {
  final String name;
  final String url;

  Song({required this.name, required this.url});

  factory Song.fromParseObject(ParseObject parseObject) {
    final ParseFile? file = parseObject.get<ParseFile>('url');
    return Song(
      name: parseObject.get<String>('Name') ?? '',
      url: file?.url ?? '',
    );
  }
}
