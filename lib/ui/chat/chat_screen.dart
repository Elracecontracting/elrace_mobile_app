import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../chat/chat.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/typing_indicator.dart';

/// Chat screen for viewing and sending messages
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final ChatType chatType;
  final String? peerUid;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.chatType,
    this.peerUid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _currentUid;
  bool _isLoading = false;
  bool _isRecording = false;
  Timer? _typingTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _markAsRead();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    PresenceService.instance.setTyping(widget.chatId, false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markAsRead();
    }
  }

  void _markAsRead() {
    ChatRepository.instance.markChatRead(widget.chatId);
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty) {
      PresenceService.instance.setTyping(widget.chatId, true);
      
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        PresenceService.instance.setTyping(widget.chatId, false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          ChatInputBar(
            controller: _messageController,
            isLoading: _isLoading,
            isRecording: _isRecording,
            onSendText: _sendTextMessage,
            onPickImage: _pickImage,
            onPickFile: _pickFile,
            onStartRecording: _startRecording,
            onStopRecording: _stopRecording,
            onCancelRecording: _cancelRecording,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 16),
                ),
                if (widget.chatType == ChatType.dm && widget.peerUid != null)
                  _buildPresenceStatus(),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: _onMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.volume_off),
                  SizedBox(width: 8),
                  Text('كتم'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('معلومات'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (widget.chatType == ChatType.dm) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.blue[100],
        child: Text(
          _getInitials(widget.title),
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.purple[100],
      child: Icon(Icons.group, color: Colors.purple[700], size: 20),
    );
  }

  Widget _buildPresenceStatus() {
    return StreamBuilder<PresenceStatus>(
      stream: PresenceService.instance.subscribeToUserPresence(widget.peerUid!),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null) return const SizedBox.shrink();

        return Text(
          status.online ? 'متصل' : status.lastSeenText,
          style: TextStyle(
            fontSize: 12,
            color: status.online ? Colors.green : Colors.grey[400],
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Message>>(
      stream: ChatRepository.instance.subscribeToMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ: ${snapshot.error}'),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'لا توجد رسائل',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'ابدأ المحادثة الآن!',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUid;
            
            // Check if we should show date header
            final showDateHeader = _shouldShowDateHeader(messages, index);

            return Column(
              children: [
                if (showDateHeader)
                  _buildDateHeader(message.createdAt),
                MessageBubble(
                  message: message,
                  isMe: isMe,
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowDateHeader(List<Message> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final current = messages[index].createdAt;
    final previous = messages[index + 1].createdAt;
    
    return current.day != previous.day ||
           current.month != previous.month ||
           current.year != previous.year;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String text;

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      text = 'اليوم';
    } else if (date.year == now.year && 
               date.month == now.month && 
               date.day == now.day - 1) {
      text = 'أمس';
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<Set<String>>(
      stream: PresenceService.instance.subscribeToTyping(widget.chatId),
      builder: (context, snapshot) {
        final typingUsers = snapshot.data ?? {};
        
        if (typingUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        return const TypingIndicatorWidget();
      },
    );
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'mute':
        ChatRepository.instance.toggleMute(widget.chatId, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم كتم المحادثة')),
        );
        break;
      case 'info':
        // TODO: Show chat info
        break;
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    PresenceService.instance.setTyping(widget.chatId, false);
    
    setState(() => _isLoading = true);

    try {
      await ChatRepository.instance.sendText(widget.chatId, text);
      _scrollToBottom();
    } catch (e) {
      _showError('فشل إرسال الرسالة');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      await ChatRepository.instance.sendImage(
        widget.chatId,
        File(image.path),
      );
      
      _scrollToBottom();
    } catch (e) {
      _showError('فشل إرسال الصورة');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      
      setState(() => _isLoading = true);

      await ChatRepository.instance.sendFile(
        widget.chatId,
        file,
        mimeType: result.files.single.extension,
      );
      
      _scrollToBottom();
    } catch (e) {
      _showError('فشل إرسال الملف');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startRecording() async {
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      _showError('يرجى السماح بإذن الميكروفون');
      return;
    }

    final started = await VoiceRecorderService.instance.startRecording();
    if (started) {
      setState(() => _isRecording = true);
    } else {
      _showError('فشل بدء التسجيل');
    }
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    
    final result = await VoiceRecorderService.instance.stopRecording();
    
    if (result == null) {
      _showError('فشل حفظ التسجيل');
      return;
    }

    if (result.isTooShort) {
      _showError('التسجيل قصير جداً');
      return;
    }

    if (result.file != null) {
      setState(() => _isLoading = true);
      
      try {
        await ChatRepository.instance.sendVoice(
          widget.chatId,
          result.file!,
          durationMs: result.durationMs,
        );
        _scrollToBottom();
      } catch (e) {
        _showError('فشل إرسال الرسالة الصوتية');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelRecording() async {
    await VoiceRecorderService.instance.cancelRecording();
    setState(() => _isRecording = false);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
