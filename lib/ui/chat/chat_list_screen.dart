import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../chat/chat.dart';
import '../../resources/app_colors.dart';
import '../widgets/header_widget.dart';
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

    // Show loading indicator while initializing chat
    if (_isInitializing) {
      return Scaffold(
        appBar: const HeaderWidget(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_isChatAvailable || _currentUid == null) {
      return Scaffold(
        appBar: const HeaderWidget(),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  ChatModuleHelper.instance.getStatusMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
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
              const SizedBox(height: 12),
              // Show logout button if error mentions session expired
              if (ChatModuleHelper.instance.getStatusMessage().contains('expired') ||
                  ChatModuleHelper.instance.getStatusMessage().contains('login again'))
                TextButton.icon(
                  onPressed: () {
                    // Navigate to logout or login screen
                    Navigator.of(context).pushReplacementNamed('/signIN');
                  },
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Logout & Login Again'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: const HeaderWidget(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Fixed secondary bar (Chats + Massages)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: _SecondaryChatBar(onMessagesTap: _startNewChat),
            ),
            // Everything else scrolls together
            Expanded(
              child: StreamBuilder<List<UserChat>>(
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
                          Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Error: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allChats = snapshot.data ?? [];

                  final groups = allChats
                      .where((c) => c.type == ChatType.role || c.type == ChatType.group)
                      .toList();

                  final filteredChats = _localSearchQuery.isEmpty
                      ? allChats
                      : allChats
                          .where((c) => (c.title ?? '').toLowerCase().contains(_localSearchQuery))
                          .toList();

                  return CustomScrollView(
                    slivers: [
                      // Search bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: _ChatSearchBar(
                            controller: _localSearchController,
                            onOpenGlobalSearch: _openSearch,
                          ),
                        ),
                      ),
                      // Groups header + horizontal list
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Row(
                            children: const [
                              Text(
                                'Groups',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 82,
                          child: groups.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No groups yet',
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 16),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: groups.length,
                                  itemBuilder: (context, i) {
                                    final g = groups[i];
                                    return _GroupQuickItem(
                                      label: g.title ?? 'Group',
                                      onTap: () => _openChat(g),
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 14)),
                      // White card header (drag handle)
                      SliverToBoxAdapter(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                          ),
                          padding: const EdgeInsets.only(top: 9, bottom: 8),
                          alignment: Alignment.center,
                          child: Container(
                            width: 70,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      // Chat list items
                      if (filteredChats.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Container(
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    allChats.isEmpty ? 'No chats yet' : 'No results',
                                    style: TextStyle(fontSize: 17, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final userChat = filteredChats[index];
                              return Container(
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: _ChatListTile(
                                  userChat: userChat,
                                  currentUid: _currentUid!,
                                  onTap: () => _openChat(userChat),
                                ),
                              );
                            },
                            childCount: filteredChats.length,
                          ),
                        ),
                      // Fill remaining space with white
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Container(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userChat.title ?? 'Chat',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF171717),
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          DefaultTextStyle.merge(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8B8B8B),
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                            child: isTyping
                                ? TypingTextWidget(
                                    typingUserNames: typingInfo!.typingNames,
                                    isGroupChat: userChat.type != ChatType.dm,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF20B051),
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : _buildLastMessage(lastMessage),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    StreamBuilder<int>(
                      stream: ChatRepository.instance.subscribeToUnreadCount(userChat.chatId),
                      builder: (context, unreadSnap) {
                        final unreadCount = unreadSnap.data ?? 0;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              lastMessage != null ? _formatTime(lastMessage.createdAt) : '',
                              style: TextStyle(
                                color: unreadCount > 0
                                    ? const Color(0xFF8C8C8C)
                                    : const Color(0xFFAAAAAA),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (unreadCount > 0)
                              Container(
                                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF04D57),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 22),
                          ],
                        );
                      },
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
          return _avatarShell(
            isOnline: isOnline,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFECECEC),
              child: Text(
                _getInitials(userChat.title ?? '?'),
                style: const TextStyle(
                  color: Color(0xFF2E2E2E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      );
    }

    return _avatarShell(
      isOnline: true,
      child: const CircleAvatar(
        radius: 24,
        backgroundImage: AssetImage('assets/logo/rcc2.png'),
      ),
    );
  }

  Widget _avatarShell({required Widget child, required bool isOnline}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(1.3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE9B23A), width: 1.2),
          ),
          child: child,
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

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes == 1) return '1 min ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours == 1) return '1 hour ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: const TextStyle(
          color: Color(0xFF9A9A9A),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const SizedBox.shrink(),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: IconButton(
          tooltip: 'Search users',
          onPressed: onOpenGlobalSearch,
          icon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E8E)),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      ),
      style: const TextStyle(
        color: Color(0xFF1F1F1F),
        fontWeight: FontWeight.w500,
      ),
      textInputAction: TextInputAction.search,
    );
  }
}

class _SecondaryChatBar extends StatelessWidget {
  final VoidCallback onMessagesTap;

  const _SecondaryChatBar({required this.onMessagesTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
          const SizedBox(width: 8),
          Text(
            'Chats',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onMessagesTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF4C542),
              side: const BorderSide(color: Color(0xFFF4C542), width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.star, size: 16),
            label: const Text(
              'Massages',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupQuickItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _GroupQuickItem({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(1.3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE9B23A), width: 1.2),
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/logo/rcc2.png'),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}