import User from "../../models/userModel.js";
import jwt from "jsonwebtoken";

export const register = async ({ username, password, name }) => {
  if (!username || !password) {
    return { error: "Username and password are required", statusCode: 400 };
  }

  if (password.length < 8) {
    return {
      error: "Password must be at least 8 characters long",
      statusCode: 400,
    };
  }

  const displayName =
    typeof name === "string" && name.trim() ? name.trim() : username;

  try {
    const user = await User.create({
      name: displayName,
      username,
      password,
    });

    return {
      token: jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
        expiresIn: "10d",
      }),
      userId: user._id,
    };
  } catch (error) {
    if (error.code === 11000) {
      return { error: "Username already exists", statusCode: 409 };
    }

    console.error("Registration error:", error);
    return { error: "Registration failed", statusCode: 500 };
  }
};

export const login = async ({ username, password }) => {
  try {
    const user = await User.findOne({ username });
    if (!user) {
      throw new Error("User not found");
    }

    const isMatch = await user.correctPassword(password, user.password);
    if (!isMatch) {
      throw new Error("Incorrect password");
    }

    return {
      token: jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
        expiresIn: "10d",
      }),
      userId: user._id,
    };
  } catch (error) {
    console.log("Login error:", error.message);
    return null;
  }
};
