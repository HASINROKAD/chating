# Backend

Node.js real-time chat backend for the Chating app.

## Stack

- Express 5
- MongoDB with Mongoose
- Socket.IO
- JWT auth
- bcryptjs password hashing

## Folder Overview

backend/src

- config: database connection
- controllers: HTTP controllers
- middleware: auth middleware
- models: Mongoose schemas
- modules/auth: auth controller/service (modularized)
- routes: API routes
- services: chat business logic
- utils: helpers

## Environment Variables

Create backend/.env:

PORT=3000
MONGO_URI=<your-mongodb-connection-string>
JWT_SECRET=<your-secret>

## Run

From backend folder:

npm install
npm run run

## API

User routes

- POST /api/users/register
- POST /api/users/login
- GET /api/users/users (Bearer token)

Chat routes

- GET /api/chat/messages?senderId=<id>&receiverId=<id>&page=1&limit=20 (Bearer token)
- GET /api/chat/chat-room (Bearer token)

## Socket Events

Client to server (main)

- register_user
- join_room
- send_message
- typing_start
- typing_end
- message_delivered
- messages_read
- mark_messages_read
- user_status_change

Server to client (main)

- new_message
- new_message_notification
- message_status
- messages_all_read
- typing_indicator
- user_status
- pending_messages

## Name/Username Behavior

- Register accepts name and username.
- name is preferred for display.
- For old users without name, backend falls back to username.
- If fallback is email-like, text before @ is used for display in key endpoints/events.
