# FYPApp - NeuroCompanion Mental Health Companion

A comprehensive full-stack mental health companion application featuring a **React web app**, **Flutter mobile app**, and **Node.js backend**. Built for ADHD support and general wellness, with AI-powered emotion recognition, task management, therapeutic voice assistant, and adaptive UI.

## 🏗️ Project Structure

```
FYPApp/
├── /backend          → Express + MongoDB + AI Integration
│   ├── /config
│   │   └── db.js
│   ├── /controllers
│   │   └── authController.js
│   ├── /middleware
│   │   └── auth.js
│   ├── /models
│   │   └── User.js
│   ├── /routes
│   │   ├── authRoutes.js
│   │   ├── emotionRoutes.js
│   │   ├── emotionHistoryRoutes.js
│   │   ├── taskRoutes.js
│   │   ├── journalRoutes.js
│   │   ├── preferencesRoutes.js
│   │   └── wellnessRoutes.js
│   ├── server.js
│   ├── package.json
│   └── env.example
├── /frontend         → React (Vite) Web Application
│   ├── /src
│   │   ├── /components
│   │   ├── /pages
│   │   ├── /context
│   │   ├── /utils
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── package.json
│   ├── vite.config.js
│   └── tailwind.config.js
├── /neurocompanion_flutter  → Flutter Mobile Application
│   ├── /lib
│   │   ├── /bloc
│   │   ├── /models
│   │   ├── /providers
│   │   ├── /screens
│   │   ├── /services
│   │   ├── /widgets
│   │   └── main.dart
│   ├── /android
│   ├── /ios
│   ├── /web
│   ├── /windows
│   ├── /linux
│   ├── /macos
│   ├── pubspec.yaml
│   └── README.md
└── README.md
```

## 🚀 Quick Start

### 1. Backend Setup
```bash
cd backend
npm install
cp env.example .env
# Edit .env with your MongoDB URI and JWT secret
npm run dev
```
Backend runs on: http://localhost:5000

### 2. Frontend (Web) Setup
```bash
cd frontend
npm install
npm run dev
```
Frontend runs on: http://localhost:5556

### 3. Flutter Mobile App Setup
```bash
cd neurocompanion_flutter
flutter pub get
flutter run
```
Or use the provided batch files:
- Windows: `run_app.bat`
- Setup: `setup_path.ps1`

### 4. Environment Setup
Create a `.env` file in the backend directory with:
```
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
PORT=5000
GEMINI_API_KEY=your_gemini_api_key
```

## 🛠️ Tech Stack

### Backend
- **Node.js + Express** - Server framework
- **MongoDB Atlas** - Cloud database
- **JWT Authentication** - Secure token-based auth
- **bcryptjs** - Password hashing
- **CORS** - Cross-origin resource sharing
- **Mongoose** - MongoDB object modeling
- **Gemini AI API** - Emotion recognition and therapeutic responses
- **Multer** - File upload handling

### Frontend (Web)
- **React (Vite)** - Fast development and building
- **TailwindCSS** - Utility-first CSS framework
- **Framer Motion** - Animation library
- **Axios** - HTTP client for API calls
- **React Router DOM** - Client-side routing
- **Lucide React** - Beautiful icons
- **@dnd-kit** - Drag and drop functionality
- **Recharts** - Data visualization
- **React Toastify** - Notifications

### Mobile App (Flutter)
- **Flutter** - Cross-platform mobile framework
- **Flutter BLoC** - State management
- **Provider** - Dependency injection
- **HTTP** - API communication
- **Shared Preferences** - Local storage
- **Image Picker** - Photo selection
- **Flutter Local Notifications** - Push notifications

## 📋 Core Features

### 🔐 Authentication System
- ✅ **User Registration** - Create new accounts with validation
- ✅ **User Login** - Secure authentication with JWT
- ✅ **Protected Routes** - Dashboard access control
- ✅ **Token Management** - Automatic token refresh and storage

