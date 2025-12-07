# 📝 NoteIt - Intelligent AI-Powered Note Application

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Hive](https://img.shields.io/badge/Hive-ECC94B?style=for-the-badge&logo=hive&logoColor=white)

## 🚀 Overview

**NoteIt** is a next-generation Android application developed with **Flutter**, designed to bridge the gap between simple note-taking and AI productivity. 

Unlike standard apps, NoteIt features a **hybrid architecture** (Local + Cloud) ensuring data availability both offline and online. It integrates **Google's Gemini AI** for smart content generation and **AssemblyAI** for voice-to-text capabilities, making it a powerhouse for productivity.

## ✨ Key Features

### 🧠 Artificial Intelligence
* **Gemini API Integration:** Built-in AI assistant to help generate content, summarize ideas, and enhance your writing directly within the app.
* **Voice-to-Text (AssemblyAI):** Advanced speech recognition that accurately converts voice recordings into text notes.

### 📝 Core Functionality
* **Smart CRUD:** Full Create, Read, Update, and Delete operations for seamless note management.
* **Trash with Auto-Delete:** Deleted notes are moved to a Trash/Recycle Bin and are automatically permanently deleted after a specific time duration (e.g., 30 days).
* **Advanced Filtering:** Quickly find notes using smart search and filtering options.
* **Rich Media Storage:** Add images to your notes, securely stored using **Supabase Storage**.

### ☁️ Hybrid Data Architecture
* **Offline-First (Hive):** Uses Hive NoSQL database to store data locally, ensuring the app works perfectly without internet.
* **Cloud Sync (Firebase):** Syncs data to **Firebase Realtime Database** when online, allowing access across devices.

### 👤 User Management & Security
* **Google Sign-In:** Secure and one-tap authentication via Firebase Auth.
* **Profile Section:**
    * Edit Profile details.
    * Change Password.
    * **Delete Account:** Full control for users to permanently remove their account and data.

### ⚙️ DevOps & Monetization
* **Firebase Crashlytics:** Real-time crash reporting to monitor app stability and fix bugs instantly.
* **Remote Config:** Use Firebase Remote Config to toggle features and change app appearance without releasing a new update.
* **Push Notifications:** Integrated **Firebase Cloud Messaging (FCM)** to keep users engaged.
* **Google AdMob:** Monetization via banner and interstitial ads.

## 🛠️ Tech Stack

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Frontend** | Flutter (Dart) | Cross-platform UI toolkit |
| **Authentication** | Firebase Auth | Google Sign-In handling |
| **Local Database** | Hive | High-speed local data persistence |
| **Cloud Database** | Firebase Realtime DB | Server-side data synchronization |
| **Image Storage** | Supabase | Scalable object storage for images |
| **Generative AI** | Google Gemini API | Text generation and AI assistance |
| **Voice AI** | AssemblyAI | Audio transcription |
| **Analytics** | Firebase Crashlytics | Stability monitoring |
| **Config/Updates** | Remote Config | Dynamic feature management |
| **Messaging** | FCM | Cloud messaging/notifications |
| **Ads** | Google Mobile Ads | Ad integration |

## 📸 Screenshots

*(Screenshots coming soon)*

## ⚡ Getting Started

Follow these steps to set up the project locally on your machine.

### Prerequisites
* Flutter SDK installed
* Android Studio / VS Code
* A Firebase Project
* A Supabase Project
* API Keys for Gemini & AssemblyAI

### Installation

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/your-username/NoteIt.git](https://github.com/your-username/NoteIt.git)
    cd NoteIt
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration**
    * Go to your Firebase Console.
    * Download `google-services.json`.
    * Place it in the `android/app/` directory.

4.  **API Key Setup**
    * Create a `.env` file or a `secrets.dart` file (ensure this is added to `.gitignore`).
    * Add your keys:
        * `GEMINI_API_KEY`
        * `ASSEMBLY_AI_KEY`
        * `SUPABASE_URL` & `SUPABASE_ANON_KEY`

5.  **Run the App**
    ```bash
    flutter run
    ```

## 🤝 Contributing

Contributions are always welcome!
1.  Fork the project
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request



**Developed with ❤️ by Kumari Surbhi**