import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const KotokelyApp());
}

class SupabaseConfig {
  static const String supabaseUrl = 'https://zogohkfzplcuonkkfoov.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvZ29oa2Z6cGxjdW9ua2tmb292Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA4Nzk0ODAsImV4cCI6MjA3NjQ1NTQ4MH0.AeQ5pbrwjCAOsh8DA7pl33B7hLWfaiYwGa36CaeXCsw';
  static String get edgeFunctionUrl => '$supabaseUrl/functions/v1/kotokely-ai';
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

class AssistantSelector extends StatefulWidget {
  const AssistantSelector({Key? key}) : super(key: key);

  @override
  State<AssistantSelector> createState() => _AssistantSelectorState();
}

class _AssistantSelectorState extends State<AssistantSelector> {
  int? _hoveredIndex;

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
                index: 0,
                type: AssistantType.kotokely,
                title: 'Kotokely',
                subtitle: 'Text Chat & File Upload',
                icon: 'https://i.ibb.co/nM8LCgkb/php-Prk-X86.png',
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              _buildAssistantCard(
                context,
                index: 1,
                type: AssistantType.balita,
                title: 'Balita',
                subtitle: 'Image Generation',
                icon: 'https://i.ibb.co/JWmgHf5F/phpi-JSe61-1.png',
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              _buildAssistantCard(
                context,
                index: 2,
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
    required int index,
    required AssistantType type,
    required String title,
    required String subtitle,
    required String icon,
    required Color color,
  }) {
    final isHovered = _hoveredIndex == index;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
        child: InkWell(
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
              border: Border.all(color: color, width: isHovered ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isHovered ? 0.5 : 0.3),
                  blurRadius: isHovered ? 20 : 10,
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
  String? _generatedImageUrl;
  String? _generatedVideoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.assistantType == AssistantType.kotokely) {
      _messages.add(Message(
        text: '🦎 Salama! Izaho i Kotokely!\n\n💬 Afaka manoratra, mamaky fichier, ary mandray valiny aho.\n\nInona no tianao hotadiavina?',
        isUser: false,
      ));
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
      if (widget.assistantType == AssistantType.kotokely) {
        _messages.add(Message(
          text: userMessage,
          isUser: true,
          imageUrl: _selectedImagePath,
          fileName: _selectedFilePath?.split('/').last,
        ));
      }
      _isLoading = true;
      _generatedImageUrl = null;
      _generatedVideoUrl = null;
    });

    _messageController.clear();
    if (widget.assistantType == AssistantType.kotokely) {
      _scrollToBottom();
    }

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
          if (widget.assistantType == AssistantType.kotokely) {
            _messages.add(Message(
              text: data['response'] ?? 'Tsy nahita valiny',
              isUser: false,
            ));
          } else if (widget.assistantType == AssistantType.balita) {
            _generatedImageUrl = data['imageUrl'];
          } else {
            _generatedVideoUrl = data['videoUrl'];
          }
          _isLoading = false;
          _selectedImagePath = null;
          _selectedFilePath = null;
        });
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        if (widget.assistantType == AssistantType.kotokely) {
          _messages.add(Message(
            text: '❌ Nisy olana: $e',
            isUser: false,
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Nisy olana: $e')),
          );
        }
        _isLoading = false;
        _selectedImagePath = null;
        _selectedFilePath = null;
      });
    }

    if (widget.assistantType == AssistantType.kotokely) {
      _scrollToBottom();
    }
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

  Future<void> _downloadMedia(String url, String type) async {
    try {
      final status = await Permission.storage.request();
      
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Mila permission hanindrana')),
        );
        return;
      }

      final response = await http.get(Uri.parse(url));
      
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      
      final ext = type == 'image' ? 'png' : 'mp4';
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Voatahiry: $filePath'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Tsy afaka nitahiry: $e')),
      );
    }
  }

  Future<void> _shareMedia(String url, String type) async {
    try {
      final response = await http.get(Uri.parse(url));
      final directory = await getTemporaryDirectory();
      final ext = type == 'image' ? 'png' : 'mp4';
      final filePath = '${directory.path}/share_$type.$ext';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      await Share.shareXFiles(
        [XFile(filePath)],
        text: type == 'image' ? 'Sary avy amin\'ny Balita AI' : 'Video avy amin\'ny Ketaka AI',
      );
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
    if (widget.assistantType == AssistantType.balita) {
      return _buildBalitaScreen();
    } else if (widget.assistantType == AssistantType.ketaka) {
      return _buildKetakaScreen();
    } else {
      return _buildKotokelyScreen();
    }
  }

  Widget _buildKotokelyScreen() {
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
                  const Text('Mandinika...'),
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

  Widget _buildBalitaScreen() {
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
            const Text('Balita', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF16213E),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _generatedImageUrl != null
                  ? Stack(
                      children: [
                        InteractiveViewer(
                          child: Image.network(
                            _generatedImageUrl!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('❌ Tsy afaka nampiseho ny sary'),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.download),
                                label: const Text('Download'),
                                onPressed: () => _downloadMedia(_generatedImageUrl!, 'image'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                onPressed: () => _shareMedia(_generatedImageUrl!, 'image'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _isLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: _getAssistantColor()),
                            const SizedBox(height: 16),
                            const Text('Mamorona sary...', style: TextStyle(fontSize: 18)),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 100, color: _getAssistantColor()),
                              const SizedBox(height: 16),
                              const Text(
                                '🎨 Salama! Izaho i Balita!',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Mamorona sary aho avy amin\'ny description-nao.\n\nLazao amiko ny sary tianao ho hitanao!',
                                style: TextStyle(fontSize: 16, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Lazao ny sary tianao (ex: sunset beach)...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.auto_awesome, color: _getAssistantColor(), size: 32),
                  onPressed: _sendMessage,
                  tooltip: 'Mamorona sary',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKetakaScreen() {
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
            const Text('Ketaka', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF16213E),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _generatedVideoUrl != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _getAssistantColor(), width: 3),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.video_library, size: 100, color: _getAssistantColor()),
                              const SizedBox(height: 16),
                              const Text(
                                '🎬 Video vita!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                              onPressed: () => _downloadMedia(_generatedVideoUrl!, 'video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              onPressed: () => _shareMedia(_generatedVideoUrl!, 'video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : _isLoading
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: _getAssistantColor()),
                            const SizedBox(height: 16),
                            const Text('Mamorona video...', style: TextStyle(fontSize: 18)),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library, size: 100, color: _getAssistantColor()),
                              const SizedBox(height: 16),
                              const Text(
                                '🎬 Salama! Izaho i Ketaka!',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Mamorona video fohy aho (2-4s).\n\nLazao amiko ny video tianao ho hitanao!',
                                style: TextStyle(fontSize: 16, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Lazao ny video tianao (ex: cat playing)...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.movie_creation, color: _getAssistantColor(), size: 32),
                  onPressed: _sendMessage,
                  tooltip: 'Mamorona video',
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