### 🎭 Emotion Recognition & Analysis
- ✅ **AI-Powered Emotion Detection** - Upload images for emotion analysis
- ✅ **Manual Emotion Selection** - Choose emotions manually
- ✅ **Adaptive Theme Switching** - UI adapts based on detected emotions
- ✅ **Emotion History Tracking** - Store and visualize emotional patterns
- ✅ **Confidence Scoring** - AI confidence levels for emotion detection

### 📋 Task Scheduling & Management
- ✅ **Drag & Drop Interface** - Intuitive task organization
- ✅ **Priority System** - High, medium, low priority tasks
- ✅ **Due Date Management** - Time-based task scheduling
- ✅ **Nudging System** - Smart reminders and notifications
- ✅ **Task History Analytics** - Completion statistics and trends
- ✅ **Weekly Completion Charts** - Visual progress tracking

### 🧠 Therapeutic Voice Assistant
- ✅ **AI-Powered Responses** - Dr. Sarah, your mental health companion
- ✅ **Empathetic Guidance** - Professional therapeutic support
- ✅ **Real-time Chat** - Instant responses to mental health concerns
- ✅ **Quick Response Buttons** - Pre-made therapeutic prompts
- ✅ **Voice Input Support** - Microphone integration ready

### 🎨 Adaptive UI Engine
- ✅ **6 Theme System** - Ocean, Coral, Midnight, Mint, Lavender, Golden
- ✅ **Emotion-Based Themes** - Automatic theme switching
- ✅ **Font Customization** - Size and style adjustments
- ✅ **Smooth Transitions** - Framer Motion animations
- ✅ **Persistent Settings** - localStorage integration

### 📊 Analytics & Insights
- ✅ **Emotion Trend Charts** - Weekly emotional patterns
- ✅ **Task Completion Stats** - Productivity metrics
- ✅ **Mood Distribution** - Emotional state visualization
- ✅ **AI Insights** - Personalized recommendations

### 📝 Journaling & Wellness
- ✅ **Digital Journal** - Rich text editor with mood analysis
- ✅ **Entry Management** - Save, edit, delete journal entries
- ✅ **Sleep Tracking** - Sleep schedule management
- ✅ **Breathing Exercises** - Guided relaxation techniques
- ✅ **Wellness Reminders** - Persistent nudge system

### 👥 Caregiver Dashboard
- ✅ **Progress Reports** - User activity summaries
- ✅ **Emotion Trends** - Caregiver insights
- ✅ **Task Completion** - Productivity tracking
- ✅ **AI Recommendations** - Personalized suggestions

## 📝 API Endpoints

### Authentication Routes
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (protected)

### Emotion Analysis Routes
- `POST /api/emotion/analyze` - Analyze emotion from image
- `POST /api/emotions/history` - Log emotion entry
- `GET /api/emotions/history/:userId` - Get emotion history
- `GET /api/emotions/history/:userId/chart` - Get chart data

### Task Management Routes
- `POST /api/tasks/create` - Create new task
- `GET /api/tasks/:userId` - Get user tasks
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task
- `GET /api/tasks/:userId/due` - Get due tasks
- `PUT /api/tasks/:id/nudge` - Mark task as nudged

### Utility Routes
- `GET /api/health` - Health check endpoint

## 🔐 Security Features

- **Password Hashing** - bcrypt with salt rounds
- **JWT Tokens** - Secure token-based authentication
- **CORS Protection** - Configured for frontend origin
- **Input Validation** - Server-side validation
- **Error Handling** - Secure error responses
- **File Upload Security** - Image validation and size limits

## 🎨 UI/UX Features

- **Modern Design** - Clean, professional interface
- **Smooth Animations** - Framer Motion powered
- **Responsive Layout** - Works on all devices
- **Loading States** - User feedback during operations
- **Form Validation** - Real-time validation feedback
- **Accessibility** - Proper ARIA labels and keyboard navigation
- **Theme System** - Multiple color schemes
- **Drag & Drop** - Intuitive task management

## 🧪 Testing the Application

