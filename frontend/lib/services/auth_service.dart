import 'dart:convert';

import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  static Future<bool> loginUser(String userName, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.API_BASE_URL}/api/users/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": userName, "password": password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["userId"] != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userId", data["userId"]);
          await prefs.setString("token", data["token"]);

          //CHAT PLUGIN
          await initializeChatPlugin(data["userId"], data["token"]);

          await Future.delayed(const Duration(seconds: 5));
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print("Error during login: $e");
      }
      return false;
    }
  }

  static Future<bool> registerUser(String userName, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${Config.API_BASE_URL}/api/users/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": userName, "password": password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["userId"] != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString("userId", data["userId"]);
          await prefs.setString("token", data["token"]);

          //CHAT PLUGIN
          await initializeChatPlugin(data["userId"], data["token"]);

          await Future.delayed(const Duration(seconds: 5));
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print("Error during registration: $e");
      }
      return false;
    }
  }

  static Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId");
  }

  static Future<bool?> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("userId") != null ? true : false;
  }

  static Future<String?> getUserToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> logout(BuildContext context) async {
    try {
      if (ChatConfig.instance.userId != null) {
        ChatPlugin.chatService.fullDisconnect();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error during logout: $e");
      }
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("userId");
    await prefs.remove("token");

    Navigator.of(context).pushReplacementNamed('/landing');
  }

  static Future<void> initializeChatPlugin(String userId, String token) async {
    try {
      if (ChatConfig.instance.userId == userId) {
        ChatPlugin.chatService.refreshGlobalConnection();
        return;
      }
      await ChatPlugin.initialize(
        config: ChatConfig(
          apiUrl: Config.API_BASE_URL,
          userId: userId,
          token: token,
          enableTypingIndicators: true,
          enableReadReceipts: true,
          enableOnlineStatus: true,
          autoMarkAsRead: true,
          maxReconnectionAttempts: 5,
          debugMode: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing chat plugin: $e");
      }
    }
  }

  static Future<void> _setupChatAPIHandlers(String userId, String token) async {
    final apiHandler = ChatApiHandlers(
      loadMessagesHandler: ({limit = 20, page = 1, searchText = ""}) async {
        final receiverId = ChatPlugin.chatService.receiverId;

        if (receiverId.isEmpty) return [];

        try {
          var url =
              "${Config.API_BASE_URL}/api/messages?currentUserId=$userId&receiverId=$receiverId&page=$page&limit=$limit";

          if (searchText.isNotEmpty) {
            url += "&searchText=${Uri.encodeComponent(searchText)}";
          }

          final response = await http.get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);

            return data.map((msg) => ChatMessage.fromMap(msg, userId)).toList();
          } else {
            return [];
          }
        } catch (e) {
          if (kDebugMode) {
            print("Error loading messages: $e");
          }
          return [];
        }
      },

      loadChatRoomsHandler: () async {
        try {
          var url = "${Config.API_BASE_URL}/api/chat-room";

          final response = await http.get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          );

          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);

            return data.map((room) => ChatRoom.fromMap(room)).toList();
          } else {
            return [];
          }
        } catch (e) {
          if (kDebugMode) {
            print("Error loading chat rooms: $e");
          }
          return [];
        }
      },
    );

    ChatPlugin.chatService.setApiHandlers(apiHandler);
  }

  static Future<List<dynamic>> fetchUsers() async {
    try {
      var token = await getUserToken();
      final response = await http.get(
        Uri.parse("${Config.API_BASE_URL}/api/users/users"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print("Error during login: $e");
      }
      return [];
    }
  }
}
