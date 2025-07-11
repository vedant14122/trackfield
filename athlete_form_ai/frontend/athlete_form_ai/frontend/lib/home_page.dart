import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:io' show Platform;
import 'personalization_page.dart';
import 'package:flutter/foundation.dart';
import 'history_page.dart';
import 'main.dart'; // For ThemeNotifier

class HomePage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const HomePage({Key? key, required this.themeNotifier}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  String? _uploadStatus;
  String? _uploadError;
  bool _dragging = false;
  List<Map<String, dynamic>> _uploadedVideos = [];
  File? _selectedVideo;

  @override
  void initState() {
    super.initState();
    _fetchUploadedVideos();
  }

  Future<void> _fetchUploadedVideos() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('videos')
          .select()
          .eq('user_id', user.id)
          .order('uploaded_at', ascending: false)
          .limit(10);
      if (response != null && response is List) {
        setState(() {
          _uploadedVideos = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      String errorMessage = 'Failed to load videos: ${e.toString()}';
      
      // Check for specific connection errors
      if (e.toString().contains('No host specified') || 
          e.toString().contains('Connection failed') ||
          e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('SocketException')) {
        errorMessage = 'Connection error: Unable to load your videos.\n\nReason: ${e.toString()}\n\nPlease check your internet connection.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _fetchUploadedVideos(),
            ),
          ),
        );
      }
    }
  }

  Widget _animatedCard({required Widget child}) {
    final isDesktop = (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        boxShadow: isDesktop
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _hoverButton({required VoidCallback? onPressed, required String label}) {
    final isDesktop = (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    return MouseRegion(
      cursor: isDesktop ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadStatus = 'Picking video...';
        _uploadError = null;
      });

      XFile? video;
      File? fileToUpload;
      String? fileName;

      if (Platform.isIOS || Platform.isAndroid) {
        video = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );
        if (video != null) {
          fileToUpload = File(video.path);
          fileName = video.name;
        }
      } else {
        // Desktop: use file_picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          fileToUpload = File(result.files.single.path!);
          fileName = result.files.single.name;
        }
      }

      if (fileToUpload == null || fileName == null) {
        setState(() {
          _isUploading = false;
          _uploadStatus = null;
          _uploadError = 'No video selected.';
        });
        return;
      }

      setState(() {
        _uploadStatus = 'Uploading video...';
      });

      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create file path
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final filePath = '${user.id}/$uniqueFileName';

      // Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from('videos')
          .upload(filePath, fileToUpload, fileOptions: const FileOptions(
            contentType: 'video/mp4',
            upsert: false,
          ));

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('videos')
          .getPublicUrl(filePath);

      // Store video metadata in database
      await Supabase.instance.client
          .from('videos')
          .insert({
            'user_id': user.id,
            'file_path': filePath,
            'file_name': uniqueFileName,
            'file_url': publicUrl,
            'uploaded_at': DateTime.now().toIso8601String(),
            'status': 'uploaded',
          });

      setState(() {
        _uploadStatus = 'Video uploaded successfully!';
        _isUploading = false;
        _uploadError = null;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Complete'),
            content: const Text('Your video was uploaded successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HistoryPage(themeNotifier: widget.themeNotifier)),
                  );
                },
                child: const Text('View History'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

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
        _uploadStatus = null;
        _isUploading = false;
        _uploadError = errorMessage;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _pickAndUploadVideo(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    if (files.isEmpty) return;
    final file = files.first;
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading video...';
      _uploadError = null;
    });
    await _uploadVideoFile(File(file.path), file.name);
  }

  Future<void> _uploadVideoFile(File fileToUpload, String fileName) async {
    try {
      // Get current user
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final filePath = '${user.id}/$uniqueFileName';
      await Supabase.instance.client.storage
          .from('videos')
          .upload(filePath, fileToUpload, fileOptions: const FileOptions(
            contentType: 'video/mp4',
            upsert: false,
          ));
      final publicUrl = Supabase.instance.client.storage
          .from('videos')
          .getPublicUrl(filePath);
      await Supabase.instance.client
          .from('videos')
          .insert({
            'user_id': user.id,
            'file_path': filePath,
            'file_name': uniqueFileName,
            'file_url': publicUrl,
            'uploaded_at': DateTime.now().toIso8601String(),
            'status': 'uploaded',
          });
      setState(() {
        _uploadStatus = 'Video uploaded successfully!';
        _isUploading = false;
        _uploadError = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Upload failed: ${e.toString()}';
      
      // Check for specific connection errors
      if (e.toString().contains('No host specified') || 
          e.toString().contains('Connection failed') ||
          e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('SocketException')) {
        errorMessage = 'Connection error: Unable to reach Dash AI services. Please check your internet connection and try again.';
      }
      
      setState(() {
        _uploadStatus = null;
        _isUploading = false;
        _uploadError = errorMessage;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _uploadVideoFile(fileToUpload, fileName),
            ),
          ),
        );
      }
    }
  }

  // Remove all image upload and preview logic. Only allow video uploads.
  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
        _uploadError = null;
      });
    } else {
      setState(() {
        _uploadError = 'No video selected.';
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isDesktop = (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackField'),
        actions: [
          TextButton(
            onPressed: () => setState(() => widget.themeNotifier.toggleTheme()),
            child: Text(widget.themeNotifier.themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode'),
          ),
          TextButton(
            onPressed: _signOut,
            child: const Text('Logout'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return Center(
            child: Container(
              width: isWide ? 600 : double.infinity,
              padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 8, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.deepPurple.shade200,
                                child: Icon(Icons.person, size: 28, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome!',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Email: ${user?.email ?? 'Unknown'}'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Upload section
                  _animatedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Upload Video', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _pickVideo,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              side: BorderSide(color: Colors.deepPurple.shade200, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Upload Video', style: TextStyle(fontSize: 18)),
                          ),
                          if (_selectedVideo != null) ...[
                            const SizedBox(height: 16),
                            Text('Selected: ' + _selectedVideo!.path.split('/').last, textAlign: TextAlign.center),
                          ],
                          if (_uploadError != null) ...[
                            const SizedBox(height: 8),
                            Text(_uploadError!, style: const TextStyle(color: Colors.red)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Navigation buttons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          _hoverButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const PersonalizationPage()),
                              );
                            },
                            label: 'Complete Profile',
                          ),
                          const SizedBox(height: 8),
                          _hoverButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => HistoryPage(themeNotifier: widget.themeNotifier)),
                              );
                            },
                            label: 'View History',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

ElevatedButton _platformButton({required VoidCallback? onPressed, required IconData icon, required String label}) {
  if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    // Desktop/web: text only
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  } else {
    // Mobile: icon + text
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  }
} 