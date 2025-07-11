import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import '../services/feedback_service.dart';
import '../config/api_config.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class ChatPage extends StatefulWidget {
  final String userId;
  final String videoUrl;
  final String? videoFilename;
  const ChatPage({Key? key, required this.userId, required this.videoUrl, this.videoFilename}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _error;
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  List<KeyframeFeedback> _keyframes = [];
  bool _loadingKeyframes = true;
  int? _selectedKeyframe;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _videoInitialized = true;
        });
      });
    _fetchKeyframes();
  }

  Future<void> _fetchKeyframes() async {
    setState(() {
      _loadingKeyframes = true;
    });
    try {
      final keyframes = await FeedbackService.fetchKeyframes(
        userId: widget.userId,
        videoFilename: widget.videoFilename,
      );
      setState(() {
        _keyframes = keyframes;
        _loadingKeyframes = false;
      });
    } catch (e) {
      setState(() {
        _keyframes = [];
        _loadingKeyframes = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
      _controller.clear();
      _error = null;
    });
    _scrollToBottom();
    try {
      final contextMap = {
        'recent_feedback': _keyframes.map((kf) => {
          'frame': kf.frame,
          'feedback': kf.feedback,
        }).toList(),
        'selected_keyframe': _selectedKeyframe,
      };
      final response = await http.post(
        Uri.parse(ApiConfig.chatEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'question': text,
          'context': contextMap,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.add(ChatMessage(text: data['response'], isUser: false, timestamp: DateTime.now()));
        });
      } else {
        setState(() {
          _error = 'Error: ${response.body}';
          _messages.add(ChatMessage(text: _error!, isUser: false, timestamp: DateTime.now()));
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _messages.add(ChatMessage(text: _error!, isUser: false, timestamp: DateTime.now()));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildChatBubble(ChatMessage msg) {
    final time = DateFormat('h:mm a').format(msg.timestamp);
    final isUser = msg.isUser;
    final avatar = isUser
        ? const CircleAvatar(child: Icon(Icons.person, color: Colors.white))
        : const CircleAvatar(child: Icon(Icons.smart_toy, color: Colors.deepPurple));
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) avatar,
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[200] : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(msg.text),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) avatar,
        ],
      ),
    );
  }

  Widget _buildKeyframeTimeline() {
    if (_loadingKeyframes) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_keyframes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No keyframe feedback available.'),
      );
    }
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _keyframes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final kf = _keyframes[index];
          final isSelected = _selectedKeyframe == kf.frame;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedKeyframe = kf.frame;
                // Seek video to keyframe (approximate by frame/time)
                if (_videoController.value.isInitialized) {
                  final duration = _videoController.value.duration;
                  final frameCount = _keyframes.last.frame + 1;
                  final target = duration * (kf.frame / frameCount);
                  _videoController.seekTo(target);
                }
              });
            },
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Frame ${kf.frame}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      kf.feedback,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach Chat')),
      body: Column(
        children: [
          // Video player at the top
          AspectRatio(
            aspectRatio: _videoInitialized ? _videoController.value.aspectRatio : 16 / 9,
            child: _videoInitialized
                ? Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      VideoPlayer(_videoController),
                      VideoProgressIndicator(_videoController, allowScrubbing: true),
                      Align(
                        alignment: Alignment.center,
                        child: IconButton(
                          icon: Icon(
                            _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _videoController.value.isPlaying
                                  ? _videoController.pause()
                                  : _videoController.play();
                            });
                          },
                        ),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          const Divider(height: 1),
          // Keyframe timeline/feedback history
          _buildKeyframeTimeline(),
          const Divider(height: 1),
          // Chat below
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const CircleAvatar(child: Icon(Icons.smart_toy, color: Colors.deepPurple)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('AI is typing...'),
                      ),
                    ],
                  );
                }
                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Ask a question...'
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 