import { register, login } from "../services/authService.js";
import User from "../models/userModel.js";

// Controller functions for user registration
export const registerUser = async (req, res) => {
  const { username, password } = req.body;

  try {
    const response = await register(username, password);

    if (response.error) {
      return res
        .status(response.statusCode || 400)
        .json({ message: response.error });
    }

    return res.status(201).json(response);
  } catch (error) {
    return res.status(500).json({ message: "Error during registration user" });
  }
};

// Controller function for user login
export const loginUser = async (req, res) => {
  const { username, password } = req.body;

  try {
    const response = await login(username, password);
    if (!response) {
      return res.status(401).json({ message: "Login Failed" });
    }
    return res.status(200).json(response);
  } catch (error) {
    return res.status(500).json({ message: "Login error" });
  }
};

export const getUsers = async (req, res) => {
  try {
    const users = await User.find({ _id: { $ne: req.userId } }).select(
      "_id username",
    );
    return res.status(200).json(users);
  } catch (error) {
    return res.status(500).json({ message: "Error fetching users" });
  }
};
