import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';

class ApiService {
  static final String _apiUrl = 'http://your-backend-url/analyze';

  static Future<String?> uploadVideo(File videoFile) async {
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString('gender') ?? '';
    final height = prefs.getString('height') ?? '';

    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));
    request.fields['gender'] = gender;
    request.fields['height'] = height;

    final response = await request.send();
    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      return resBody;
    } else {
      return null;
    }
  }
}
