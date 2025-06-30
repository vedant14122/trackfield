import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

class UploadPage extends StatefulWidget {
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _videoFile;
  VideoPlayerController? _controller;
  String? _feedbackText;
  bool _isLoading = false;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _videoFile = file;
        _controller = VideoPlayerController.file(file)..initialize().then((_) {
          setState(() {});
        });
      });
    }
  }

  Future<void> _uploadAndAnalyzeVideo() async {
    if (_videoFile == null) return;

    setState(() => _isLoading = true);

    const userId = "user123"; // Replace with actual user ID
    const motionType = "sprint"; // Or "jump"
    const apiUrl = "http://<YOUR_BACKEND_IP>:8000/analyze"; // Replace with your server

    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(_videoFile!.path, filename: "input.mp4"),
      "motion_type": motionType,
      "user_id": userId,
    });

    final dio = Dio();

    try {
      final response = await dio.post(apiUrl, data: formData);

      final data = response.data;
      final videoUrl = "http://<YOUR_BACKEND_IP>:8000" + data['video_url'];
      final feedbackUrl = "http://<YOUR_BACKEND_IP>:8000" + data['feedback_url'];

      final feedback = await dio.get(feedbackUrl);
      final localDir = await getApplicationDocumentsDirectory();

      final savedVideo = await _downloadFile(videoUrl, "${localDir.path}/saved_video.mp4");
      final savedFeedback = await _downloadFile(feedbackUrl, "${localDir.path}/feedback.json");

      setState(() {
        _videoFile = savedVideo;
        _controller = VideoPlayerController.file(savedVideo)..initialize().then((_) {
          setState(() {});
        });
        _feedbackText = jsonEncode(feedback.data);
      });
    } catch (e) {
      print("Upload error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<File> _downloadFile(String url, String savePath) async {
    final dio = Dio();
    await dio.download(url, savePath);
    return File(savePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sprint/Jump Analyzer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_videoFile != null && _controller != null && _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text("Pick Video"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadAndAnalyzeVideo,
              child: _isLoading ? CircularProgressIndicator() : Text("Upload & Analyze"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_feedbackText ?? "No feedback yet."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
