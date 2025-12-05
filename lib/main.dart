import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

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
      home: const AssistantSelector(),
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

enum AssistantType {
  kotokely,
  balita,
  ketaka,
}

class AssistantSelector extends StatelessWidget {
  const AssistantSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safidio ny Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF16213E),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAssistantCard(
                context,
                type: AssistantType.kotokely,
                title: 'Kotokely',
                subtitle: 'Text Chat & File Upload',
                icon: 'https://i.ibb.co/nM8LCgkb/php-Prk-X86.png',
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              _buildAssistantCard(
                context,
                type: AssistantType.balita,
                title: 'Balita',
                subtitle: 'Image Generation',
                icon: 'https://i.ibb.co/JWmgHf5F/phpi-JSe61-1.png',
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              _buildAssistantCard(
                context,
                type: AssistantType.ketaka,
                title: 'Ketaka',
                subtitle: 'Video Generation',
                icon: 'https://i.ibb.co/LXdmxHPx/phpd-Qio-KR.png',
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantCard(
    BuildContext context, {
    required AssistantType type,
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(assistantType: type),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  icon,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.assistant, size: 40, color: color);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final AssistantType assistantType;
  
  const ChatScreen({Key? key, required this.assistantType}) : super(key: key);

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
  
  final String _supabaseUrl = 'https://your-project.supabase.co/functions/v1/kotokely-ai';

  @override
  void initState() {
    super.initState();
    _messages.add(Message(
      text: _getWelcomeMessage(),
      isUser: false,
    ));
  }

  String _getWelcomeMessage() {
    switch (widget.assistantType) {
      case AssistantType.kotokely:
        return '🦎 Salama! Izaho i Kotokely!\n\n💬 Afaka manoratra, mamaky fichier, ary mandray valiny aho.\n\nInona no tianao hotadiavina?';
      case AssistantType.balita:
        return '🎨 Salama! Izaho i Balita!\n\n🖼️ Mamorona sary aho avy amin\'ny description-nao.\n\nLazao amiko ny sary tianao ho hitanao!';
      case AssistantType.ketaka:
        return '🎬 Salama! Izaho i Ketaka!\n\n📹 Mamorona video fohy aho (2-4s).\n\nLazao amiko ny video tianao ho hitanao!';
    }
  }

  String _getAssistantName() {
    switch (widget.assistantType) {
      case AssistantType.kotokely:
        return 'Kotokely';
      case AssistantType.balita:
        return 'Balita';
      case AssistantType.ketaka:
        return 'Ketaka';
    }
  }

  String _getAssistantIcon() {
    switch (widget.assistantType) {
      case AssistantType.kotokely:
        return 'https://i.ibb.co/nM8LCgkb/php-Prk-X86.png';
      case AssistantType.balita:
        return 'https://i.ibb.co/JWmgHf5F/phpi-JSe61-1.png';
      case AssistantType.ketaka:
        return 'https://i.ibb.co/LXdmxHPx/phpd-Qio-KR.png';
    }
  }

  Color _getAssistantColor() {
    switch (widget.assistantType) {
      case AssistantType.kotokely:
        return Colors.blue;
      case AssistantType.balita:
        return Colors.green;
      case AssistantType.ketaka:
        return Colors.orange;
    }
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
          'mode': widget.assistantType == AssistantType.kotokely
              ? 'chat'
              : widget.assistantType == AssistantType.balita
                  ? 'imageGen'
                  : 'videoGen',
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

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Text nadika tany clipboard')),
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Sary voatahiry: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Tsy afaka nitahiry: $e')),
      );
    }
  }

  Future<void> _shareImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/share_image.png';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      await Share.shareXFiles([XFile(filePath)], text: 'Sary avy amin\'ny Balita AI');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Tsy afaka nizara: $e')),
      );
    }
  }

  Future<void> _shareVideo(String videoUrl) async {
    try {
      final response = await http.get(Uri.parse(videoUrl));
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/share_video.mp4';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      await Share.shareXFiles([XFile(filePath)], text: 'Video avy amin\'ny Ketaka AI');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Tsy afaka nizara: $e')),
      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _getAssistantIcon(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.assistant, color: _getAssistantColor());
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(_getAssistantName(), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  CircularProgressIndicator(color: _getAssistantColor()),
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
                if (widget.assistantType == AssistantType.kotokely) ...[
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
                  icon: Icon(Icons.send, color: _getAssistantColor(), size: 28),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHintText() {
    switch (widget.assistantType) {
      case AssistantType.kotokely:
        return 'Soraty eto ny hafatrao...';
      case AssistantType.balita:
        return 'Lazao ny sary tianao (ex: sunset beach)...';
      case AssistantType.ketaka:
        return 'Lazao ny video tianao (ex: cat playing)...';
    }
  }

  String _getLoadingText() {
    switch (widget.assistantType) {
      case AssistantType.kotokely:
        return 'Mandinika...';
      case AssistantType.balita:
        return 'Mamorona sary...';
      case AssistantType.ketaka:
        return 'Mamorona video...';
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
            ? _getAssistantColor().withOpacity(0.8)
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
                child: Stack(
                  children: [
                    ClipRRect(
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
                    if (!message.isUser && message.imageUrl!.startsWith('http'))
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.download, color: Colors.white),
                              onPressed: () => _downloadImage(message.imageUrl!),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.white),
                              onPressed: () => _shareImage(message.imageUrl!),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (message.videoUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getAssistantColor(), width: 2),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.video_library, size: 48, color: _getAssistantColor()),
                          const SizedBox(height: 8),
                          const Text(
                            '🎬 Video vita!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                          onPressed: () => _downloadImage(message.videoUrl!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getAssistantColor(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                          onPressed: () => _shareVideo(message.videoUrl!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getAssistantColor(),
                          ),
                        ),
                      ],
                    ),
                  ],
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
            if (!message.isUser && widget.assistantType == AssistantType.kotokely)
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