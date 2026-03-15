import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:math';

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
import 'chat_user_profile_screen.dart';
import 'chat_group_profile_screen.dart';
import 'screens/sign_zone_picker_screen.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/typing_indicator.dart';

/// Chat screen for viewing and sending messages
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final ChatType chatType;
  final String? peerUid;
  final String? supportUserUid; // For support chats: the external user's UID
  final String? supportGroupTitle; // For support chats: the group title (e.g. "HR")

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    required this.chatType,
    this.peerUid,
    this.supportUserUid,
    this.supportGroupTitle,
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

  /// Peer user info (cached for avatar)
  ChatUser? _peerUser;

  /// Messages stream — recreatable if the chat doc is created after first open
  late Stream<List<Message>> _messagesStream;

  /// Whether the stream has had an error (needs reconnect after first send)
  bool _streamErrored = false;

  /// Support chat state
  bool get _isSupportChat => widget.chatType == ChatType.support;
  bool get _isExternalUser => _isSupportChat && widget.supportUserUid == _currentUid;
  
  /// Cache of member names for support chat (uid -> name)
  final Map<String, String> _memberNames = {};

  /// Starred message IDs (live from Firestore)
  Set<String> _starredIds = {};
  StreamSubscription? _starredSub;

  /// Reply state (WhatsApp-style)
  Message? _replyingTo;

  /// Optimistic (pending) messages — shown with clock icon until Firestore confirms
  final List<Message> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _messagesStream = ChatRepository.instance.subscribeToMessages(widget.chatId);
    _markAsRead();
    _loadPeerUser();
    _messageController.addListener(_onTextChanged);

    // Set this chat as active to suppress notifications
    ChatNotificationService.instance.setActiveChatId(widget.chatId);
    // Cancel any pending notifications for this chat
    ChatNotificationService.instance.cancelNotificationsForChat(widget.chatId);

    // Defer non-critical loads so messages render first
    Future.microtask(() {
      if (!mounted) return;
      _loadMuteStatus();

      // Load member names for support chats (group members see real names)
      if (_isSupportChat && !_isExternalUser) {
        _loadSupportChatMemberNames();
      }

      // Subscribe to starred message IDs
      _starredSub =
          ChatRepository.instance.subscribeToStarredMessageIds().listen((ids) {
        if (mounted) setState(() => _starredIds = ids);
      });
    });
  }

  Future<void> _loadMuteStatus() async {
    final userChat = await ChatRepository.instance.getUserChat(widget.chatId);
    if (mounted && userChat != null) {
      setState(() => _isMuted = userChat.muted);
    }
  }

  /// Pre-load peer user for fast avatar rendering
  Future<void> _loadPeerUser() async {
    if (widget.peerUid == null) return;
    final user = await UserRepository.instance.getUser(widget.peerUid!);
    if (mounted && user != null) {
      setState(() => _peerUser = user);
    }
  }

  /// Load member names for support chat so group members see who sent what
  Future<void> _loadSupportChatMemberNames() async {
    try {
      final members = await ChatRepository.instance.getChatMembers(widget.chatId);
      final uids = members.map((m) => m.uid).toList();
      final users = await UserRepository.instance.getUsersByIds(uids);
      if (mounted) {
        setState(() {
          for (final user in users) {
            _memberNames[user.uid] = user.name;
          }
        });
      }
    } catch (e) {
      print('⚠️ ChatScreen: Error loading support chat member names: $e');
    }
  }

  /// Get display name for a sender in support chat
  String _getSupportSenderName(String senderId) {
    if (_isExternalUser) {
      // External user: all non-self messages show group name
      if (senderId == _currentUid) return 'You';
      return widget.supportGroupTitle ?? widget.title;
    } else {
      // Group member: show real names
      if (senderId == _currentUid) return 'You';
      if (senderId == widget.supportUserUid) {
        return widget.title; // The external user's name
      }
      return _memberNames[senderId] ?? 'Team member';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _starredSub?.cancel();
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
        child: ChatIdProvider(
          chatId: widget.chatId,
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
              _buildReplyBar(),
              ChatInputBar(
                controller: _messageController,
                isLoading: false,
                isRecording: _isRecording,
                onSendText: _sendTextMessage,
                onPickImage: _pickImage,
                onPickGallery: _pickImagesFromGallery,
                onPickFile: _pickFile,
                onPickSignableDoc: _pickSignableDocument,
              onStartRecording: _startRecording,
              onStopRecording: _stopRecording,
              onCancelRecording: _cancelRecording,
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildGlassTopHeader() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap:
                      (widget.chatType == ChatType.dm && widget.peerUid != null)
                          ? _openPeerProfile
                          : _openGroupProfile,
                  behavior: HitTestBehavior.opaque,
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
                            if (widget.chatType == ChatType.dm &&
                                widget.peerUid != null)
                              _buildPresenceStatus(),
                            if (_isSupportChat)
                              Text(
                                _isExternalUser
                                    ? 'Department Support'
                                    : 'Support Chat • ${widget.supportGroupTitle ?? ""}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          final avatarUrl = _peerUser?.avatarUrl;
          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(1.3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFE9B23A), width: 1.2),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFECECEC),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          _getInitials(widget.title),
                          style: const TextStyle(
                            color: Color(0xFF2E2E2E),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
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
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('📨 StreamBuilder: ERROR — ${snapshot.error}');
          _streamErrored = true;
        }

        final bool isWaiting = snapshot.connectionState == ConnectionState.waiting;
        final bool hasPending = _pendingMessages.isNotEmpty;

        // Log every rebuild so we can trace
        debugPrint('📨 StreamBuilder rebuild: state=${snapshot.connectionState}, '
            'firestoreCount=${snapshot.data?.length ?? 0}, '
            'pendingCount=${_pendingMessages.length}, '
            'hasError=${snapshot.hasError}');

        // Show loading ONLY if no Firestore data yet AND no pending messages
        if (isWaiting && !hasPending) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF1D2449),
              ),
            ),
          );
        }

        // Merge Firestore messages with optimistic pending messages.
        final firestoreMessages = snapshot.data ?? [];
        _deduplicatePendingMessages(firestoreMessages);
        final messages = [
          ..._pendingMessages,
          ...firestoreMessages,
        ];

        debugPrint('📨 StreamBuilder: merged total=${messages.length} '
            '(${_pendingMessages.length} pending + ${firestoreMessages.length} firestore)');

        // Only show empty state AFTER we got real data (not while loading)
        if (messages.isEmpty && !isWaiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 60, color: Colors.grey[400]),
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

        if (messages.isEmpty) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF1D2449),
              ),
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

            // For support chats, determine sender display name
            String? senderDisplayName;
            if (_isSupportChat && !isMe) {
              senderDisplayName = _getSupportSenderName(message.senderId);
            }

            return Column(
              children: [
                if (showDateHeader) _buildDateHeader(message.createdAt),
                MessageBubble(
                  message: message,
                  isMe: isMe,
                  isStarred: _starredIds.contains(message.id),
                  senderName: senderDisplayName,
                  showSenderName: _isSupportChat && !isMe,
                  onStar: _onStarMessage,
                  onReply: _onReplyMessage,
                  onForward: _onForwardMessage,
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

    final current = messages[index].createdAt.toLocal();
    final previous = messages[index + 1].createdAt.toLocal();

    return current.day != previous.day ||
        current.month != previous.month ||
        current.year != previous.year;
  }

  Widget _buildDateHeader(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    String text;

    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      text = 'Today';
    } else if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day - 1) {
      text = 'Yesterday';
    } else {
      text = '${local.day}/${local.month}/${local.year}';
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
      stream:
          PresenceService.instance.subscribeToTypingWithNames(widget.chatId),
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

  /// WhatsApp-style reply preview bar above input
  Widget _buildReplyBar() {
    if (_replyingTo == null) return const SizedBox.shrink();

    final message = _replyingTo!;
    final preview = message.getPreviewText();
    final isMyMessage = message.senderId == _currentUid;

    // Determine display name for the reply header
    String replyToName;
    if (isMyMessage) {
      replyToName = 'You';
    } else if (_isSupportChat) {
      replyToName = _getSupportSenderName(message.senderId);
    } else {
      replyToName = widget.title;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFDCE6E5).withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: isMyMessage
                  ? const Color(0xFF1D2449)
                  : const Color(0xFF2DD65B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  replyToName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isMyMessage
                        ? const Color(0xFF1D2449)
                        : const Color(0xFF2DD65B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _replyingTo = null),
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF8E8E93)),
            splashRadius: 20,
          ),
        ],
      ),
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

  /// Remove pending messages that already appeared in Firestore (dedup).
  /// Called from the StreamBuilder builder so duplicates are never shown.
  void _deduplicatePendingMessages(List<Message> firestoreMessages) {
    if (_pendingMessages.isEmpty || firestoreMessages.isEmpty) return;
    _pendingMessages.removeWhere((pending) {
      return firestoreMessages.any((fm) {
        if (fm.senderId != pending.senderId || fm.type != pending.type) return false;
        // For signable docs, match on clientMsgId (shared between optimistic + real msg)
        if (pending.type == MessageType.signableDoc) {
          if (pending.clientMsgId.isNotEmpty && fm.clientMsgId.isNotEmpty) {
            return fm.clientMsgId == pending.clientMsgId;
          }
          return false; // Don't dedup if no clientMsgId
        }
        return fm.text == pending.text;
      });
    });
  }

  /// Reconnect the messages stream if it previously errored
  /// (e.g. chat doc didn't exist yet, now created by _ensureDmChatExists).
  void _reconnectStreamIfNeeded() {
    if (_streamErrored && mounted) {
      _streamErrored = false;
      setState(() {
        _messagesStream = ChatRepository.instance.subscribeToMessages(widget.chatId);
      });
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Capture reply state before clearing
    final replyTo = _replyingTo != null
        ? ReplyTo(
            messageId: _replyingTo!.id,
            senderId: _replyingTo!.senderId,
            text: _replyingTo!.getPreviewText(),
            type: _replyingTo!.type.toJson(),
          )
        : null;

    _messageController.clear();
    setState(() => _replyingTo = null);
    PresenceService.instance.setTyping(widget.chatId, false);

    // Create optimistic message with 'sending' status (shows clock icon)
    final optimistic = Message(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _currentUid ?? '',
      type: MessageType.text,
      text: text,
      createdAt: DateTime.now(),
      clientMsgId: '',
      replyTo: replyTo,
      status: MessageStatus.sending,
    );

    setState(() {
      _pendingMessages.insert(0, optimistic);
    });
    _scrollToBottom();

    try {
      await ChatRepository.instance
          .sendText(widget.chatId, text, replyTo: replyTo);
      // Don't remove optimistic here — the StreamBuilder merge
      // will auto-deduplicate once the Firestore snapshot arrives.
      _reconnectStreamIfNeeded();
    } catch (e) {
      // Mark as failed so user sees error icon
      if (mounted) {
        setState(() {
          final idx = _pendingMessages.indexWhere((m) => m.id == optimistic.id);
          if (idx >= 0) {
            _pendingMessages[idx] = optimistic.copyWith(status: MessageStatus.failed);
          }
        });
      }
      _showError('Failed to send message');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (image == null) return;

      // Optimistic UI - scroll immediately
      _scrollToBottom();

      await ChatRepository.instance.sendImage(
        widget.chatId,
        File(image.path),
      );
      _reconnectStreamIfNeeded();
    } catch (e) {
      _showError('Failed to send image');
    }
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );

      if (images.isEmpty) return;

      _scrollToBottom();

      for (final image in images) {
        await ChatRepository.instance.sendImage(
          widget.chatId,
          File(image.path),
        );
      }
      _reconnectStreamIfNeeded();
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
      _reconnectStreamIfNeeded();
    } catch (e) {
      _showError('Failed to send file');
    }
  }

  Future<void> _pickSignableDocument() async {
    try {
      // Pick PDF file only
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // Navigate to sign zone picker
      if (!mounted) return;
      final pickerResult = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => SignZonePickerScreen(
            pdfFile: file,
            fileName: fileName,
          ),
        ),
      );

      if (pickerResult == null) {
        debugPrint('📝 SignableDoc: User cancelled sign zone picker');
        return;
      }

      debugPrint('📝 SignableDoc: Got picker result, creating optimistic message...');
      final signZones = pickerResult['signZones'] as List<SignZone>;
      final pageCount = pickerResult['pageCount'] as int?;
      final fileSize = await file.length();

      // Generate a shared clientMsgId for both optimistic + real message (used for dedup)
      final sharedClientMsgId = 'sig_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';

      // Create optimistic message with 'sending' status (shows upload indicator)
      final optimistic = Message(
        id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _currentUid ?? '',
        type: MessageType.signableDoc,
        text: null,
        fileName: fileName,
        fileSize: fileSize,
        signZones: signZones,
        signStatus: SignStatus.pending,
        signExpiresInDays: 2,
        pageCount: pageCount,
        createdAt: DateTime.now(),
        clientMsgId: sharedClientMsgId,
        status: MessageStatus.sending,
        isUploading: true,
      );

      setState(() {
        _pendingMessages.insert(0, optimistic);
      });
      debugPrint('📝 SignableDoc: ✅ Optimistic message added! '
          'pendingMessages=${_pendingMessages.length}, '
          'fileName=$fileName, senderId=${_currentUid}');

      // Use post-frame callback to ensure scroll happens after layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      try {
        debugPrint('📝 SignableDoc: Starting upload...');
        // Send signable document (uploads PDF + writes to Firestore)
        await ChatRepository.instance.sendSignableDocument(
          widget.chatId,
          file,
          signZones: signZones,
          pageCount: pageCount,
          clientMsgId: sharedClientMsgId,
        );
        debugPrint('📝 SignableDoc: ✅ Upload + Firestore write complete!');
        _reconnectStreamIfNeeded();
      } catch (e) {
        debugPrint('📝 SignableDoc: ❌ Upload failed: $e');
        // Mark as failed so user sees error icon
        if (mounted) {
          setState(() {
            final idx = _pendingMessages.indexWhere((m) => m.id == optimistic.id);
            if (idx >= 0) {
              _pendingMessages[idx] = optimistic.copyWith(
                status: MessageStatus.failed,
                isUploading: false,
              );
            }
          });
        }
        _showError('Failed to send document');
      }
    } catch (e) {
      _showError('Failed to pick document');
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

  // ── Message long-press actions ──

  void _onStarMessage(Message message) {
    final isCurrentlyStarred = _starredIds.contains(message.id);
    if (isCurrentlyStarred) {
      ChatRepository.instance.unstarMessage(message.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message unstarred'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ChatRepository.instance.starMessage(widget.chatId, message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message starred'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _onReplyMessage(Message message) {
    setState(() => _replyingTo = message);
    // Focus the text field
    // Delay slightly to ensure the reply bar is rendered first
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _onForwardMessage(Message message) {
    // Show a bottom sheet to pick a chat to forward to
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const Text(
                  'Forward to...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<UserChat>>(
                  stream: ChatRepository.instance
                      .subscribeToUserChats(_currentUid!),
                  builder: (ctx, snap) {
                    final chats = snap.data ?? [];
                    if (chats.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No chats available'),
                      );
                    }
                    return SizedBox(
                      height: 280,
                      child: ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (_, i) {
                          final chat = chats[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFECECEC),
                              child: Text(
                                _getInitials(chat.title ?? '?'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E2E2E),
                                ),
                              ),
                            ),
                            title: Text(
                              chat.title ?? 'Chat',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onTap: () async {
                              Navigator.pop(sheetCtx);
                              try {
                                final text = message.getPreviewText();
                                await ChatRepository.instance.sendText(
                                  chat.chatId,
                                  text,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Message forwarded'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted)
                                  _showError('Failed to forward message');
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPeerProfile() {
    final peerUid = widget.peerUid;
    if (peerUid == null || widget.chatType != ChatType.dm) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatUserProfileScreen(
          chatId: widget.chatId,
          peerUid: peerUid,
          fallbackName: widget.title,
        ),
      ),
    );
  }

  void _openGroupProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatGroupProfileScreen(
          chatId: widget.chatId,
          title: widget.title,
          chatType: widget.chatType,
          supportGroupTitle: widget.supportGroupTitle,
        ),
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
