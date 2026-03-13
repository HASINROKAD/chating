import express from "express";
import { createServer } from "http";
import { connectDb } from "./src/config/db.js";
import userRoutes from "./src/routes/userRoutes.js";

connectDb();
const app = express();

app.use(express.json());

app.use("/api/users", userRoutes);

app.listen(process.env.PORT || 5000, () => {
  console.log(`Server running on port ${process.env.PORT || 5000}`);
});