1. **Start both servers** (backend on port 5000, frontend on port 5556)
2. **Visit** http://localhost:5556
3. **Register** a new account
4. **Login** with your credentials
5. **Explore** all features:
   - Upload images for emotion analysis
   - Create and manage tasks with drag & drop
   - Chat with the therapeutic voice assistant
   - Customize themes and settings
   - View analytics and insights

## 📦 Installation Commands

### Backend Dependencies
```bash
npm install express mongoose dotenv cors bcryptjs jsonwebtoken multer node-fetch
npm install -D nodemon
```

### Frontend (Web) Dependencies
```bash
npm install axios react-router-dom tailwindcss lucide-react framer-motion @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities recharts react-toastify
npx tailwindcss init -p
```

### Flutter Mobile App Dependencies
```bash
cd neurocompanion_flutter
flutter pub get
```

## 🔧 Development Commands

### Backend
```bash
npm run dev    # Start development server with nodemon
npm start      # Start production server
```

### Frontend (Web)
```bash
npm run dev    # Start Vite development server
npm run build  # Build for production
npm run preview # Preview production build
```

### Flutter Mobile App
```bash
flutter run                    # Run on connected device/emulator
flutter run -d chrome          # Run on web
flutter build apk             # Build Android APK
flutter build ios             # Build iOS app
flutter build web             # Build web version
```

## 🌟 Key Features Implemented

1. **Complete Authentication Flow** - Registration, login, logout
2. **AI-Powered Emotion Recognition** - Image analysis with Gemini API
3. **Adaptive UI System** - Dynamic theme switching
4. **Task Management** - Drag & drop with analytics
5. **Therapeutic Voice Assistant** - AI mental health companion
6. **Comprehensive Analytics** - Charts and insights
7. **Journaling System** - Digital diary with mood tracking
8. **Caregiver Dashboard** - Progress monitoring
9. **Wellness Features** - Sleep tracking and breathing exercises
10. **Modern Animations** - Smooth user interactions

## 🚀 Ready for Production

The application is production-ready with:
- Environment variable configuration
- Error handling and logging
- Security best practices
- Clean, maintainable code
- Comprehensive documentation
- AI integration
- Real-time features
- Responsive design

## 🤖 AI Integration

- **Gemini Vision API** - Emotion detection from images
- **Gemini Text API** - Therapeutic conversation responses
- **Real-time Processing** - Instant AI responses
- **Confidence Scoring** - AI accuracy metrics
- **Adaptive Learning** - Context-aware responses

## 📱 Mobile Applications

### Flutter Mobile App
- **Cross-Platform** - iOS, Android, Web, Windows, macOS, Linux
- **Native Performance** - Smooth animations and interactions
- **Offline Support** - Local data caching
- **Push Notifications** - Task reminders and wellness alerts
- **Camera Integration** - Direct photo capture for emotion analysis
- **Adaptive Themes** - Same theme system as web app
- **BLoC Architecture** - Clean state management

### Web App Mobile Responsive
- **Mobile-First Design** - Optimized for all devices
- **Touch Interactions** - Drag & drop on mobile
- **Responsive Charts** - Adaptive data visualization
- **Mobile Navigation** - Bottom navigation bar
- **Touch-Friendly UI** - Large buttons and inputs

## 🎯 Platform Support

- ✅ **Web Application** - React/Vite (Desktop & Mobile browsers)
- ✅ **Android App** - Native Flutter application
- ✅ **iOS App** - Native Flutter application
- ✅ **Windows Desktop** - Flutter desktop support
- ✅ **macOS Desktop** - Flutter desktop support
- ✅ **Linux Desktop** - Flutter desktop support
- ✅ **Web (PWA)** - Progressive Web App support

## 🔗 Repository

**GitHub:** [https://github.com/Dervaish-dev/FYPApp](https://github.com/Dervaish-dev/FYPApp)

---

**Developed by Dervaish Ahmed** - A comprehensive mental health companion for ADHD and general wellness support.

**Final Year Project (FYP)** - Full-stack application with web and mobile clients.