# 🚀 Full Stack Project Setup Guide

## 📦 1. Backend Setup (Node.js + Express)

### 🔧 Environment Configuration
1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```

2. Create a `.env` file in the root folder and add:
   ```env
   PORT=5000
   MONGO_URI=your_mongodb_uri
   JWT_SECRET=your_jwt_secret_key
   CLIENT_ORIGIN=http://localhost:3000
   ```

### ▶️ Run Backend
```bash
npm install
npm run dev
```

---

## 📱 2. Frontend Setup (Flutter)

### ⚙️ Requirements
- Install and configure Flutter SDK

### ▶️ Run App
1. Navigate to the `frontend` directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Start the app:
   ```bash
   flutter run
   ```

---

## 🏗️ 3. Project Architecture

This project follows a **decoupled architecture**, separating backend and frontend for scalability and maintainability.

### 🔙 Backend
- Built with **Node.js & Express**
- Handles API requests
- Uses **JWT authentication**

### 🗄️ Database
- **MongoDB**
- Flexible, document-based storage

### 📲 Frontend
- Built with **Flutter**
- Cross-platform mobile application

---

## ✅ Notes
- Ensure MongoDB is running or use MongoDB Atlas
- Update `.env` values before running the backend
- Backend must be running before starting the frontend
