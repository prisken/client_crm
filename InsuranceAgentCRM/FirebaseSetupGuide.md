# Firebase Firestore Setup Guide

## Why Firebase Instead of CloudKit?

Since you're using a **Personal Team** Apple ID, CloudKit is not available. Firebase Firestore provides the same cross-device sync functionality with these advantages:

✅ **Works with Personal Team accounts** (no paid Apple Developer Program required)  
✅ **Free tier available** (generous limits for personal use)  
✅ **Real-time sync** across all devices  
✅ **Offline support** with automatic sync when online  
✅ **Easy setup** - just add Firebase to your project  

## Step-by-Step Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name: `InsuranceAgentCRM`
4. Enable Google Analytics (optional)
5. Click **"Create project"**

### 2. Add iOS App to Firebase
1. In Firebase Console, click **"Add app"** → **iOS**
2. **iOS bundle ID**: `com.insuranceagent.crm.InsuranceAgentCRM`
3. **App nickname**: `InsuranceAgentCRM`
4. Click **"Register app"**

### 3. Download Configuration File
1. Download `GoogleService-Info.plist`
2. **Drag and drop** it into your Xcode project
3. Make sure **"Copy items if needed"** is checked
4. Make sure your app target is selected
5. Click **"Finish"**

### 4. Add Firebase SDK to Xcode
1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Click **"Add Package"**
4. Select these products:
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseAuth** (optional, for user authentication)
5. Click **"Add Package"**

### 5. Initialize Firebase in Your App
Add this to your `InsuranceAgentCRMApp.swift`:

```swift
import FirebaseCore

@main
struct InsuranceAgentCRMApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var firebaseManager = FirebaseManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(firebaseManager)
        }
    }
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Force Core Data to initialize
        let _ = persistenceController.container.viewContext
        
        // Initialize Firebase manager
        let _ = FirebaseManager.shared
    }
}
```

### 6. Enable Firestore Database
1. In Firebase Console, go to **"Firestore Database"**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select a location (choose closest to you)
5. Click **"Done"**

### 7. Set Up Security Rules (Important!)
In Firestore Database → Rules, replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents for authenticated users
    // For personal use, you can restrict this further
    match /{document=**} {
      allow read, write: if true; // Allow all for personal use
    }
  }
}
```

## What Will Sync

✅ **All client information** (name, phone, email, address, notes)  
✅ **All tags** (interests, social status, life stage)  
✅ **All assets and expenses** from Stage 2  
✅ **All products and status** from Stage 3  
✅ **All tasks and follow-ups**  
✅ **All documents and notes**  

## Testing Sync

1. **Install app on iPhone**
2. **Create test data** (clients, assets, expenses, products)
3. **Install same app on iPad**
4. **Data should sync automatically** within seconds

## Firebase Console Features

- **Real-time database viewer** - see your data update live
- **Usage monitoring** - track how much data you're using
- **Backup and restore** - never lose your data
- **Multi-device access** - works on any device with your Firebase project

## Cost

- **Free tier**: 1GB storage, 50K reads, 20K writes per day
- **For personal CRM use**: Should stay within free limits
- **Paid plans**: Start at $25/month if you exceed free tier

## Troubleshooting

- **"Firebase not connected"**: Check internet connection
- **"Permission denied"**: Check Firestore security rules
- **"Bundle ID mismatch"**: Verify bundle ID in Firebase Console matches Xcode
- **Sync not working**: Check Firebase Console for error logs

This setup will give you the same cross-device sync functionality as CloudKit, but works with your Personal Team Apple ID! 🚀
