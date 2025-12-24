import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  runApp(const PhilosophePascalApp());
}

class SupabaseConfig {
  static const String supabaseUrl = 'https://zogohkfzplcuonkkfoov.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvZ29oa2Z6cGxjdW9ua2tmb292Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4Nzk0ODAsImV4cCI6MjA3NjQ1NTQ4MH0.AeQ5pbrwjCAOsh8DA7pl33B7hLWfaiYwGa36CaeXCsw';
  static String get edgeFunctionUrl => '$supabaseUrl/functions/v1/kotokely-ai';
}

class PhilosophePascalApp extends StatelessWidget {
  const PhilosophePascalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Philosophe Pascal',
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
  
  Message({
    required this.text,
    required this.isUser,
    this.imageUrl,
    this.fileName,
  });
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

  @override
  void initState() {
    super.initState();
    _messages.add(Message(
      text: '🧠 Salama! Izaho i Philosophe Pascal!\n\n💭 Afaka mifanakalo hevitra aminao aho momba ny fiainana, ny filozofia, ary ny fanontaniana lalina.\n\nInona no tianao iresahana?',
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
        Uri.parse(SupabaseConfig.edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        },
        body: jsonEncode({
          'message': userMessage,
          'image': imageBase64,
          'file': fileContent,
          'mode': 'chat',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(Message(
            text: data['response'] ?? 'Tsy nahita valiny',
            isUser: false,
          ));
          _isLoading = false;
          _selectedImagePath = null;
          _selectedFilePath = null;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
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

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Text nadika tany clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://i.ibb.co/Z1fwzS1C/IMG-20251224-104653.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.psychology, color: Colors.purple);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Philosophe Pascal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
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
                children: const [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(width: 12),
                  Text('Misaina...'),
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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
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
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Soraty eto ny hafatrao...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purple, size: 28),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            ? Colors.purple.withOpacity(0.8)
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
            if (message.imageUrl != null && message.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(message.imageUrl!),
                    height: 150,
                    fit: BoxFit.cover,
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
            if (!message.isUser)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _copyText(message.text),
                  tooltip: 'Copy text',
                ),
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