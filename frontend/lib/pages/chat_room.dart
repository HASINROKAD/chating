import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';

class DirectMessages extends StatefulWidget {
  const DirectMessages({super.key});

  @override
  State<DirectMessages> createState() => _DirectMessagesState();
}

class _DirectMessagesState extends State<DirectMessages> {
  final ChatService _chatService = ChatPlugin.chatService;

  bool _isLoading = true;
  Map<String, int> _newMessageCount = {};

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
        if (data["event_name"] == 'new_message_notification') {
          _handleNewMessageNotification(data['data']);
        }
      },
    );

    _initChatService();
  }

  _handleNewMessageNotification(Map<String, dynamic> messageData) {
    if (!mounted) return;

    final senderId = messageData['senderId'];

    if (senderId != null) {
      setState(() {
        _newMessageCount[senderId] = (_newMessageCount[senderId] ?? 0) + 1;
      });
    }
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
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: InkWell(
                                  onTap: () {},
                                  child: Column(
                                    mainAxisSize: .min,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.grey[300],
                                        child: Text(
                                          user['username'][0].toUpperCase(),
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        user['username'],
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

  _buildChatRoomItem(ChatRoom chatRoom) {
    final localCount = _newMessageCount[chatRoom.userId] ?? 0;
    final unreadCount = localCount > chatRoom.unreadCount
        ? localCount
        : chatRoom.unreadCount;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
            chatRoom.avatarUrl ?? "https://via.placeholder.com/150",
          ),
        ),
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
                  "{$unreadCount}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  // void _navigateToChat(String userId, String username) {
  //   setState(() {
  //     _newMessageCount.remove(userId);
  //   });
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) =>
  //           ChatScreenPage(receiverId: userId, receiverName: username),
  //     ),
  //   ).then(_){
  //     _chatService.loadChatRooms();
  //   };
  // }

  //
}
