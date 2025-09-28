# Insurance Agent CRM

A comprehensive Customer Relationship Management system for insurance agents, built with SwiftUI and Firebase.

## 🔧 Architecture

### **Core Technologies**
- **SwiftUI** - Modern iOS user interface framework
- **Core Data** - Local data persistence and management
- **Firebase Firestore** - Cloud database with real-time synchronization
- **Firebase Auth** - User authentication and management

### **Key Features**
- ✅ **User Authentication** - Secure Firebase Auth integration
- ✅ **Client Management** - Complete client lifecycle management
- ✅ **Product Management** - Insurance product catalog and tracking
- ✅ **Task Management** - Task creation, tracking, and completion
- ✅ **Data Synchronization** - Real-time sync across devices
- ✅ **User Isolation** - Complete data privacy and security

## 🔒 Security & Privacy

### **User-Based Data Isolation**
- Each user has completely isolated data space
- Firebase collections structured as: `/users/{uid}/collection/{id}`
- No cross-user data access possible
- Proper authentication required for all operations

### **Data Structure**
```
/users/{firebaseUID}/
├── clients/{clientId}
├── assets/{assetId}
├── expenses/{expenseId}
├── products/{productId}
├── standalone_products/{productId}
├── tasks/{taskId}
└── standalone_tasks/{taskId}
```

## 📱 Core Components

### **Authentication System**
- `AuthenticationManager` - Handles user authentication and session management
- Firebase Auth integration with Core Data user synchronization
- Secure token management and user session persistence

### **Data Synchronization**
- `FirebaseManager` - Manages all Firebase operations
- Real-time data sync between local Core Data and Firebase
- User-specific collection management
- Automatic conflict resolution

### **User Interface**
- `DashboardView` - Main dashboard with statistics and controls
- `ClientsView` - Client management and filtering
- `TasksView` - Task management and tracking
- `ProductsView` - Product catalog management

## 🚀 Getting Started

### **Prerequisites**
- Xcode 15.0+
- iOS 17.0+
- Firebase project setup
- GoogleService-Info.plist configured

### **Setup**
1. Clone the repository
2. Open `InsuranceAgentCRM.xcodeproj` in Xcode
3. Configure Firebase project settings
4. Add `GoogleService-Info.plist` to the project
5. Build and run on device or simulator

### **Firebase Configuration**
1. Create Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Firestore Database
3. Enable Authentication (Email/Password)
4. Download `GoogleService-Info.plist`
5. Add to Xcode project

## 🧪 Testing

### **System Validation**
- User authentication flow testing
- Data synchronization validation
- User isolation verification
- Firebase structure validation

### **Test Scenarios**
1. Create multiple user accounts
2. Verify complete data isolation
3. Test cross-device synchronization
4. Validate Firebase collection structure

## 📊 Data Models

### **Core Entities**
- `Client` - Client information and details
- `Asset` - Client asset information
- `Expense` - Client expense tracking
- `ClientProduct` - Client-specific products
- `Product` - General product catalog
- `Task` - Task management
- `ClientTask` - Client-specific tasks

## 🔧 Development

### **Code Organization**
```
InsuranceAgentCRM/
├── Core/
│   ├── Managers/          # Business logic managers
│   └── Services/          # External service integrations
├── Views/                 # SwiftUI views
├── ViewModels/           # View model classes
├── Utils/                # Utility classes and helpers
└── Resources/            # Assets and configuration
```

### **Key Design Patterns**
- **MVVM Architecture** - Clean separation of concerns
- **Singleton Pattern** - Shared managers (FirebaseManager, AuthenticationManager)
- **Observer Pattern** - @Published properties for reactive UI
- **Repository Pattern** - Data access abstraction

## 🛡️ Security Best Practices

### **Firebase Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### **Data Protection**
- All data encrypted in transit (HTTPS)
- User authentication required for all operations
- Complete data isolation between users
- No shared collections or cross-user access

## 📈 Performance

### **Optimizations**
- Efficient Core Data queries with proper predicates
- Firebase batch operations for bulk data sync
- Lazy loading for large data sets
- Optimized UI updates with @Published properties

### **Memory Management**
- Proper object lifecycle management
- Weak references to prevent retain cycles
- Efficient Core Data context usage
- Background processing for heavy operations

## 🚀 Deployment

### **Production Checklist**
- [ ] Firebase security rules configured
- [ ] Authentication methods enabled
- [ ] Error handling implemented
- [ ] Performance testing completed
- [ ] User isolation verified
- [ ] Data sync validation passed

### **App Store Preparation**
- [ ] App icons and launch screens configured
- [ ] Privacy policy and terms of service
- [ ] App Store metadata completed
- [ ] Screenshots and app previews
- [ ] Beta testing completed

## 📞 Support

For technical support or questions about the Insurance Agent CRM system, please refer to the documentation or contact the development team.

---

**Built with ❤️ for insurance professionals**