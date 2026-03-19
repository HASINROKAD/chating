import User from "../models/userModel.js";

export const getUsers = async (req, res) => {
  try {
    const users = await User.find({ _id: { $ne: req.userId } }).select(
      "_id username name",
    );

    const response = users.map((user) => {
      const displayName = user.name || user.username;
      return {
        _id: user._id,
        id: user._id,
        username: displayName,
        name: displayName,
      };
    });

    return res.status(200).json(response);
  } catch (error) {
    return res.status(500).json({ message: "Error fetching users" });
  }
};
