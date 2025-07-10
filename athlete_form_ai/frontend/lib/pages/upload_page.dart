import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../config/api_config.dart';

class UploadPage extends StatefulWidget {
  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _videoFile;
  VideoPlayerController? _controller;
  String? _feedbackText;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _videoFile = file;
        _error = null;
        _controller = VideoPlayerController.file(file)..initialize().then((_) {
          setState(() {});
        });
      });
    }
  }

  Future<void> _uploadAndAnalyzeVideo() async {
    if (_videoFile == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    const userId = "user123"; // Replace with actual user ID
    const motionType = "sprint"; // Or "jump"

    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(_videoFile!.path, filename: "input.mp4"),
      "motion_type": motionType,
      "user_id": userId,
    });

    final dio = Dio();
    
    // Configure timeouts
    dio.options.connectTimeout = ApiConfig.connectionTimeout;
    dio.options.receiveTimeout = ApiConfig.receiveTimeout;

    try {
      final response = await dio.post(ApiConfig.analyzeEndpoint, data: formData);

      final data = response.data;
      final videoUrl = ApiConfig.apiBaseUrl + data['video_url'];
      final feedbackUrl = ApiConfig.apiBaseUrl + data['feedback_url'];

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
      String errorMessage = 'Upload failed: ${e.toString()}';
      
      // Check for specific connection errors
      if (e.toString().contains('No host specified') || 
          e.toString().contains('Connection failed') ||
          e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('SocketException')) {
        errorMessage = 'Connection error: Unable to reach Dash AI services.\n\nReason: ${e.toString()}\n\nPlease check your internet connection and try again.';
      }
      
      setState(() {
        _error = errorMessage;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _uploadAndAnalyzeVideo(),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<File> _downloadFile(String url, String savePath) async {
    final dio = Dio();
    dio.options.connectTimeout = ApiConfig.connectionTimeout;
    dio.options.receiveTimeout = ApiConfig.receiveTimeout;
    await dio.download(url, savePath);
    return File(savePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sprint/Jump Analyzer")),
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
              child: const Text("Pick Video"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _uploadAndAnalyzeVideo,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Upload & Analyze"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
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
