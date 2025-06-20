<!-- cspell:disable -->
# 📱 Graph — Super Simple Social App

![Cover](https://github.com/user-attachments/assets/7d58765b-bbbc-4779-84cc-bb40f5b07db6)


Graph is a minimalist, modern social media app built with **Flutter**, featuring authentication, user profiles, post feeds, comments, messaging, and more. Designed with a focus on clean UI/UX, real-time updates, and responsive behavior for both mobile and web.

---

## 🚀 Features

### 🔐 Authentication
- Email/password sign-up & login
- Google and GitHub OAuth
- Secure custom text fields with validation

### 👤 User Profiles
- View and edit profile with avatar and bio
- Tabbed user posts grid (opens to feed)
- Follow/unfollow, block/unblock users
- View others' profiles with dynamic state handling

### 📰 Feed & Posts
- Displays posts from non-blocked users
- Each post includes:
  - User avatar, name, image, caption
  - Like and comment count (latest comment preview)
- Post actions:
  - Like/Unlike with owner notification
  - Comment with notification
  - Delete (own post only)
  - Report (feedback bottom sheet)
- Blocked users' posts are hidden

### 💬 Comments
- Tap comment icon to open full comment thread
- Latest comment preview in feed
- Add new comments from a dedicated screen
- Report any comment via bottom sheet

### 💌 Chat / Messaging
- 1-to-1 chat with Telegram-style bubbles
- Read/seen indicators
- Edit or delete own messages (long-press)
- Bottom sheet UI for editing
- Text-only chat (no media/voice)

### 🎨 Theming
- Full light/dark mode support
- Themed chat bubbles, app bars, etc.

### 🧠 Text Bomb Protection
- Character count limitation
- “See more / See less” UI for long text

### 📲 UI/UX Highlights
- Custom bottom sheets (edit, report, etc.)
- Toasts and snackbars for feedback
- Responsive mobile & web layout (`kIsWeb`)
- State managed via `flutter_bloc`
- Smooth experience across devices

---

## 🛠️ Tech Stack

- **Flutter**
- **Firebase**: Auth, Firestore
- **Supabase**: storage
- `flutter_bloc` (state management)
- `get_it` (dependency injection)
- `shared_preferences`, `cached_network_image`
- `json_serializable`, `intl`, `image_picker`, and more

---

## 📦 Dependencies

<details>
<summary>Tap to expand</summary>

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.13.1
  firebase_auth: ^5.5.4
  cloud_firestore: ^5.6.8
  supabase: ^2.7.0
  supabase_flutter: ^2.9.0
  flutter_bloc: ^9.1.1
  bloc: ^9.0.0
  get_it: latest
  cached_network_image: ^3.4.1
  shared_preferences: ^2.5.3
  google_sign_in: ^6.3.0
  image_picker: ^1.1.2
  image_picker_web: ^4.0.0
  fluttertoast: ^8.2.12
  flutter_chat_bubble: ^2.0.2
  json_serializable: ^6.9.5
  json_annotation: ^4.9.0
  intl: ^0.20.2
  package_info_plus: ^8.3.0
  path_provider: ^2.1.5
  url_launcher: ^6.3.1
  uuid: ^4.5.1
  quickalert: ^1.1.0
  google_fonts: ^6.2.1
  retrofit: ^4.4.2
  retrofit_generator: ^9.2.0
  mime: ^2.0.0
  meta: ^1.16.0

dev_dependencies:
  flutter_launcher_icons: ^0.14.3
  flutter_lints: ^5.0.0
  build_runner: ^2.4.15
  flutter_test:
    sdk: flutter
````

</details>

---

## 🖼️ App Icon

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/graph.png"
```

---

## ✨ Notable UX Details

* All destructive actions are confirmed via bottom sheets or toasts
* Robust block/unblock logic reflected throughout the app
* Offline-aware and optimized for real-time UX
* Clean architecture with clear separation of concerns

---

## 🔧 Getting Started

1. Clone the repo:

   ```bash
   git clone https://github.com/0xAhmd/graph.git
   cd graph
   ```
2. Get dependencies:

   ```bash
   flutter pub get
   ```
3. Set up Firebase and Supabase credentials in `.env`
4. Run the app:

   ```bash
   flutter run
   ```

---

## 🧑‍💻 Author

**Ahmed Hesham** — [GitHub @0xAhmd](https://github.com/0xAhmd)

