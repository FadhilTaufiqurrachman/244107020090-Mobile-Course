import 'dart:async';

import 'package:flutter/material.dart';

import '../ai/ai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

class ChatScreen extends StatefulWidget {
  final AiService? aiService;

  const ChatScreen({super.key, this.aiService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final AiService _aiService;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Halo! Saya asisten cerdas Campus Notify. Tanyakan informasi seputar pengumuman kampus, jadwal akademik, atau kegiatan perkuliahan.',
      isUser: false,
    ),
  ];

  bool _isLoading = false;
  bool _hasApiKey = false;
  StreamSubscription<String>? _streamSub;

  final List<String> _quickPrompts = [
    'Jadwal KRS Semester Ini',
    'Info Beasiswa Prestasi',
    'Prosedur Izin Perkuliahan',
  ];

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService();
    _checkApiKey();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final key = await _aiService.getApiKey();
    if (mounted) {
      setState(() {
        _hasApiKey = key != null && key.trim().isNotEmpty;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Memeriksa adanya data sensitif (NIK 16 digit, nomor telepon panjang)
  String? _detectSensitiveData(String text) {
    // Deteksi NIK (16 digit angka)
    final nikRegex = RegExp(r'\b\d{16}\b');
    if (nikRegex.hasMatch(text)) {
      return 'NIK (Nomor Induk Kependudukan 16 digit)';
    }

    // Deteksi nomor telepon Indonesia
    final phoneRegex = RegExp(r'\b(\+62|62|08)[0-9]{8,12}\b');
    if (phoneRegex.hasMatch(text)) {
      return 'Nomor telepon pribadi';
    }

    return null;
  }

  Future<void> _sendMessage([String? presetText]) async {
    final rawText = presetText ?? _controller.text;
    final trimmedText = rawText.trim();
    if (trimmedText.isEmpty || _isLoading) return;

    // Peringatan keamanan privasi
    final sensitiveLabel = _detectSensitiveData(trimmedText);
    if (sensitiveLabel != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Peringatan Keamanan: Terdeteksi $sensitiveLabel. Jangan mengirim data sensitif ke AI!',
          ),
        ),
      );
      return;
    }

    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(text: trimmedText, isUser: true));
      // Siapkan bubble placeholder untuk respons asisten
      _messages.add(ChatMessage(text: '', isUser: false, isStreaming: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final stream = _aiService.askStream(trimmedText);
      final aiIndex = _messages.length - 1;
      final buffer = StringBuffer();

      _streamSub?.cancel();
      _streamSub = stream.listen(
        (chunk) {
          buffer.write(chunk);
          if (mounted) {
            setState(() {
              _messages[aiIndex] = _messages[aiIndex].copyWith(
                text: buffer.toString(),
                isStreaming: true,
              );
            });
            _scrollToBottom();
          }
        },
        onError: (error) {
          _handleAiError(error, trimmedText);
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _messages[aiIndex] = _messages[aiIndex].copyWith(
                isStreaming: false,
              );
              _isLoading = false;
            });
            _scrollToBottom();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      _handleAiError(e, trimmedText);
    }
  }

