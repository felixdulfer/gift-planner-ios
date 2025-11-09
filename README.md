# Gift Planner iOS

A SwiftUI iOS app for planning and organizing gifts for events, built with Firebase Authentication and Firestore.

## Features

- 🔐 User authentication with Firebase Auth
- 📅 Create and manage events
- 🎁 Create wishlists for events
- 💝 Add gift suggestions to wishlists
- 👥 Invite users to events
- ⭐ Mark gifts as favorites
- ✅ Track purchased gifts

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.0+
- Firebase account

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/felixdulfer/gift-planner-ios.git
cd gift-planner-ios
```

### 2. Install Dependencies

1. Open `gift-planner-ios.xcodeproj` in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter: `https://github.com/firebase/firebase-ios-sdk`
4. Select: **FirebaseAuth**, **FirebaseFirestore**, **FirebaseCore**
5. Click **Add Package**

### 3. Set Up Firebase Configuration

#### Option A: Download GoogleService-Info.plist (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click **Add App** → **iOS**
4. Enter your bundle identifier: `com.example.gift-planner-ios`
5. Download the `GoogleService-Info.plist` file
6. **Important**: Place it in the `gift-planner-ios/` folder:
   ```
   gift-planner-ios/
   └── GoogleService-Info.plist
   ```
7. In Xcode, right-click the `gift-planner-ios` folder → **Add Files to "gift-planner-ios"...**
8. Select `GoogleService-Info.plist` and ensure your app target is checked

### 4. Configure Firebase

Follow the detailed setup instructions in [FIREBASE_SETUP.md](./FIREBASE_SETUP.md):

- Enable Email/Password authentication
- Set up Firestore database
- Deploy Firestore indexes
- Configure security rules

### 5. Deploy Firestore Indexes

The app requires composite indexes for Firestore queries. Deploy them using Firebase CLI:

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy indexes
firebase deploy --only firestore:indexes
```

Or click the URL provided in error messages when running the app.

### 6. Build and Run

1. Select your target device or simulator in Xcode
2. Press **⌘R** to build and run

## Environment Variables & Secrets

### Why GoogleService-Info.plist is Not in Git

The `GoogleService-Info.plist` file contains sensitive Firebase configuration (API keys, project IDs, etc.) and is excluded from version control via `.gitignore` for security reasons.

**⚠️ Important**: Each developer must obtain their own `GoogleService-Info.plist` file from Firebase Console.

### Managing Secrets Locally

#### Using .env File (Optional)

For local development, you can create a `.env` file (already in `.gitignore`):

```bash
# Create .env file
cat > .env << EOF
FIREBASE_API_KEY=your-api-key
FIREBASE_PROJECT_ID=gift-planner-ios
FIREBASE_BUNDLE_ID=com.example.gift-planner-ios
FIREBASE_STORAGE_BUCKET=gift-planner-ios.firebasestorage.app
FIREBASE_GCM_SENDER_ID=563071008569
FIREBASE_GOOGLE_APP_ID=1:563071008569:ios:1faf664063ee2288d8b2e8
EOF
```

**Note**: iOS apps cannot directly read `.env` files at runtime. You would need a build script to generate `GoogleService-Info.plist` from environment variables. The recommended approach is to simply download the file from Firebase Console.

### For Team Members

When cloning the repository:

1. **Download** `GoogleService-Info.plist` from Firebase Console:
   - Go to Firebase Console → Your Project → Project Settings
   - Under "Your apps", find your iOS app
   - Click "Download GoogleService-Info.plist"
2. **Place** it in `gift-planner-ios/` folder (same level as `ContentView.swift`)
3. **Add** it to your Xcode project:
   - Right-click `gift-planner-ios` folder in Xcode
   - Select "Add Files to 'gift-planner-ios'..."
   - Choose `GoogleService-Info.plist`
   - Ensure "Copy items if needed" is checked
   - Verify your app target is selected

The file is already in `.gitignore`, so it won't be committed accidentally.

## Project Structure

```
gift-planner-ios/
├── gift-planner-ios/
│   ├── Models/          # Data models (Event, Wishlist, GiftSuggestion, User)
│   ├── Services/        # Firebase services (AuthService, FirestoreService)
│   ├── Views/           # SwiftUI views
│   │   ├── Auth/       # Login and Sign Up views
│   │   ├── Events/     # Event management views
│   │   ├── Gifts/      # Gift suggestion views
│   │   └── Wishlists/  # Wishlist views
│   └── Utilities/      # Helper utilities
├── firebase.json        # Firebase project configuration
├── firestore.rules      # Firestore security rules
├── firestore.indexes.json # Firestore composite indexes
└── FIREBASE_SETUP.md    # Detailed Firebase setup guide
```

## Troubleshooting

### "No such module 'FirebaseCore'"

1. In Xcode, go to **File** → **Packages** → **Resolve Package Versions**
2. Wait for packages to resolve
3. Clean build folder: **Product** → **Clean Build Folder** (⇧⌘K)
4. Build again: **⌘B**

### "The query requires an index"

Deploy Firestore indexes using Firebase CLI:
```bash
firebase deploy --only firestore:indexes
```

Or click the URL in the error message to create the index in Firebase Console.

### App takes forever to start

The app has been optimized to use cached authentication state. If startup is still slow:
- Check your network connection
- Verify Firebase configuration is correct
- Ensure `GoogleService-Info.plist` is properly added to your Xcode target

### GoogleService-Info.plist not found

1. Download it from Firebase Console (see setup instructions above)
2. Ensure it's in the `gift-planner-ios/` folder
3. Verify it's added to your Xcode target:
   - Select the file in Xcode
   - Check the "Target Membership" in the File Inspector (right panel)

### Haptic feedback errors in Simulator

These are harmless warnings. The iOS Simulator doesn't have haptic hardware, so keyboard haptic feedback fails. This doesn't affect app functionality and won't appear on real devices.

## Development

### Code Style

- Follow Swift naming conventions
- Use SwiftUI for UI
- Keep views focused and composable
- Use async/await for asynchronous operations

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[Add your license here]

## Support

For issues and questions:
- Open an issue on GitHub
- Check [FIREBASE_SETUP.md](./FIREBASE_SETUP.md) for Firebase-specific setup help

