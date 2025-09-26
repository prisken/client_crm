# Insurance Agent CRM - iOS App

A comprehensive Customer Relationship Management (CRM) system designed specifically for insurance agents, built with SwiftUI and Core Data.

## Features

### 🏠 Dashboard
- Real-time overview of key metrics
- Today's priority tasks with commission optimization
- Recent activity timeline
- Monthly commission tracking

### 👥 Client Management
- Complete client profiles with contact information
- Document vault for storing client files
- Activity timeline for each client
- WhatsApp opt-in management
- Tag-based organization

### 📋 Task Management
- Follow-up workflow with customizable stages
- Commission optimization algorithm (DP Knapsack)
- Priority-based task scheduling
- Automatic task generation based on client stages
- What-if analysis for task planning

### 💬 WhatsApp Integration
- Direct messaging through WhatsApp Business API
- Message templates with variable substitution
- Delivery and read receipt tracking
- Compliance with opt-in requirements

### 📦 Product Catalog
- Insurance product management
- Quote builder with premium calculation
- Rider selection and pricing
- PDF quote generation

### 📊 Reporting & Analytics
- Client list exports (CSV, Excel, PDF)
- Monthly commission vs target reports
- Renewal rate analysis
- Follow-up conversion tracking
- Custom report builder

### 🔐 Security & Compliance
- Role-based authentication (Admin/Agent)
- Secure token storage in Keychain
- Audit trail for all data changes
- GDPR-style consent management

## Technical Architecture

### iOS App (SwiftUI)
- **UI Framework**: SwiftUI with MVVM architecture
- **Data Persistence**: Core Data with CloudKit sync
- **Authentication**: Firebase Auth with JWT tokens
- **Commission Optimization**: DP Knapsack algorithm
- **Export**: PDFKit, CSV generation, Excel support

### Serverless Backend (Node.js)
- **Runtime**: Node.js 18+ on AWS Lambda/Vercel
- **WhatsApp Integration**: Meta WhatsApp Business Cloud API
- **Authentication**: JWT token verification
- **Webhooks**: Status updates and message handling

## Commission Optimization Algorithm

The app includes a sophisticated commission optimization engine that uses a Dynamic Programming (DP) Knapsack algorithm to maximize expected commission within daily time constraints.

### Key Features:
- **Mandatory Task Handling**: Overdue tasks are automatically prioritized
- **Target-Aware Scaling**: Algorithm adjusts based on monthly target progress
- **Priority Weighting**: Business-defined priorities influence task selection
- **What-If Analysis**: Test different scenarios before committing

### Algorithm Details:
```swift
// Core optimization function
func buildTaskList(
    for date: Date,
    allOpenTasks: [Task],
    dailyHours: Double = 8.0,
    monthlyTarget: Decimal,
    earnedSoFar: Decimal
) -> OptimizerResult
```

## Installation & Setup

### Prerequisites
- Xcode 15.0+
- iOS 15.0+
- Node.js 18+ (for backend)
- WhatsApp Business API access

### iOS App Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd InsuranceAgentCRM
   ```

2. **Open in Xcode**
   ```bash
   open InsuranceAgentCRM.xcodeproj
   ```

3. **Configure CloudKit**
   - Enable CloudKit capability in Xcode
   - Set up CloudKit container
   - Configure schema in CloudKit Dashboard

4. **Configure Firebase (Optional)**
   - Add `GoogleService-Info.plist` to project
   - Enable Authentication in Firebase Console

### Backend Setup

1. **Install dependencies**
   ```bash
   cd ServerlessBackend
   npm install
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

3. **Deploy to Vercel**
   ```bash
   npm install -g vercel
   vercel --prod
   ```

### WhatsApp Business API Setup

1. **Create WhatsApp Business Account**
   - Register with Meta for Business
   - Verify your business phone number

2. **Get API Credentials**
   - Phone Number ID
   - Access Token
   - Webhook Verify Token

3. **Configure Webhook**
   - Set webhook URL: `https://your-domain.com/whatsapp/webhook`
   - Subscribe to message statuses

## Database Schema

### Core Entities
- **User**: Authentication and role management
- **Client**: Customer information and preferences
- **Task**: Follow-up tasks with optimization data
- **Product**: Insurance products and pricing
- **Quote**: Client quotes and proposals
- **WhatsAppMessage**: Message history and status
- **AuditLog**: Compliance and change tracking

### Relationships
- One-to-many relationships between entities
- Proper foreign key constraints
- Cascade delete for data integrity

## API Endpoints

### WhatsApp Integration
```
POST /whatsapp/send
GET /whatsapp/status/{messageId}
POST /whatsapp/webhook
GET /whatsapp/templates
```

### Authentication
```
POST /auth/login
POST /auth/register
POST /auth/refresh
```

## Deployment

### iOS App Store
1. Configure App Store Connect
2. Set up provisioning profiles
3. Archive and upload build
4. Submit for review

### Backend (Vercel)
1. Connect GitHub repository
2. Configure environment variables
3. Deploy automatically on push

### WhatsApp Webhook
1. Configure webhook URL in Meta Developer Console
2. Verify webhook with your server
3. Subscribe to required events

## Testing

### Unit Tests
```bash
# Run iOS tests
xcodebuild test -scheme InsuranceAgentCRM -destination 'platform=iOS Simulator,name=iPhone 15'

# Run backend tests
cd ServerlessBackend
npm test
```

### UI Tests
- Automated UI testing with XCUITest
- Accessibility testing with VoiceOver
- Performance testing on various devices

## Performance Considerations

### iOS App
- **Core Data**: Optimized fetch requests with predicates
- **Memory**: Lazy loading for large datasets
- **UI**: SwiftUI performance best practices
- **Background**: Background app refresh for sync

### Backend
- **Caching**: Redis for frequently accessed data
- **Rate Limiting**: WhatsApp API rate limits
- **Monitoring**: Error tracking and performance metrics

## Security

### Data Protection
- **Encryption**: iOS Data Protection enabled
- **Keychain**: Secure token storage
- **HTTPS**: All API communications encrypted
- **Authentication**: JWT with secure key rotation

### Compliance
- **GDPR**: Data subject rights implementation
- **Audit Trail**: Immutable change logs
- **Consent**: WhatsApp opt-in management
- **Data Retention**: Configurable retention policies

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For technical support or questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation wiki

## Roadmap

### Phase 1 (Current)
- ✅ Core CRM functionality
- ✅ Commission optimization
- ✅ WhatsApp integration
- ✅ Basic reporting

### Phase 2 (Future)
- 🔄 AI-powered insights
- 🔄 Advanced analytics
- 🔄 Multi-language support
- 🔄 Voice call integration

### Phase 3 (Future)
- 🔄 Machine learning recommendations
- 🔄 Predictive analytics
- 🔄 Advanced automation
- 🔄 Third-party integrations

## Changelog

### Version 1.0.0
- Initial release
- Core CRM functionality
- Commission optimization algorithm
- WhatsApp Business API integration
- Comprehensive reporting system
- Role-based authentication
- CloudKit sync support

---

**Built with ❤️ for insurance professionals**


