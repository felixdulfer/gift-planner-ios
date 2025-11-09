# Firebase Setup Guide

This app requires Firebase Authentication and Firestore to be configured. Follow these steps to set up Firebase:

## 1. Add Firebase SDK Dependencies

1. Open your project in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter the Firebase iOS SDK URL: `https://github.com/firebase/firebase-ios-sdk`
4. Select the following packages:
   - **FirebaseAuth**
   - **FirebaseFirestore**
   - **FirebaseCore**

## 2. Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project** or select an existing project
3. Follow the setup wizard

## 3. Add iOS App to Firebase

1. In Firebase Console, click **Add App** → **iOS**
2. Enter your bundle identifier (found in your Xcode project settings)
3. Download the `GoogleService-Info.plist` file
4. Add the `GoogleService-Info.plist` file to your Xcode project:
   - Drag it into the `gift-planner-ios` folder in Xcode
   - Make sure "Copy items if needed" is checked
   - Make sure your app target is selected

## 4. Enable Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Email/Password** authentication

## 5. Set Up Firestore

1. In Firebase Console, go to **Firestore Database**
2. Click **Create Database**
3. Start in **test mode** for development (you can set up security rules later)
4. Choose a location for your database

## 6. Firestore Security Rules (Recommended)

For production, update your Firestore security rules. Here's a basic set:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Events: members can read, edit, delete
    match /events/{eventId} {
      allow read: if request.auth != null && request.auth.uid in resource.data.memberIds;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.createdBy;
      allow update, delete: if request.auth != null && request.auth.uid in resource.data.memberIds;
    }

    // Wishlists: event members can read, edit, delete
    match /wishlists/{wishlistId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }

    // Gift suggestions: event members can read, edit, delete
    match /giftSuggestions/{suggestionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }
  }
}
```

**Note:** The rules above are permissive for development. For production, you should add more specific checks to ensure users can only access events they're members of.

## 7. Firestore Indexes

The app requires a composite index for querying events. The index configuration is already included in `firestore.indexes.json`.

### Required Index for Events

The app queries events using:

- `whereField("memberIds", arrayContains: userId)` - filters events where the user is a member
- `order(by: "createdAt", descending: true)` - orders by creation date

### Using Firebase CLI (Recommended)

1. **Install Firebase CLI** (if not already installed):

   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:

   ```bash
   firebase login
   ```

3. **Initialize Firebase** (if not already initialized):

   ```bash
   firebase init firestore
   ```

   - Select your Firebase project
   - Use existing `firestore.indexes.json` file (already configured)

4. **Deploy the index**:

   ```bash
   firebase deploy --only firestore:indexes
   ```

   This will create the composite index in your Firebase project. The index will be built automatically (takes 2-5 minutes).

### Alternative Methods

**Method 1: Click the error URL:**

- When you see the error message in Xcode console, click the URL provided in the error. It will open Firebase Console with the index pre-configured.

**Method 2: Manual creation:**

- Go to [Firebase Console](https://console.firebase.google.com/)
- Navigate to **Firestore Database** → **Indexes** → **Composite**
- Click **Create Index**
- Configure as follows:
  - **Collection ID:** `events`
  - **Fields to index:**
    - `memberIds` - Array
    - `createdAt` - Descending
  - Click **Create**

**Note:** Index creation can take a few minutes. The app will work once the index is built.

## 8. Build and Run

After completing the above steps, build and run your app. The Firebase SDK will automatically initialize when the app launches.

## Troubleshooting

- **"FirebaseApp.configure() failed"**: Make sure `GoogleService-Info.plist` is added to your project and included in your app target
- **Authentication errors**: Verify Email/Password authentication is enabled in Firebase Console
- **Firestore permission errors**: Check your security rules and ensure you're authenticated
- **"The query requires an index"**: Deploy the index using Firebase CLI (`firebase deploy --only firestore:indexes`), click the URL in the error message, or create it manually in Firebase Console (see section 7 above). Wait a few minutes for the index to build before running the query again.
