import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const HistoryPage({Key? key, required this.themeNotifier}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];
  Map<String, List<Map<String, dynamic>>> _chats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Not logged in.';
        _loading = false;
      });
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('videos')
          .select()
          .eq('user_id', user.id)
          .order('uploaded_at', ascending: false)
          .limit(20);
      if (response != null && response is List) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(response);
        });
        // Fetch chat previews for each video
        for (final video in _history) {
          final fileName = video['file_name'];
          if (fileName != null) {
            _fetchChatPreview(user.id, fileName);
          }
        }
      } else {
        setState(() {
          _history = [];
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load history:  [${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchChatPreview(String userId, String videoFilename) async {
    try {
      // Replace with your backend endpoint if needed
      final uri = Uri.parse('http://localhost:8000/chat_history')
          .replace(queryParameters: {
        'user_id': userId,
        'video_filename': videoFilename,
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chatList = (data['chats'] as List<dynamic>)
            .map((msg) => msg as Map<String, dynamic>)
            .toList();
        setState(() {
          _chats[videoFilename] = chatList;
        });
      }
    } catch (e) {
      // Optionally handle chat fetch errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 56, color: Colors.deepPurple.shade200),
                          const SizedBox(height: 16),
                          Text(
                            'No videos uploaded yet!\nYour uploaded videos and chats will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final fileName = item['file_name'];
                        final chatPreview = _chats[fileName]?.isNotEmpty == true
                            ? _chats[fileName]!.last['text'] ?? ''
                            : 'No chat yet.';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.videocam, size: 32),
                            title: Text(item['file_name'] ?? 'Video'),
                            subtitle: Text(
                              'Uploaded: ${item['uploaded_at'] ?? ''}\nChat: $chatPreview',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.deepPurple.shade200),
                            onTap: () {
                              // Show full chat in a dialog
                              final chatList = _chats[fileName] ?? [];
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Chat for ${item['file_name'] ?? 'Video'}'),
                                  content: chatList.isEmpty
                                      ? const Text('No chat history for this video.')
                                      : SizedBox(
                                          width: 350,
                                          child: ListView(
                                            shrinkWrap: true,
                                            children: chatList
                                                .map((msg) => ListTile(
                                                      title: Text(msg['text'] ?? ''),
                                                      subtitle: Text(msg['isUser'] == true ? 'You' : 'AI'),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
} 