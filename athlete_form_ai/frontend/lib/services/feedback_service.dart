import 'dart:convert';
import 'package:http/http.dart' as http;

class KeyframeFeedback {
  final int frame;
  final String feedback;
  final String? videoFilename;

  KeyframeFeedback({required this.frame, required this.feedback, this.videoFilename});

  factory KeyframeFeedback.fromJson(Map<String, dynamic> json) {
    return KeyframeFeedback(
      frame: json['frame'] as int,
      feedback: json['feedback'] as String,
      videoFilename: json['video_filename'] as String?,
    );
  }
}

class FeedbackService {
  // Set this to your backend base URL
  static const String baseUrl = 'http://localhost:8000';

  static Future<List<KeyframeFeedback>> fetchKeyframes({required String userId, String? videoFilename}) async {
    final uri = Uri.parse('$baseUrl/keyframes').replace(
      queryParameters: {
        'user_id': userId,
        if (videoFilename != null) 'video_filename': videoFilename,
      },
    );
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final keyframes = data['keyframes'] as List<dynamic>;
      return keyframes.map((kf) => KeyframeFeedback.fromJson(kf)).toList();
    } else {
      throw Exception('Failed to fetch keyframes: ${response.body}');
    }
  }
} 