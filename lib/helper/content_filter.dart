import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ContentFilter {
  static final Set<String> _bannedWords = {};
  static bool _isInitialized = false;

  ///loading forbidden words from Json
  static Future<void> loadBannedWordsFromJson() async {
    if (_isInitialized) return;

    final jsonString = await rootBundle.loadString('assets/banned_words_multilingual.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);

    for (var entry in jsonMap.entries) {
      final words = List<String>.from(entry.value);
      _bannedWords.addAll(words.map((w) => w.toLowerCase()));
    }

    _isInitialized = true;
  }

  ///is that involved forbidden words?
  static bool hasBadWords(String text) {
    final lower = text.toLowerCase();
    return _bannedWords.any((word) => lower.contains(word));
  }

  /// is there any forbidden words on the text?
  static List<String> findBannedWords(String text) {
    final lower = text.toLowerCase();
    return _bannedWords.where((word) => lower.contains(word)).toList();
  }
}



//maybe we need forbidden sending video file
final List<String> bannedExtensions = [
  '.mp4',
  '.mov',
  '.avi',
  '.mkv',
  '.webm',
  '.flv',
  '.3gp',
  '.wmv',
];




