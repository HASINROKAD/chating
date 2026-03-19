import mongoose from "mongoose";
import Message from "../models/messageModel.js";
import User from "../models/userModel.js";
import { getRoomId } from "../utils/chatHelper.js";

const ObjectId = mongoose.Types.ObjectId;

const toObjectId = (id, fieldName) => {
  if (!mongoose.isValidObjectId(id)) {
    throw new Error(`Invalid ${fieldName}: ${id}`);
  }

  return new ObjectId(id);
};

export const createMessage = async (messageData) => {
  try {
    const message = new Message({
      chatRoomId: messageData.roomId,
      messageId: messageData.messageId,
      sender: messageData.sender,
      receiver: messageData.receiver,
      message: messageData.message,
      status: messageData.status || "sent",
    });

    await message.save();
    return message;
  } catch (error) {
    throw error;
  }
};

export const fetchChatMessages = async ({
  currentUserId,
  senderId,
  receiverId,
  page = 1,
  limit = 20,
}) => {
  const roomId = getRoomId(senderId, receiverId);
  const query = { chatRoomId: roomId };
  try {
    const currentUserObjectId = toObjectId(currentUserId, "currentUserId");

    if (currentUserId === receiverId) {
      const senderObjectId = toObjectId(senderId, "senderId");

      const undeliveredQuery = {
        chatRoomId: roomId,
        receiver: currentUserObjectId,
        sender: senderObjectId,
        status: "sent",
      };

      const undeliveredUpdate = await Message.updateMany(undeliveredQuery, {
        $set: { status: "delivered" },
      });
      if (undeliveredUpdate.modifiedCount > 0) {
        console.log(
          `Updated ${undeliveredUpdate.modifiedCount} messages to delivered status.`,
        );
      }
    }

    const messages = await Message.aggregate([
      { $match: query },
      { $sort: { createdAt: -1 } },
      { $skip: (page - 1) * limit },
      { $limit: limit },
      {
        $addFields: {
          isMine: {
            $eq: ["$sender", currentUserObjectId],
          },
        },
      },
    ]);

    return messages.reverse();
  } catch (error) {
    throw new Error("Failed to retrieve messages: " + error.message);
  }
};

export const updateMessageStatus = async (messageId, status) => {
  try {
    const message = await Message.findOneAndUpdate(
      { messageId: messageId },
      { status: status },
      { returnDocument: "after" },
    );
    return message;
  } catch (error) {
    throw error;
  }
};

export const getUndeliveredMessages = async (userId, partnerId) => {
  try {
    const receiverObjectId = toObjectId(userId, "userId");
    const senderObjectId = toObjectId(partnerId, "partnerId");

    const message = await Message.find({
      receiver: receiverObjectId,
      sender: senderObjectId,
      status: "sent",
    }).sort({ createdAt: 1 });
    return message;
  } catch (error) {
    throw error;
  }
};

export const updateUserLastSeen = async (userId, lastSeen) => {
  try {
    const user = await User.findByIdAndUpdate(
      userId,
      { lastSeen: lastSeen },
      { returnDocument: "after" },
    );
    return user;
  } catch (error) {
    throw error;
  }
};

export const markMessageAsDelivered = async (userId, partnerId) => {
  try {
    const result = await Message.updateMany(
      {
        receiver: new ObjectId(userId),
        sender: new ObjectId(partnerId),
        status: "sent",
      },
      { $set: { status: "delivered" } },
    );
    return result.modifiedCount;
  } catch (error) {
    throw error;
  }
};

export const markMessageAsRead = async (userId, partnerId) => {
  try {
    const receiverObjectId = toObjectId(userId, "userId");
    const senderObjectId = toObjectId(partnerId, "partnerId");

    const result = await Message.updateMany(
      {
        receiver: receiverObjectId,
        sender: senderObjectId,
        status: { $in: ["sent", "delivered"] },
      },
      { $set: { status: "read" } },
    );
    return result.modifiedCount;
  } catch (error) {
    throw error;
  }
};

export const getUserLastSeen = async (userId) => {
  try {
    const user = await User.findById(userId).select("lastSeen");
    if (!user) {
      return null;
    }

    return user.lastSeen ? user.lastSeen.toISOString() : null;
  } catch (error) {
    throw error;
  }
};

export const getUserOnlineStatus = async (userId) => {
  try {
    const user = await User.findById(userId).select("isOnline lastSeen");
    if (!user) {
      return { isOnline: false, lastSeen: null };
    }

    return {
      isOnline: user.isOnline,
      lastSeen: user.lastSeen ? user.lastSeen.toISOString() : null,
    };
  } catch (error) {
    throw error;
  }
};

// CHATROOM
export const chatRoom = async (userId) => {
  try {
    const userObjectId = new mongoose.Types.ObjectId(userId);

    const privateChatQuery = {
      $or: [{ sender: userObjectId }, { receiver: userObjectId }],
    };

    const privateChats = await Message.aggregate([
      { $match: privateChatQuery },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: {
            $cond: [{ $ne: ["$sender", userObjectId] }, "$sender", "$receiver"],
          },
          latestMessageTime: { $first: "$createdAt" },
          latestMessage: { $first: "$message" },
          latestMessageId: { $first: "$_id" },
          sender: { $first: "$sender" },
          messages: {
            $push: {
              sender: "$sender",
              receiver: "$receiver",
              status: "$status",
            },
          },
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "_id",
          as: "userDetails",
        },
      },
      {
        $unwind: "$userDetails",
      },
      {
        $project: {
          _id: 0,
          chatType: "private",
          messageId: "$latestMessageId",
          username: { $ifNull: ["$userDetails.name", "$userDetails.username"] },
          userId: "$userDetails._id",
          latestMessageTime: 1,
          latestMessage: 1,
          sender: 1,
          unreadCount: {
            $size: {
              $filter: {
                input: "$messages",
                as: "msg",
                cond: {
                  $and: [
                    { $eq: ["$$msg.receiver", userObjectId] },
                    { $in: ["$$msg.status", ["sent", "delivered"]] },
                  ],
                },
              },
            },
          },
          latestMessageStatus: {
            $cond: [
              {
                $eq: ["$sender", userObjectId],
              },
              {
                $arrayElemAt: [
                  {
                    $map: {
                      input: {
                        $filter: {
                          input: "$messages",
                          as: "msg",
                          cond: {
                            $eq: ["$$msg.receiver", userObjectId],
                          },
                        },
                      },
                      as: "m",
                      in: "$$m.status",
                    },
                  },
                  0,
                ],
              },
              null,
            ],
          },
        },
      },
    ]);
    return privateChats.sort((a, b) => {
      return new Date(b.latestMessageTime) - new Date(a.latestMessageTime);
    });
  } catch (error) {
    throw error;
  }
};
