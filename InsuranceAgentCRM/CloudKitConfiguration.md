# CloudKit Configuration Guide

## Required Xcode Setup

### 1. Enable CloudKit Capability
1. Open your project in Xcode
2. Select your app target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "CloudKit"
6. Select your CloudKit container or create a new one with identifier: `iCloud.com.insuranceagent.crm.InsuranceAgentCRM`

### 2. Core Data Model Configuration
Ensure your Core Data model has the following settings for each entity:

#### Required for CloudKit Sync:
- **Client**: ✅ Configured
  - `id` (UUID, Required)
  - `createdAt` (Date, Required) 
  - `updatedAt` (Date, Required)
  - `firstName`, `lastName`, `email`, `phone` (String, Optional)
  - `interests`, `socialStatus`, `lifeStage` (Transformable, Optional)

- **Asset**: ✅ Configured
  - `id` (UUID, Required)
  - `createdAt` (Date, Required)
  - `updatedAt` (Date, Required)
  - `name`, `type`, `assetDescription` (String, Optional)
  - `amount` (Decimal, Optional)

- **Expense**: ✅ Configured
  - `id` (UUID, Required)
  - `createdAt` (Date, Required)
  - `updatedAt` (Date, Required)
  - `name`, `type`, `frequency`, `assetDescription` (String, Optional)
  - `amount` (Decimal, Optional)

- **ClientProduct**: ✅ Configured
  - `id` (UUID, Required)
  - `createdAt` (Date, Required)
  - `updatedAt` (Date, Required)
  - `name`, `category`, `status`, `coverage`, `assetDescription` (String, Optional)
  - `amount`, `premium` (Decimal, Optional)

- **User**: ✅ Configured
  - `id` (UUID, Required)
  - `createdAt` (Date, Required)
  - `updatedAt` (Date, Required)
  - `email`, `role`, `passwordHash` (String, Optional)

### 3. CloudKit Dashboard Setup
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container: `iCloud.com.insuranceagent.crm.InsuranceAgentCRM`
3. The schema will be automatically created when you first run the app
4. Verify all entities are present in the "Schema" section

### 4. Testing Sync
1. Install app on iPhone
2. Create some test data (clients, assets, expenses, products)
3. Install same app on iPad using same Apple ID
4. Sign in with same credentials
5. Data should sync automatically within minutes

### 5. Troubleshooting
- **No sync**: Check iCloud account status in Settings
- **Partial sync**: Ensure all devices are signed into same Apple ID
- **Slow sync**: Initial sync can take several minutes for large datasets
- **Sync errors**: Check CloudKit Dashboard for quota limits

## What Syncs Automatically:
✅ All client information and personal details
✅ All tags (interests, social status, life stage)
✅ All assets and expenses from Stage 2
✅ All products and their status from Stage 3
✅ All tasks and follow-ups
✅ All documents and notes
✅ User authentication data
✅ All custom tags created by users

## Sync Behavior:
- **Real-time**: Changes sync within seconds to minutes
- **Offline**: Works offline, syncs when connection restored
- **Conflict Resolution**: Last write wins (NSMergeByPropertyObjectTrumpMergePolicy)
- **Initial Sync**: Can take 5-15 minutes for large datasets
- **Background**: Syncs automatically when app is backgrounded
