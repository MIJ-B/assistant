import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(const KotokelyApp());
}

class KotokelyApp extends StatelessWidget {
  const KotokelyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kotokely AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9D4EDD),
          secondary: Color(0xFF7B2CBF),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;
  final String? imageUrl;
  final String? fileName;
  final String? videoUrl;
  
  Message({
    required this.text,
    required this.isUser,
    this.imageUrl,
    this.fileName,
    this.videoUrl,
  });
}

enum AIMode {
  chat,
  imageGen,
  videoGen,
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  String? _selectedImagePath;
  String? _selectedFilePath;
  AIMode _currentMode = AIMode.chat;
  
  // ⚠️ OVAO IO: Remplaza eto ny URL Supabase Edge Function-nao
  final String _supabaseUrl = 'https://your-project.supabase.co/functions/v1/kotokely-ai';

  @override
  void initState() {
    super.initState();
    _messages.add(Message(
      text: '🦎 Salama! Izaho i Kotokely!\n\n💬 Chat - Gemini 2.0 Flash\n🎨 Image - Pollinations/Flux (FREE)\n🎬 Video - ModelScope (FREE)\n\nInona no tianao hatao?',
      isUser: false,
    ));
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImagePath == null && _selectedFilePath == null) {
      return;
    }

    final userMessage = _messageController.text.trim();
    
    setState(() {
      _messages.add(Message(
        text: userMessage,
        isUser: true,
        imageUrl: _selectedImagePath,
        fileName: _selectedFilePath?.split('/').last,
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String? imageBase64;
      String? fileContent;
      
      if (_selectedImagePath != null) {
        final bytes = await File(_selectedImagePath!).readAsBytes();
        imageBase64 = base64Encode(bytes);
      }
      
      if (_selectedFilePath != null) {
        fileContent = await File(_selectedFilePath!).readAsString();
      }

      final response = await http.post(
        Uri.parse(_supabaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userMessage,
          'image': imageBase64,
          'file': fileContent,
          'mode': _currentMode.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(Message(
            text: data['response'] ?? 'Tsy nahita valiny',
            isUser: false,
            imageUrl: data['imageUrl'],
            videoUrl: data['videoUrl'],
          ));
          _isLoading = false;
          _selectedImagePath = null;
          _selectedFilePath = null;
        });
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.add(Message(
          text: '❌ Nisy olana: $e',
          isUser: false,
        ));
        _isLoading = false;
        _selectedImagePath = null;
        _selectedFilePath = null;
      });
    }

    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'pdf', 'doc', 'docx'],
    );
    
    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: Colors.purpleAccent),
            const SizedBox(width: 8),
            const Text('Kotokely AI', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            _buildModeSelector(),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF16213E),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 12),
                  Text(_getLoadingText()),
                ],
              ),
            ),
          
          if (_selectedImagePath != null || _selectedFilePath != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black26,
              child: Row(
                children: [
                  if (_selectedImagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImagePath!),
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _selectedImagePath = null),
                    ),
                  ],
                  if (_selectedFilePath != null) ...[
                    const Icon(Icons.description),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFilePath!.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => setState(() => _selectedFilePath = null),
                    ),
                  ],
                ],
              ),
            ),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentMode == AIMode.chat) ...[
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.blue),
                    onPressed: _pickImage,
                    tooltip: 'Upload sary',
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.green),
                    onPressed: _pickFile,
                    tooltip: 'Upload fichier',
                  ),
                ],
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _getHintText(),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(_getModeIcon(), color: Colors.purpleAccent, size: 28),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<AIMode>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getModeIcon(), size: 20),
            const SizedBox(width: 4),
            Text(_getModeName(), style: const TextStyle(fontSize: 12)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
        onSelected: (mode) {
          setState(() {
            _currentMode = mode;
          });
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: AIMode.chat,
            child: Row(
              children: [
                Icon(Icons.chat, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text('💬 Chat'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: AIMode.imageGen,
            child: Row(
              children: [
                Icon(Icons.image, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text('🎨 Image'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: AIMode.videoGen,
            child: Row(
              children: [
                Icon(Icons.video_library, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text('🎬 Video'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon() {
    switch (_currentMode) {
      case AIMode.chat:
        return Icons.chat;
      case AIMode.imageGen:
        return Icons.image;
      case AIMode.videoGen:
        return Icons.video_library;
    }
  }

  String _getModeName() {
    switch (_currentMode) {
      case AIMode.chat:
        return 'Chat';
      case AIMode.imageGen:
        return 'Image';
      case AIMode.videoGen:
        return 'Video';
    }
  }

  String _getHintText() {
    switch (_currentMode) {
      case AIMode.chat:
        return 'Soraty eto ny hafatrao...';
      case AIMode.imageGen:
        return 'Lazao ny sary tianao (ex: sunset beach)...';
      case AIMode.videoGen:
        return 'Lazao ny video tianao (ex: cat playing)...';
    }
  }

  String _getLoadingText() {
    switch (_currentMode) {
      case AIMode.chat:
        return 'Mandinika...';
      case AIMode.imageGen:
        return 'Mamorona sary...';
      case AIMode.videoGen:
        return 'Mamorona video (30-60s)...';
    }
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser 
            ? const Color(0xFF7B2CBF) 
            : const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: message.imageUrl!.startsWith('http')
                    ? Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          );
                        },
                      )
                    : Image.file(
                        File(message.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                ),
              ),
            if (message.videoUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purpleAccent, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.video_library, size: 48, color: Colors.purpleAccent),
                      const SizedBox(height: 8),
                      const Text(
                        '🎬 Video vita!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Base64 video (2s @ 256x256)',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            if (message.fileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          message.fileName!,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Text(
              message.text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
