import { fetchChatMessages, chatRoom } from "../services/chatServices.js";

export const getMessages = async (req, res) => {
  const { senderId, receiverId, pageId, limit } = req.query;

  try {
    const message = await fetchChatMessages({
      currentUserId: req.userId,
      senderId,
      receiverId,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });

    res.json({ success: true, messages: message });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Error Fetching Messages" });
  }
};

export const getChatRoom = async (req, res) => {
  try {
    const rooms = await chatRoom(req.userId);

    res.json({ success: true, message: rooms });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Error Fetching Chat Rooms" });
  }
};
