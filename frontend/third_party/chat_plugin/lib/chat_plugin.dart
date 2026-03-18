import 'chat_plugin.dart';
export 'package:chat_plugin/src/models/models.dart';
export 'package:chat_plugin/src/core/chat_service.dart';
export 'package:chat_plugin/src/config/chat_config.dart';
export 'package:chat_plugin/src/utils/message_formatter.dart';

/// Main class for initializing and using the Flutter Chat Plugin
class ChatPlugin {
  /// Initializes the Flutter Chat Plugin with the given configuration
  /// Must be called before using any other plugin features
  static Future<void> initialize({required ChatConfig config}) async {
    ChatConfig.instance = config;
  }

  /// Returns the current instance of the chat service
  static ChatService get chatService => ChatService.instance;

  /// Returns the current instance of the auth service
  //static ChatAuthService get authService => ChatAuthService.instance;
}