  /// Menangani error API dengan Fallback Dialog dan Mode Offline (Modul Bagian 5)
  void _handleAiError(dynamic error, String originalQuestion) {
    if (!mounted) return;
    final aiIndex = _messages.length - 1;
    setState(() {
      _messages[aiIndex] = _messages[aiIndex].copyWith(
        text: 'Layanan AI sedang tidak tersedia (${error.toString()}).',
        isStreaming: false,
      );
      _isLoading = false;
    });
    _scrollToBottom();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Layanan AI Sibuk'),
        content: const Text('Coba lagi nanti atau gunakan mode offline.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).pop();
              _useOfflineFallback(originalQuestion);
            },
            child: const Text('Gunakan Mode Offline'),
          ),
        ],
      ),
    );
  }

  void _useOfflineFallback(String question) {
    if (!mounted) return;
    final fallbackAnswer = AiService.getFallbackResponse(question);
    final aiIndex = _messages.length - 1;
    setState(() {
      _messages[aiIndex] = _messages[aiIndex].copyWith(
        text: fallbackAnswer,
        isStreaming: false,
      );
    });
    _scrollToBottom();
  }

  Future<void> _showApiKeyDialog() async {
    final currentKey = await _aiService.getApiKey() ?? '';
    final keyController = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.key, color: Colors.blue),
              SizedBox(width: 8),
              Text('Atur Gemini API Key'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kunci API disimpan secara aman di FlutterSecureStorage perangkat Anda dan tidak dibagikan ke server.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API Key (Google AI Studio)',
                  border: OutlineInputBorder(),
                  hintText: 'AIzaSy...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            if (currentKey.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await _aiService.clearApiKey();
                  await _checkApiKey();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API Key telah dihapus.')),
                    );
                  }
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: () async {
                final newKey = keyController.text.trim();
                await _aiService.saveApiKey(newKey);
                await _checkApiKey();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('API Key tersimpan dengan aman!'),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMultimodalSheet() async {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fitur Multimodal AI',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.document_scanner_outlined),
                  ),
                  title: const Text('OCR Dokumen / KTM'),
                  subtitle: const Text(
                    'Ekstraksi teks dari gambar pengumuman atau kartu mahasiswa',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _runOcrDemo();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.mic_outlined)),
                  title: const Text('Speech-to-Text (STT)'),
                  subtitle: const Text(
                    'Konversi suara/audio ke teks bahasa Indonesia',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _runSttDemo();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.image_search_outlined),
                  ),
                  title: const Text('Image Understanding'),
                  subtitle: const Text(
                    'Deskripsi dan analisis konteks gambar fasilitas/kampus',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _runImageUnderstandingDemo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runOcrDemo() async {
    setState(() => _isLoading = true);
    try {
      const mockKtmBytes =
          'data:image/jpeg;base64,U2FtcGxlS1RNRG9jdW1lbnRUZXh0';
      final result = await _aiService.recognizeText(mockKtmBytes);
      _controller.text = result;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OCR Berhasil: Teks disalin ke kolom input.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('OCR Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runSttDemo() async {
    setState(() => _isLoading = true);
    try {
      const mockAudioBytes =
          'data:audio/mp3;base64,U2FtcGxlQXVkaW9TdHJlYW1EYXRh';
      final text = await _aiService.speechToText(mockAudioBytes);
      _controller.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech-to-Text Berhasil: Transkrip disalin ke input.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('STT Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runImageUnderstandingDemo() async {
    setState(() => _isLoading = true);
    try {
      const mockImageBytes =
          'data:image/jpeg;base64,U2FtcGxlQ2FtcHVzSW1hZ2VEYXRh';
      final description = await _aiService.describeImage(mockImageBytes);
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: '[Image Understanding]: $description',
              isUser: false,
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Image Understanding Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus AI Chat'),
        actions: [
          IconButton(
            tooltip: _hasApiKey ? 'Ubah API Key' : 'Atur API Key',
            icon: Icon(
              Icons.vpn_key_rounded,
              color: _hasApiKey ? Colors.green : Colors.amber.shade800,
            ),
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner Keamanan dan Privasi Data
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privasi: Jangan kirim NIK, telepon, atau data sensitif. Gunakan konteks anonim.',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                  if (!_hasApiKey)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _showApiKeyDialog,
                      child: const Text(
                        'Set Key',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // Daftar Pesan Chat
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return ChatMessageBubble(message: msg);
                },
              ),
            ),

            // Indikator Loading Streaming jika aktif
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI sedang menyusun jawaban...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Prompt Suggestions
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _quickPrompts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickPrompts[index];
                  return ActionChip(
                    label: Text(prompt, style: const TextStyle(fontSize: 12)),
                    onPressed: _isLoading ? null : () => _sendMessage(prompt),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    tooltip: 'Fitur Multimodal (OCR, STT, Vision)',
                    onPressed: _isLoading ? null : _showMultimodalSheet,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Ketik pertanyaan seputar kampus...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : () => _sendMessage(),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget bubble chat terpisah yang diisolasi dengan RepaintBoundary (Optimasi Minggu 11)
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return RepaintBoundary(
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: isUser
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isUser ? 14 : 2),
              bottomRight: Radius.circular(isUser ? 2 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person : Icons.smart_toy_outlined,
                    size: 14,
                    color: isUser
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isUser ? 'Anda' : 'Campus Assistant',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUser
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                message.text.isEmpty && message.isStreaming
                    ? '...'
                    : message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
