1. Backend Setup
The backend requires environment variables to connect to the database and handle authentication.

Navigate to the backend directory.

Create a file named .env in the root of the backend folder.

Add the following variables to the file:

កំណាត់កូដ
PORT=5000
MONGO_URI=your_mongodb_uri
JWT_SECRET=your_jwt_secret_key
CLIENT_ORIGIN=http://localhost:3000
Install dependencies and start the development server:

Bash
npm install
npm run dev
2. Frontend Setup (Flutter)
Ensure you have the Flutter SDK installed and configured on your system.

Navigate to the frontend directory.

Fetch the required packages:

Bash
flutter pub get
Launch the application:

Bash
flutter run
3. Project Architecture
This project utilizes a decoupled architecture to separate concerns between data management and the user interface.

Backend: Node.js & Express handling API requests and JWT authentication.

Database: MongoDB for flexible, document-based storage.

Frontend: Flutter for a cross-platform mobile experience.
