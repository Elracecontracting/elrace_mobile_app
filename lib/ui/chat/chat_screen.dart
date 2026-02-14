import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../chat/chat.dart';
import '../../chat/services/chat_notification_service.dart';
import '../../resources/app_colors.dart';
import '../../core/utils/shared_pref.dart';
import '../widgets/header_widget.dart';
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
  bool _isRecording = false;
  bool _isMuted = false;
  Timer? _typingTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _markAsRead();
    _loadMuteStatus();
    _messageController.addListener(_onTextChanged);
    
    // Set this chat as active to suppress notifications
    ChatNotificationService.instance.setActiveChatId(widget.chatId);
    // Cancel any pending notifications for this chat
    ChatNotificationService.instance.cancelNotificationsForChat(widget.chatId);
  }

  Future<void> _loadMuteStatus() async {
    final userChat = await ChatRepository.instance.getUserChat(widget.chatId);
    if (mounted && userChat != null) {
      setState(() => _isMuted = userChat.muted);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    PresenceService.instance.setTyping(widget.chatId, false);
    
    // Clear active chat when leaving
    ChatNotificationService.instance.setActiveChatId(null);
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
      backgroundColor: AppColors.primaryColor,
      appBar: const HeaderWidget(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildGlassTopHeader(),
            Expanded(
              child: Container(
                color: const Color(0xFFF2F2F2),
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildChatBackgroundPattern()),
                    _buildMessageList(),
                  ],
                ),
              ),
            ),
            _buildTypingIndicator(),
            ChatInputBar(
              controller: _messageController,
              isLoading: false,
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
      ),
    );
  }

  Widget _buildGlassTopHeader() {
    return Column(
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 0.8,
                  ),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                  SizedBox(width: 6),
                  Text(
                    'Private Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: AppColors.primaryColor,
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.chatType == ChatType.dm && widget.peerUid != null)
                      _buildPresenceStatus(),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: _onMenuAction,
                color: Colors.white,
                icon: const Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mute',
                    child: Row(
                      children: [
                        Icon(_isMuted ? Icons.volume_up : Icons.volume_off),
                        const SizedBox(width: 8),
                        Text(_isMuted ? 'Unmute' : 'Mute'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (widget.chatType == ChatType.dm) {
      return StreamBuilder<PresenceStatus>(
        stream: widget.peerUid != null
            ? PresenceService.instance.subscribeToUserPresence(widget.peerUid!)
            : null,
        builder: (context, snapshot) {
          final isOnline = snapshot.data?.online ?? false;
          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(1.3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE9B23A), width: 1.2),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFECECEC),
                  child: Text(
                    _getInitials(widget.title),
                    style: const TextStyle(
                      color: Color(0xFF2E2E2E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD65B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
    return Container(
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE9B23A), width: 1.2),
      ),
      child: const CircleAvatar(
        radius: 22,
        backgroundImage: AssetImage('assets/logo/rcc2.png'),
      ),
    );
  }

  Widget _buildPresenceStatus() {
    return StreamBuilder<PresenceStatus>(
      stream: PresenceService.instance.subscribeToUserPresence(widget.peerUid!),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null) return const SizedBox.shrink();

        return Text(
          status.online ? 'Active now' : status.lastSeenText,
          style: TextStyle(
            fontSize: 12,
            color: status.online ? const Color(0xFF6BE483) : Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<Message>>(
      stream: ChatRepository.instance.subscribeToMessages(widget.chatId),
      builder: (context, snapshot) {
        // Don't show loading - show empty state immediately for better UX
        // Errors are silently ignored - messages will appear when available
        if (snapshot.hasError) {
          // Log error but don't show to user
          debugPrint('Chat messages error: ${snapshot.error}');
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
                  'No messages yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start the conversation!',
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

  Widget _buildChatBackgroundPattern() {
    final token = _watermarkToken();
    return IgnorePointer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 30,
        itemBuilder: (context, index) {
          return Opacity(
            opacity: index.isEven ? 0.07 : 0.04,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                token,
                maxLines: 1,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFBFC3C9),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _watermarkToken() {
    final loginData = SharedPref.getLoginDataOrNull();
    final empId = loginData?.result?.data?.emp_id;
    if (empId != null && empId.isNotEmpty) return empId;
    // fallback
    final raw = (_currentUid ?? widget.peerUid ?? widget.chatId).trim();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      return digits.length > 4 ? digits.substring(digits.length - 4) : digits;
    }
    if (raw.length <= 4) return raw.toUpperCase();
    return raw.substring(raw.length - 4).toUpperCase();
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
      text = 'Today';
    } else if (date.year == now.year && 
               date.month == now.month && 
               date.day == now.day - 1) {
      text = 'Yesterday';
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
    return StreamBuilder<TypingInfo>(
      stream: PresenceService.instance.subscribeToTypingWithNames(widget.chatId),
      builder: (context, snapshot) {
        // Silently handle errors - typing is not critical
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        
        final typingInfo = snapshot.data;
        
        if (typingInfo == null || !typingInfo.isTyping) {
          return const SizedBox.shrink();
        }

        return TypingIndicatorWidget(
          typingUserNames: typingInfo.typingNames,
          isGroupChat: widget.chatType != ChatType.dm,
        );
      },
    );
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'mute':
        final newMuteState = !_isMuted;
        ChatRepository.instance.toggleMute(widget.chatId, newMuteState);
        setState(() => _isMuted = newMuteState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newMuteState ? 'Chat muted' : 'Chat unmuted')),
        );
        break;
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    PresenceService.instance.setTyping(widget.chatId, false);
    
    // Optimistic UI - scroll immediately, no loading
    _scrollToBottom();

    try {
      await ChatRepository.instance.sendText(widget.chatId, text);
    } catch (e) {
      _showError('Failed to send message');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      // Optimistic UI - scroll immediately
      _scrollToBottom();

      await ChatRepository.instance.sendImage(
        widget.chatId,
        File(image.path),
      );
    } catch (e) {
      _showError('Failed to send image');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      
      // Optimistic UI - scroll immediately
      _scrollToBottom();

      await ChatRepository.instance.sendFile(
        widget.chatId,
        file,
        mimeType: result.files.single.extension,
      );
    } catch (e) {
      _showError('Failed to send file');
    }
  }

  Future<void> _startRecording() async {
    print('🎙️ ChatScreen: _startRecording called');
    
    final permission = await Permission.microphone.request();
    print('🎙️ ChatScreen: Microphone permission: ${permission.isGranted}');
    
    if (!permission.isGranted) {
      _showError('Please allow microphone permission');
      return;
    }

    final started = await VoiceRecorderService.instance.startRecording();
    print('🎙️ ChatScreen: Recording started: $started');
    
    if (started) {
      setState(() => _isRecording = true);
    } else {
      _showError('Failed to start recording');
    }
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    
    final result = await VoiceRecorderService.instance.stopRecording();
    
    if (result == null) {
      _showError('Failed to save recording');
      return;
    }

    if (result.isTooShort) {
      _showError('Recording too short');
      return;
    }

    if (result.file != null) {
      // Optimistic UI - scroll immediately
      _scrollToBottom();
      
      try {
        await ChatRepository.instance.sendVoice(
          widget.chatId,
          result.file!,
          durationMs: result.durationMs,
        );
      } catch (e) {
        _showError('Failed to send voice message');
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
