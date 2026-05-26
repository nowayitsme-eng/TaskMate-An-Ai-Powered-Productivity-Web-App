# TaskMate: AI-Powered Productivity Web App

![TaskMate Banner](https://img.shields.io/badge/TaskMate-AI_Productivity-00E5FF?style=for-the-badge) ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white) ![Firebase](https://img.shields.io/badge/firebase-ffca28?style=for-the-badge&logo=firebase&logoColor=black) ![AWS](https://img.shields.io/badge/AWS_Bedrock-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white) 

TaskMate is a next-generation, deeply gamified productivity and study-assistant application built with Flutter Web. It moves beyond traditional task management by integrating behavioral psychology (gamification), focus techniques (Pomodoro), and cutting-edge Generative AI (Anthropic's Claude via AWS Bedrock) into a single, cohesive ecosystem.

TaskMate's architectural philosophy revolves around real-time synchronization, offline-first resilience, and a premium Glassmorphism UI.

## 🚀 Key Features & Architecture

### 1. Gamified Ecosystem & Activity Tracking
TaskMate employs a sophisticated behavioral reinforcement loop to keep users engaged.
* **Experience (XP) Engine:** Users gain XP by completing tasks and logging Pomodoro minutes. The `GamificationService` handles level thresholds and rank progression dynamically.
* **Badge Unlock System:** Background algorithms evaluate user milestones (e.g., "Complete 100 Tasks", "Focus for 500 Minutes") and award distinct badges stored securely in Firestore.
* **GitHub-Style Heatmap:** The `ActivityService` tracks daily productivity metrics on a 365-day rolling window, parsing complex Firestore maps into a visual activity matrix for instant visual feedback on consistency.
* **Virtual Pet Companion:** A state-driven virtual pet that visually reacts to the user's current productivity velocity and task completion rates.

### 2. AI-Powered Assistant & Summarizer (AWS Bedrock)
The application leverages Large Language Models to accelerate the learning process.
* **Document Summarization:** Users can paste extensive study notes, and the `AiService` communicates with AWS Bedrock (Claude Sonnet/Haiku) to generate concise, highly readable summaries.
* **Automated Flashcards:** The LLM parses dense text and autonomously generates structured Q&A flashcards for active recall.
* **Context-Aware AI Chat:** An integrated conversational agent that acts as a tutor and productivity coach.

### 3. Advanced Task & Time Management
* **Hierarchical Task Modeling:** Support for Parent and Sub-task object models, allowing complex goals to be broken down into actionable micro-steps.
* **Pomodoro Engine:** A robust, state-managed timer adhering to the Pomodoro technique (25m work / 5m rest) that securely pipes completed focus minutes into the Gamification engine.
* **Offline Fallback Cache:** Designed for resilience. Utilizing `shared_preferences`, the `CacheService` caches stringified JSON payloads of the user's task list. If the Firestore stream throws a permission or connectivity error, the UI seamlessly falls back to the local cache.

### 4. Academic Tracking (GPA Calculator)
* **Real-time GPA Engine:** Users input Subject names, credits, and expected grades. The `GpaService` calculates the cumulative GPA dynamically using industry-standard grade point scaling (4.0 scale). Data is persisted securely within a `subjectsMap` on the user's root Firestore document to optimize reads and bypass restrictive nested collection rules.

---

## 🛠 Tech Stack

* **Frontend Framework:** Flutter (Dart)
* **Target Platform:** Web (Chrome optimized)
* **Backend & Database:** Firebase Authentication & Cloud Firestore (NoSQL)
* **State Management:** Provider / StreamBuilder
* **Artificial Intelligence:** AWS Bedrock (Anthropic Claude Family)
* **Design System:** Custom Glassmorphism Theme (Dark Mode, Blur Filters, Dynamic Opacities)

---

## 🔐 Security & Data Modeling

TaskMate's data architecture is flattened to ensure strict compliance with Firebase Security Rules while maintaining high read/write throughput. 

Instead of relying on deep subcollections which often trigger `permission-denied` faults, core user metrics (Profile data, XP, Heatmap matrices, and GPA Subjects) are serialized directly into Maps on the root `users/{uid}` document. Tasks are maintained in a dedicated `tasks` subcollection optimized for stream listening.

API Keys (AWS Bedrock) are injected at compile time via `--dart-define` environment variables, keeping secrets strictly out of the repository.

---

## 💻 Running Locally

### Prerequisites
* Flutter SDK (3.19.0+)
* Google Chrome

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/nowayitsme-eng/TaskMate-An-Ai-Powered-Productivity-Web-App.git
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run -d chrome --dart-define=BEDROCK_API_KEY="your_aws_key_here"
   ```

---
*Built with ❤️ for peak productivity.*
