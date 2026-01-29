import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../chat/chat.dart';
import '../../resources/app_colors.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'widgets/typing_indicator.dart';

/// Main chat list screen showing all user's conversations
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String? _currentUid;
  bool _isChatAvailable = false;
  bool _isInitializing = false;

  final TextEditingController _localSearchController = TextEditingController();
  String _localSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeChat();

    _localSearchController.addListener(() {
      final q = _localSearchController.text.trim().toLowerCase();
      if (q == _localSearchQuery) return;
      setState(() => _localSearchQuery = q);
    });
  }

  @override
  void dispose() {
    _localSearchController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _isChatAvailable = ChatModuleHelper.instance.isChatEnabled;
    
    // If chat is not available but user is authenticated, try to restore session
    if (!_isChatAvailable && !_isInitializing) {
      setState(() => _isInitializing = true);
      
      try {
        print('🔷 ChatListScreen: Chat not available, attempting to restore session...');
        final result = await ChatModuleHelper.instance.restoreFromStoredSession();
        
        if (result != null && result.chatEnabled) {
          _currentUid = FirebaseAuth.instance.currentUser?.uid;
          _isChatAvailable = true;
          print('✅ ChatListScreen: Chat session restored successfully');
        } else {
          print('⚠️ ChatListScreen: Failed to restore chat session: ${result?.error}');
        }
      } catch (e) {
        print('❌ ChatListScreen: Error restoring chat session: $e');
      } finally {
        if (mounted) {
          setState(() => _isInitializing = false);
        }
      }
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading indicator while initializing chat
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_isChatAvailable || _currentUid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
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
                'Chat not available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to initialize chat service',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initializeChat,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0.5,
        scrolledUnderElevation: 0.6,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Text(
          'Chats',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _startNewChat,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _ChatSearchBar(
              controller: _localSearchController,
              onOpenGlobalSearch: _openSearch,
            ),
          ),
        ),
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
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];

          final filteredChats = _localSearchQuery.isEmpty
              ? chats
              : chats
                  .where((c) => (c.title ?? '').toLowerCase().contains(_localSearchQuery))
                  .toList();

          if (filteredChats.isEmpty) {
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
                    chats.isEmpty ? 'No chats yet' : 'No results',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chats.isEmpty
                        ? 'Start a new conversation'
                        : 'Try a different search term',
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
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: filteredChats.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 88,
              endIndent: 16,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final userChat = filteredChats[index];
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
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
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
          title: userChat.title ?? 'Chat',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<Chat?>(
      stream: ChatRepository.instance.subscribeToChat(userChat.chatId),
      builder: (context, chatSnapshot) {
        final chat = chatSnapshot.data;
        final lastMessage = chat?.lastMessage;

        final hasUnread = userChat.hasUnread(lastMessage?.createdAt);

        return StreamBuilder<TypingInfo>(
          stream: PresenceService.instance.subscribeToTypingWithNames(userChat.chatId),
          builder: (context, typingSnapshot) {
            final typingInfo = typingSnapshot.data;
            final isTyping = typingInfo?.isTyping ?? false;

            return InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  userChat.title ?? 'Chat',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (lastMessage != null)
                                Text(
                                  _formatTime(lastMessage.createdAt),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: hasUnread
                                        ? AppColors.primaryColor
                                        : colorScheme.onSurfaceVariant,
                                    fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: isTyping
                                    ? TypingTextWidget(
                                        typingUserNames: typingInfo!.typingNames,
                                        isGroupChat: userChat.type != ChatType.dm,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF25D366),
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : DefaultTextStyle.merge(
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                        child: _buildLastMessage(lastMessage),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              if (userChat.muted)
                                Icon(Icons.volume_off, size: 16, color: colorScheme.onSurfaceVariant),
                              if (userChat.pinned)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(Icons.push_pin, size: 16, color: colorScheme.onSurfaceVariant),
                                ),
                              if (hasUnread)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF25D366),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
                backgroundColor: AppColors.primaryBlackLight,
                child: Text(
                  _getInitials(userChat.title ?? '?'),
                  style: const TextStyle(
                    color: AppColors.primaryColor,
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
      backgroundColor: AppColors.primaryBlackLight,
      child: const Icon(Icons.group, color: AppColors.primaryColor),
    );
  }

  Widget _buildLastMessage(LastMessage? lastMessage) {
    if (lastMessage == null) {
      return const Text(
        'No messages',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    String text;
    IconData? icon;

    switch (lastMessage.type) {
      case 'image':
        text = '📷 Photo';
        break;
      case 'file':
        text = '📎 File';
        break;
      case 'audio':
        text = '🎵 Voice message';
        break;
      case 'video':
        text = '🎬 Video';
        break;
      default:
        text = lastMessage.text;
    }

    return Text(
      text,
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

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${dateTime.day}/${dateTime.month}';
  }
}

class _ChatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onOpenGlobalSearch;

  const _ChatSearchBar({
    required this.controller,
    required this.onOpenGlobalSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search chats',
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        suffixIcon: IconButton(
          tooltip: 'Search users',
          onPressed: onOpenGlobalSearch,
          icon: Icon(Icons.person_search, color: colorScheme.onSurfaceVariant),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: theme.textTheme.bodyMedium,
      textInputAction: TextInputAction.search,
    );
  }
}
