# Chating App

Full-stack real-time chat application with:

- Node.js + Express + MongoDB backend
- Flutter frontend
- Socket.IO messaging
- JWT authentication
- GetX-based frontend routing/module structure

## Project Structure

- backend: API, auth, Socket.IO events, MongoDB models
- frontend: Flutter UI, chat integration, GetX routes/modules

## Core Features

- User registration and login with JWT
- Real-time 1:1 messaging via Socket.IO
- Typing indicator
- Delivery and read status updates
- Chat room list with latest message and unread count
- Online/offline user status and last seen
- Display names in chat list and notifications

## Tech Stack

Backend

- Express 5
- Mongoose
- Socket.IO
- bcryptjs
- jsonwebtoken

Frontend

- Flutter
- GetX
- shared_preferences
- chat_plugin

## Quick Start

1. Backend setup

From backend folder:
npm install

Create backend/.env with:
PORT=3000
MONGO_URI=<your-mongodb-connection-string>
JWT_SECRET=<your-secret>

Run backend:
npm run run

2. Frontend setup

From frontend folder:
flutter pub get

Set your API host in frontend/lib/config.dart.
Example:
http://192.168.x.x:3000

Run frontend:
flutter run

## API Endpoints

Auth

- POST /api/users/register
- POST /api/users/login

Users

- GET /api/users/users (Bearer token)

Chat

- GET /api/chat/messages?senderId=<id>&receiverId=<id>&page=1&limit=20 (Bearer token)
- GET /api/chat/chat-room (Bearer token)

## Display Name Behavior

- Registration accepts name and username.
- Backend uses name as preferred display name.
- If name is missing for old users, fallback display name is generated from username.
- If username is an email, text before @ is used for display.

## Notes

- Use a reachable LAN IP in frontend/lib/config.dart when testing on physical devices/emulators.
- If backend is already inside backend folder, run npm commands directly without adding cd backend again.
