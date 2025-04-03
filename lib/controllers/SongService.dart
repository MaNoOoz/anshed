import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/song.dart';

class SongService {
  final String jsonUrl =
      "https://drive.google.com/uc?export=download&id=15umR2OEyNepgufPLylIL5CXb91ex-VUT";

  Future<List<Song>> fetchSongs() async {
    try {
      final response = await http.get(Uri.parse(jsonUrl));

      if (response.statusCode == 200) {
        String decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);
        return data.map((songJson) => Song.fromJson(songJson)).toList();
      } else {
        throw Exception('Failed to load songs');
      }
    } catch (e) {
      throw Exception('Error fetching songs: $e');
    }
  }
}
