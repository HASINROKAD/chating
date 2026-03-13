import { mongoose } from "mongoose";
import Message from "../models/Message.js";
import User from "../models/userModel.js";
import { getRoomId } from "../utils/chatHelper.js";

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
    if (currentUserId === receiverId) {
      const undeliveredQuery = {
        chatRoomId: roomId,
        receiver: mongoose.Types.ObjectId(currentUserId),
        sender: mongoose.Types.ObjectId(senderId),
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
      const messages = await Message.aggregate([
        { $match: query },
        { $sort: { createdAt: -1 } },
        { $skip: (page - 1) * limit },
        { $limit: limit },
        {
          $addFields: {
            isMine: {
              $eq: ["$sender", { $toObjectId: currentUserId }],
            },
          },
        },
      ]);
      return messages.reverse();
    }
  } catch (error) {
    throw new Error("Failed to retrieve messages: " + error.message);
  }
};

export const updateMessageStatus = async (messageId, status) => {
  try {
    const message = await Message.findOneAndUpdate(
      { messageId: messageId },
      { status: status },
      { new: true },
    );
    return message;
  } catch (error) {
    throw error;
  }
};

export const getUndeliveredMessages = async (userId, partnerId) => {
  try {
    const message = await Message.find({
      receiver: userId,
      sender: partnerId,
      status: "sent",
    }).$sort({ createdAt: 1 });
    return message;
  } catch (error) {
    throw error;
  }
};

export const updateUserLastSeen = async (userId, lastSeen) => {
  try {
    const user = await User.findOneAndUpdate(
      userId,
      { lastSeen: lastSeen },
      { new: true },
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
        receiver: ObjectId(userId),
        sender: ObjectId(partnerId),
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
    const result = await Message.updateMany(
      {
        receiver: ObjectId(userId),
        sender: ObjectId(partnerId),
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
    const user = await User.findBy(userId).select("lastSeen");
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
    const user = await User.findBy(userId).select("isOnline lastSeen");
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
    const userObjecyId = new ObjectId(userId);

    const privateChatQuery = {
      $or: [{ sender: userObjecyId }, { receiver: userObjecyId }],
    };

    const privateChats = await Message.aggregate([
      { $match: privateChatQuery },
      { $sort: { createdAt: -1 } },
      {
        $group: {
          _id: {
            $cond: [{ $ne: ["$sender", userObjecyId] }, "$sender", "$receiver"],
          },
          latestMessageTime: { $first: "$createdAt" },
          latestMessage: { $first: "$message" },
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
          username: "userDetails.username",
          userId: "userDetails._id",
          latestMessageTime: 1,
          latestMessage: 1,
          senderId: 1,
          unreadCount: {
            $size: {
              $filter: {
                input: "$messages",
                as: "msg",
                cond: {
                  $and: [
                    { $eq: ["$$msg.receiver", userObjecyId] },
                    { $in: ["$$msg.status", ["sent", "delivered"]] },
                  ],
                },
              },
            },
          },
          latestMessageStatus: {
            $cond: [
              {
                $eq: ["$sender", userObjecyId],
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
                            $eq: ["$$msg.receiver", userObjecyId],
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
