import { register, login } from "./authService.js";

export const registerUser = async (req, res) => {
  const { username, password, name } = req.body;

  try {
    const response = await register({ username, password, name });

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

export const loginUser = async (req, res) => {
  const { username, password } = req.body;

  try {
    const response = await login({ username, password });
    if (!response) {
      return res.status(401).json({ message: "Login Failed" });
    }

    return res.status(200).json(response);
  } catch (error) {
    return res.status(500).json({ message: "Login error" });
  }
};
