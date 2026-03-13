import express from "express";
import { createServer } from "http";
import { connectDb } from "./src/config/db.js";
import userRoutes from "./src/routes/userRoutes.js";
import chatRoutes from "./src/routes/chatRoute.js";

connectDb();
const app = express();

app.use(express.json());

app.use("/api/users", userRoutes);
app.use("/api/chat", chatRoutes);

app.listen(process.env.PORT || 5000, () => {
  console.log(`Server running on port ${process.env.PORT || 5000}`);
});
