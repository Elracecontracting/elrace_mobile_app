import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../chat/chat.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

/// Main chat list screen showing all user's conversations
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String? _currentUid;
  bool _isChatAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _isChatAvailable = ChatModuleHelper.instance.isChatEnabled;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isChatAvailable || _currentUid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('المحادثات'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'الدردشة غير متاحة',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يرجى تسجيل الدخول مرة أخرى',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: StreamBuilder<List<UserChat>>(
        stream: ChatRepository.instance.subscribeToUserChats(_currentUid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('حدث خطأ: ${snapshot.error}'),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد محادثات',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ محادثة جديدة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final userChat = chats[index];
              return _ChatListTile(
                userChat: userChat,
                currentUid: _currentUid!,
                onTap: () => _openChat(userChat),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewChat,
        child: const Icon(Icons.message),
      ),
    );
  }

  void _openChat(UserChat userChat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: userChat.chatId,
          title: userChat.title ?? 'محادثة',
          chatType: userChat.type,
          peerUid: userChat.peerUid,
        ),
      ),
    );
  }

  void _startNewChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewChatScreen(),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewChatScreen(),
      ),
    );
  }
}

/// Chat list tile widget
class _ChatListTile extends StatelessWidget {
  final UserChat userChat;
  final String currentUid;
  final VoidCallback onTap;

  const _ChatListTile({
    required this.userChat,
    required this.currentUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Chat?>(
      stream: ChatRepository.instance.subscribeToChat(userChat.chatId),
      builder: (context, chatSnapshot) {
        final chat = chatSnapshot.data;
        final lastMessage = chat?.lastMessage;

        return ListTile(
          leading: _buildAvatar(),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  userChat.title ?? 'محادثة',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (lastMessage != null)
                Text(
                  _formatTime(lastMessage.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: _buildLastMessage(lastMessage),
              ),
              if (userChat.muted)
                Icon(Icons.volume_off, size: 16, color: Colors.grey[400]),
              if (userChat.pinned)
                Icon(Icons.push_pin, size: 16, color: Colors.grey[400]),
            ],
          ),
          onTap: onTap,
        );
      },
    );
  }

  Widget _buildAvatar() {
    if (userChat.type == ChatType.dm && userChat.peerUid != null) {
      return StreamBuilder<PresenceStatus>(
        stream: PresenceService.instance.subscribeToUserPresence(userChat.peerUid!),
        builder: (context, snapshot) {
          final isOnline = snapshot.data?.online ?? false;
          return Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue[100],
                child: Text(
                  _getInitials(userChat.title ?? '?'),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    // Group chat avatar
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.purple[100],
      child: Icon(Icons.group, color: Colors.purple[700]),
    );
  }

  Widget _buildLastMessage(LastMessage? lastMessage) {
    if (lastMessage == null) {
      return Text(
        'لا توجد رسائل',
        style: TextStyle(color: Colors.grey[500]),
      );
    }

    String text;
    IconData? icon;

    switch (lastMessage.type) {
      case 'image':
        text = '📷 صورة';
        break;
      case 'file':
        text = '📎 ملف';
        break;
      case 'audio':
        text = '🎵 رسالة صوتية';
        break;
      case 'video':
        text = '🎬 فيديو';
        break;
      default:
        text = lastMessage.text;
    }

    return Text(
      text,
      style: TextStyle(color: Colors.grey[600]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return '${diff.inMinutes}د';
    if (diff.inDays < 1) return '${diff.inHours}س';
    if (diff.inDays < 7) return '${diff.inDays}ي';

    return '${dateTime.day}/${dateTime.month}';
  }
}
