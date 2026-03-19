# Frontend

Flutter client for the Chating app.

## Highlights

- Login/Register UI
- Direct message list and chat screen
- Real-time updates through chat_plugin + Socket.IO backend
- GetX routing and module organization
- User display names shown in chat list and notifications

## Folder Overview

lib/app

- routes: centralized route names and page map
- modules: feature-based module folders (initializer, landing, login, register, direct_messages, chat)

lib/pages

- Existing page implementations used by module views where needed

lib/services

- auth_service.dart: auth calls, plugin init, API handlers

## Configuration

Set backend host in:
frontend/lib/config.dart

Example value:
http://192.168.x.x:3000

Use your machine LAN IP so emulator/device can reach backend.

## Run

From frontend folder:
flutter pub get
flutter run

## Authentication Flow

- Register sends name, username, and password
- Login uses username and password
- JWT token and userId are persisted in shared preferences

## Chat Flow

- Initialize chat plugin after login/register
- Load chat rooms from API
- Open chat by receiverId
- Receive real-time message events, status updates, typing, and online status

## Troubleshooting

- If app is stuck on loader, verify initializer route and bindings are loaded.
- If chat does not connect, ensure backend is running and API_BASE_URL is reachable.
- If names show as email-like strings for old accounts, backend fallback may display text before @.
