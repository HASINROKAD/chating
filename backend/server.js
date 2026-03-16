import express from "express";
import { connectDb } from "./src/config/db.js";
import userRoutes from "./src/routes/userRoutes.js";
import chatRoutes from "./src/routes/chatRoute.js";
import { Server } from "socket.io";
import { updateUserLastSeen } from "./src/services/userServices.js";
import { User } from "./src/models/User.js";
import { createServer } from "http";
import Message from "./src/models/messageModel.js";
import {
  roomId,
  updateMessageStatus,
  getUndeliveredMessages,
  markMessageAsDelivered,
  getUserLastSeen,
  createMessage,
  markMessagesAsRead,
} from "./src/services/chatServices.js";
import { getRoomId } from "./src/utils/chatHelper.js";

connectDb();
const app = express();

app.use(express.json());

app.use("/api/users", userRoutes);
app.use("/api/chat", chatRoutes);

const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: "*",
  },
});

const onlineUsers = new Map();

io.on("connection", (socket) => {
  console.log("New Client connected: ", socket.id);
  let currentUserId = null;

  //Register user and store their socket ID
  socket.on("register_user", ({ userId }) => {
    if (userId) return;

    currentUserId = userId;
    onlineUsers.set(userId, socket.id);

    console.log(`User ${userId} registered with socket ID: ${socket.id}`);

    checkPendingMessages();
  });

  //Join a chat room
  socket.on("join_room", async ({ userId, partnerId }) => {
    if (!userId || !partnerId) {
      console.error("User ID and Partner ID are required to join a room.");
      return;
    }
    currentUserId = userId;
    onlineUsers.set(userId, socket.id);

    const roomId = roomId(userId, partnerId);
    socket.join(roomId);
    console.log(`User ${userId} joined room: ${roomId}`);

    try {
      const undeliveredMessages = await getUndeliveredMessages(
        userId,
        partnerId,
      );
      const undeliveredCount = await markMessageAsDelivered(userId, partnerId);
      if (undeliveredCount > 0) {
        console.log(
          `Marked ${undeliveredCount} messages as delivered for user ${userId} in room ${roomId}`,
        );
        undeliveredMessages.forEach((message) => {
          io.to(socket.id).emit("message_status", {
            messageId: message.messageId,
            status: "delivered",
            sender: message.sender,
            receiver: message.receiver,
          });
        });
      }
      io.to(roomId).emit("user_status", {
        userId: userId,
        status: "online",
      });

      if (onlineUsers.has(partnerId)) {
        socket.emit("user_status", {
          userId: userId,
          status: "online",
        });
      } else {
        const lastSeen = await getUserLastSeen(partnerId);
        socket.emit("user_status", {
          userId: partnerId,
          status: "offline",
          lastSeen: lastSeen || new Date().toISOString(),
        });
      }
    } catch (error) {
      console.error("Error handling join_room event: ", error);
    }
  });

  //Sending message in the room
  socket.on("send_message", async (message) => {
    if (
      !message.sender ||
      !message.receiver ||
      !message.messageId ||
      !message.message
    ) {
      console.error("Invalid message format", message);
      return;
    }

    const roomId = roomId(message.sender, message.receiver);
    await createMessage({ ...message, status: "sent", roomId: roomId });
    console.log(
      `Message in room ${roomId} from ${message.sender} to ${message.receiver} : ${message.message}`,
    );

    if (onlineUsers.has(message.receiver)) {
      message.status = "delivered";
      await updateMessageStatus(message.messageId, "delivered");
    } else {
      message.status = "sent";
    }

    io.to(roomId).emit("new_message", message);

    if (onlineUsers.has(message.receiver)) {
      const receiverSocketId = onlineUsers.get(message.receiver);
      const receiverSocket = io.sockets.sockets.get(receiverSocketId);

      if (receiverSocket && !receiverSocket.rooms.has(roomId)) {
        const sender = await User.findById(message.sender).select("username");

        receiverSocket.emit("new_message_notification", {
          messageId: message.messageId,
          senderId: message.sender,
          senderName: sender ? sender.username : "Unknown",
          message: message.message,
        });
      }
    }
  });

  //Typing indicator
  const TypingTimeouts = new Map();

  //Typing indicator start
  socket.on("typing_start", ({ userId, receiverId }) => {
    if (!userId || !receiverId) return;

    const roomId = getRoomId(userId, receiverId);
    const key = `${userId}-${receiverId}`;
    if (TypingTimeouts.has(key)) {
      clearTimeout(TypingTimeouts.get(key));
    }

    socket.to(roomId).emit("typing_indicator", {
      userId,
      isTyping: true,
    });

    const timeout = setTimeout(() => {
      socket.to(roomId).emit("typing_indicator", {
        userId,
        isTyping: false,
      });
      TypingTimeouts.delete(key);
    }, 5000);

    TypingTimeouts.set(key, timeout);
  });

  //Typing indicator stop
  socket.on("typing_end", ({ userId, receiverId }) => {
    if (!userId || !receiverId) return;

    const roomId = getRoomId(userId, receiverId);
    const key = `${userId}-${receiverId}`;
    if (TypingTimeouts.has(key)) {
      clearTimeout(TypingTimeouts.get(key));
      TypingTimeouts.delete(key);
    }

    socket.to(roomId).emit("typing_indicator", {
      userId,
      isTyping: false,
    });
  });

  //message_delivered
  socket.on(
    "message_delivered",
    async ({ messageId, senderId, receiverId }) => {
      try {
        await updateMessageStatus(messageId, "delivered");

        const roomId = roomId(senderId, receiverId);

        const statusUpdate = {
          messageId: messageId,
          status: "delivered",
          sender: senderId,
          receiver: receiverId,
        };

        io.to(roomId).emit("message_status", statusUpdate);
      } catch (error) {
        console.error("Error updating message status:", error);
      }
    },
  );

  //message_read
  socket.on("messages_read", async ({ messageIds, senderId, receiverId }) => {
    try {
      for (const messageId of messageIds) {
        await updateMessageStatus(messageId, "read");
      }

      const roomId = roomId(senderId, receiverId);

      messageIds.forEach((messageId) => {
        const statusUpdate = {
          messageId: messageId,
          status: "read",
          sender: senderId,
          receiver: receiverId,
        };
        io.to(roomId).emit("message_status", statusUpdate);
      });
    } catch (error) {
      console.error("Error updating message status:", error);
    }
  });

  //mark_messages_read
  socket.on("mark_messages_read", async ({ userId, partnerId }) => {
    try {
      const count = await markMessagesAsRead(userId, partnerId);

      if (count > 0) {
        const roomId = roomId(userId, partnerId);
        io.to(roomId).emit("messages_all_read", {
          reader: userId,
          sender: partnerId,
        });
      }

      if (onlineUsers.has(partnerId)) {
        const senderSocketId = onlineUsers.get(partnerId);
        const senderSocket = io.sockets.sockets.get(senderSocketId);

        if (senderSocket && !senderSocket.rooms.has(roomId)) {
          senderSocket.emit("messages_all_read", {
            readerId: userId,
            senderId: partnerId,
          });
        }
      }
    } catch (error) {
      console.error("Error updating message status:", error);
    }
  });

  //user_status_change
  socket.on("user_status_change", async ({ userId, status, lastSeen }) => {
    if (status === "offline") {
      await updateUserLastSeen(userId, lastSeen);

      if (onlineUsers.get(userId) === socket.id) {
        onlineUsers.delete(userId);
      }

      io.emit("user_status", {
        userId,
        status: "offline",
        lastSeen: lastSeen,
      });
    } else {
      onlineUsers.set(userId, socket.id);
      io.emit("user_status", {
        userId,
        status: "online",
      });
    }
  });

  //Disconnect
  socket.on("disconnect", async () => {
    if (currentUserId) {
      if (onlineUsers.get(currentUserId) === socket.id) {
        onlineUsers.delete(currentUserId);
      }

      const lastseen = new Date().toISOString();
      await updateUserLastSeen(currentUserId, lastseen);

      io.emit("user_status", {
        userId: currentUserId,
        status: "offline",
        lastSeen: lastseen,
      });
    }
  });

  //
});

// Function to check for pending messages when a user connects
async function checkPendingMessages(userId) {
  try {
    const pendingMessages = await MessageChannel.find({
      receiver: userId,
      status: "sent",
    }).populate("sender", "username");

    if (pendingMessages.length > 0) {
      const messageBySender = {};

      pendingMessages.forEach((message) => {
        if (!messageBySender[msg.sender._id]) {
          messageBySender[msg.sender._id] = [];
        }
        messageBySender[msg.sender._id].push(msg);
      });

      const userSocket = io.sockets.sockets.get(onlineUsers.get(userId));

      if (userSocket) {
        Object.keys(messageBySender).forEach((senderId) => {
          const count = messageBySender[senderId].length;
          const senderName = messageBySender[senderId][0].sender.username;

          userSocket.emit("pending_messages", {
            senderId,
            senderName,
            count,
            latestMessage: messageBySender[senderId][0].message,
          });
        });
      }
    }
  } catch (error) {
    console.error("Error checking pending messages:", error);
  }
}
//
httpServer.listen(process.env.PORT || 5000, () => {
  console.log(`Server running on port ${process.env.PORT || 5000}`);
});
