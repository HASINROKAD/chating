import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/modules/chat/views/chat_view.dart';
import 'package:frontend/services/auth_service.dart';

class DirectMessages extends StatefulWidget {
  const DirectMessages({super.key});

  @override
  State<DirectMessages> createState() => _DirectMessagesState();
}

class _DirectMessagesState extends State<DirectMessages> {
  final ChatService _chatService = ChatPlugin.chatService;

  bool _isLoading = true;
  final Map<String, int> _newMessageCount = {};

  @override
  void initState() {
    super.initState();

    _chatService.addEventListener(
      ChatEventType.chatRoomsChanged,
      'direct_message_page',
      (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );

    _chatService.addEventListener(
      ChatEventType.custom,
      'direct_message_page_notification',
      (data) {
        if (data["eventName"] == 'new_message_notification') {
          _handleNewMessageNotification(data['data']);
        }
      },
    );

    _initChatService();
  }

  @override
  void dispose() {
    _chatService.removeEventListener(
      ChatEventType.chatRoomsChanged,
      'direct_message_page',
    );
    _chatService.removeEventListener(
      ChatEventType.custom,
      'direct_message_page_notification',
    );
    super.dispose();
  }

  void _handleNewMessageNotification(Map<String, dynamic> messageData) {
    if (!mounted) return;

    final senderId = messageData['sender'] ?? messageData['senderId'];

    if (senderId != null) {
      setState(() {
        _newMessageCount[senderId] = (_newMessageCount[senderId] ?? 0) + 1;
      });
    }
  }

  String? _resolveUserId(dynamic user) {
    if (user is! Map) return null;

    final dynamic id = user['id'] ?? user['_id'] ?? user['userId'];
    if (id == null) return null;

    return id.toString();
  }

  Widget _buildAvatar(String username, String? avatarUrl) {
    final String initial = username.isNotEmpty
        ? username[0].toUpperCase()
        : '?';

    if (avatarUrl == null || avatarUrl.isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: Text(initial),
      );
    }

    return CircleAvatar(
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Text(initial),
        ),
      ),
    );
  }

  Future<void> _initChatService() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (!_chatService.isSocketConnected) {
        await _chatService.initGlobalConnection();
      } else {
        _chatService.refreshGlobalConnection();
      }

      await _chatService.loadChatRooms();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing chat service: $e");
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatRooms = _chatService.chatRooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout(context);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: FutureBuilder<List<dynamic>>(
                      future: AuthService.fetchUsers(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasData &&
                            snapshot.data!.isNotEmpty) {
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              var user = snapshot.data![index];
                              final userId = _resolveUserId(user);
                              final username = (user['username'] ?? '')
                                  .toString();

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: InkWell(
                                  onTap: userId == null
                                      ? null
                                      : () {
                                          _navigateToChat(userId, username);
                                        },
                                  child: Column(
                                    mainAxisSize: .min,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.grey[300],
                                        child: Text(
                                          username.isNotEmpty
                                              ? username[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        username,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          return const Center(child: Text('No user found.'));
                        }
                      },
                    ),
                  ),
                ),
                const Text("Chat Room", style: TextStyle(fontSize: 20)),
                if (chatRooms.isEmpty && !_isLoading)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: .center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No chat rooms yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation by selecting a user above.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (chatRooms.isNotEmpty)
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _chatService.loadChatRooms(),
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          return _buildChatRoomItem(chatRooms[index]);
                        },
                        itemCount: chatRooms.length,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Container _buildChatRoomItem(ChatRoom chatRoom) {
    final localCount = _newMessageCount[chatRoom.userId] ?? 0;
    final unreadCount = localCount > chatRoom.unreadCount
        ? localCount
        : chatRoom.unreadCount;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: ListTile(
        leading: _buildAvatar(chatRoom.username, chatRoom.avatarUrl),
        title: Text(chatRoom.username),
        subtitle: Text(
          MessageFormatter.formatMessagePreview(chatRoom.latestMessage),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .end,
          children: [
            Text(
              MessageFormatter.formatTimestamp(
                chatRoom.latestMessageTime.toLocal(),
              ),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$unreadCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          _navigateToChat(chatRoom.userId, chatRoom.username);
        },
      ),
    );
  }

  void _navigateToChat(String userId, String username) {
    setState(() {
      _newMessageCount.remove(userId);
    });

    Get.to(() => ChatView(receiverId: userId, receiverName: username))?.then((
      _,
    ) {
      _chatService.loadChatRooms();
    });
  }

  //
}
