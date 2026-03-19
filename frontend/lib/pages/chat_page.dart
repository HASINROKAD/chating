import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ChatService _chatService = ChatPlugin.chatService;
  final String _listenId = 'chat_screen_page';

  bool _isLoading = true;
  bool _isTyping = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerEventListner();
    _initChat();
    _controller.addListener(_onTextChnaged);
  }

  void _registerEventListner() {
    _chatService.addEventListener(
      ChatEventType.messagesChanged,
      "$_listenId-messages",
      (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          }); // Update the UI to reflect the new messages
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }
      },
    );

    _chatService.addEventListener(
      ChatEventType.typingStatusChanged,
      "$_listenId-typing",
      (isTyping) {
        if (mounted) {
          setState(() {}); // Update the UI to reflect the typing status
        }
      },
    );

    _chatService.addEventListener(
      ChatEventType.onlineStatusChanged,
      "$_listenId-online",
      (isOnline) {
        if (mounted) {
          setState(() {}); // Update the UI to reflect the online status
        }
      },
    );

    _chatService.addEventListener(
      ChatEventType.messageStatusChanged,
      "$_listenId-status",
      (_) {
        if (mounted) {
          setState(
            () {},
          ); // Update the UI to reflect the message status changes
        }
      },
    );

    _chatService.addEventListener(ChatEventType.error, "$_listenId-error", (
      error,
    ) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        ); // Show error message to the user
      }
    });
  }

  Future<void> _ensureSocketConnection() async {
    if (_chatService.isSocketConnected) {
      return;
    }

    await _chatService.initGlobalConnection();

    int attempts = 0;
    while (!_chatService.isSocketConnected && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 300));
      attempts++;
    }
  }

  Future<void> _initChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.receiverId.isEmpty) {
        throw Exception('Receiver ID is missing');
      }

      await _ensureSocketConnection();

      await _chatService.initChat(widget.receiverId);
      await _chatService.loadMessages();
      _chatService.updateUserStatus(true);
      _chatService.emitCustomEvent('get_user_status', {
        'userId': widget.receiverId,
      });
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load chat: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTextChnaged() {
    bool isCurrentlyTyping = _controller.text.isNotEmpty;

    if (_isTyping != isCurrentlyTyping) {
      _isTyping = isCurrentlyTyping;
      _chatService.sendTypingIndicator(_isTyping);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chatService.updateUserStatus(true);
    } else if (state == AppLifecycleState.paused) {
      _chatService.updateUserStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chatService.messages;
    final displayedMessages = messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(widget.receiverName), _buldUserStatus()],
        ),
      ),
      body: Column(
        children: [
          if (_chatService.isReceiverTyping)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              alignment: .centerLeft,
              child: Text(
                "${widget.receiverName} is typing...",
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),

          if (_isLoadingMore)
            Container(
              height: 40,
              alignment: .center,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

          Expanded(
            child: _isLoading
                ? Center(child: const CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
                    child: Text(
                      "No messages yet.\nSend a message to start a conversation",
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent) {
                        _loadMoreMessages();
                      }
                      return true;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 10.0,
                      ),
                      itemCount: displayedMessages.length,
                      itemBuilder: (context, index) {
                        final message = displayedMessages[index];
                        final isMe = message.isMine;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.78,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.pink[50] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  message.message,
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  mainAxisSize: .min,
                                  children: [
                                    Text(
                                      MessageFormatter.formatTimestamp(
                                        message.createdAt.toLocal(),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    if (isMe)
                                      _buildMessageStatus(message.status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        borderSide: BorderSide(
                          color: Colors.grey[400]!,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: 5,
                    minLines: 1,
                  ),
                ),

                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //
  Widget _buildMessageStatus(String status) {
    switch (status) {
      case 'sent':
        return const Icon(Icons.check, size: 14, color: Colors.grey);
      case 'delivered':
        return Row(
          children: [
            Icon(Icons.check, size: 14, color: Colors.grey),
            Transform.translate(
              offset: Offset(-4, 0),
              child: Icon(Icons.check, size: 14, color: Colors.grey),
            ),
          ],
        );
      case 'read':
        return Row(
          mainAxisSize: .min,
          children: [
            Icon(Icons.check, size: 14, color: Colors.blue),
            Transform.translate(
              offset: Offset(-4, 0),
              child: Icon(Icons.check, size: 14, color: Colors.blue),
            ),
          ],
        );

      default:
        return SizedBox.shrink();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_chatService.messages.isEmpty || _isLoadingMore || !_hasMoreMessages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    int currentMessageCount = _chatService.messages.length;
    int nextPage = (currentMessageCount / 20).ceil() + 1;

    try {
      final newMessages = await _chatService.loadMessages(
        page: nextPage,
        limit: 20,
      );
      if (newMessages.isEmpty) {
        _hasMoreMessages = false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more messages: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      await _chatService.sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }

  Widget _buldUserStatus() {
    if (_chatService.isReceiverOnline) {
      return Text(
        "Online",
        style: TextStyle(color: Colors.green, fontSize: 12),
      );
    } else if (_chatService.lastSeen != null) {
      return Text(
        "Last seen ${MessageFormatter.timeAgo(_chatService.lastSeen!)}",
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
