# AWS Migration Plan - JUNKWUNK Firebase to AWS

**Document Version:** 1.0  
**Date:** November 8, 2025  
**Project:** JUNKWUNK (Marketplace for Rag Pickers)  
**Status:** Planning Phase (Not Yet Implemented)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current Firebase Architecture](#current-firebase-architecture)
3. [Proposed AWS Architecture](#proposed-aws-architecture)
4. [AWS Services to Implement](#aws-services-to-implement)
5. [Feature-by-Feature Migration](#feature-by-feature-migration)
6. [Dependencies & Packages](#dependencies--packages)
7. [Step-by-Step Migration Process](#step-by-step-migration-process)
8. [Files to Modify](#files-to-modify)
9. [AWS CLI Commands](#aws-cli-commands)
10. [Data Migration Strategy](#data-migration-strategy)
11. [Testing & Validation](#testing--validation)
12. [Rollback Plan](#rollback-plan)

---

## Executive Summary

This document outlines the complete migration strategy for JUNKWUNK from Firebase backend to AWS services. The migration will replace:

- **Firebase Authentication** → **AWS Cognito**
- **Cloud Firestore** → **Amazon DynamoDB**
- **Firebase Storage** → **Amazon S3** (replacing Google Drive)
- **Firebase Cloud Functions** → **AWS Lambda**
- **Real-time Features** → **AWS AppSync** (GraphQL)

**Migration Scope:**

- User authentication and management
- NoSQL database for users, sellers, items, carts, and orders
- Image storage (moving away from Google Drive)
- Location-based services
- Cart and order management
- Profile management

**Estimated Effort:** Large (40-60 hours of development)  
**Risk Level:** Medium (comprehensive testing required)

---

## Current Firebase Architecture

### Services Currently Used

1. **Firebase Authentication** (`firebase_auth`)

   - Email/Password authentication
   - Google Sign-In integration
   - Password reset functionality
   - Auth state management

2. **Cloud Firestore** (`cloud_firestore`)

   - User documents: `users/{userId}`
   - Seller items: `sellers/{userId}/items/{itemId}`
   - Cart: `users/{userId}/cart/{itemId}`
   - Orders: `users/{userId}/orders/{orderId}`
   - Real-time listeners and StreamBuilders

3. **Firebase Storage** (Not actively used)

   - Configured but replaced by Google Drive API

4. **Google Drive API** (`googleapis`, `googleapis_auth`)

   - Image uploads via service account
   - Public URL generation
   - File management

5. **Firebase Configuration**
   - `lib/firebase_options.dart` (platform-specific configurations)
   - `android/app/google-services.json` (Google Services config)
   - `firebase.json` (project settings)

### Current Data Structure

```
users/{userId}
  ├─ email: string
  ├─ displayName: string (optional)
  ├─ photoURL: string (optional)
  ├─ role: "buyer" | "seller"
  ├─ profileCompleted: boolean
  ├─ createdAt: timestamp
  ├─ coordinates: GeoPoint
  ├─ city: string
  └─ cart (subcollection)
       └─ cart/{itemId}
           ├─ sellerId: string
           ├─ itemId: string
           ├─ quantity: number
           └─ timestamp: timestamp

sellers/{userId}
  ├─ name: string
  ├─ email: string
  ├─ city: string
  ├─ coordinates: GeoPoint
  └─ items (subcollection)
       └─ items/{itemId}
           ├─ imageUrl: string
           ├─ categories: array
           ├─ itemTypes: array
           ├─ title: string
           ├─ description: string
           ├─ price: number
           ├─ quantity: number
           ├─ status: string
           └─ timestamp: timestamp

users/{userId}/orders
  └─ orders/{orderId}
      ├─ items: array
      ├─ totalPrice: number
      ├─ sellerLocation: GeoPoint
      ├─ status: string
      └─ timestamp: timestamp
```

---

## Proposed AWS Architecture

### AWS Services Mapping

| Firebase Service   | AWS Service                    | Purpose                             |
| ------------------ | ------------------------------ | ----------------------------------- |
| Firebase Auth      | AWS Cognito                    | User authentication & management    |
| Cloud Firestore    | Amazon DynamoDB                | NoSQL database for application data |
| Firebase Storage   | Amazon S3                      | Image/file storage                  |
| Realtime listeners | AWS AppSync + DynamoDB Streams | Real-time data subscriptions        |
| Firebase Rules     | IAM + Cognito policies         | Access control                      |

### High-Level Architecture

```
Flutter App
    ↓
AWS Cognito (Authentication)
    ↓
API Gateway (REST/GraphQL)
    ↓
Lambda Functions
    ↓
DynamoDB (Data Storage)
    ↓
S3 (Images/Files)
    ↓
CloudWatch (Logs & Monitoring)
```

### AWS Account Structure

**Prerequisite:** AWS Account set up with IAM User having:

- DynamoDB full access
- Cognito full access
- S3 full access
- Lambda full access
- API Gateway full access
- CloudFormation full access (for Infrastructure as Code)

---

## AWS Services to Implement

### 1. AWS Cognito (Authentication)

**Purpose:** Replace Firebase Authentication

**Components:**

- User Pool: For email/password and Google federated authentication
- Identity Pool: For temporary AWS credentials
- MFA support for enhanced security

**DynamoDB Alternative:** Store user profiles with Cognito integration

### 2. Amazon DynamoDB (Database)

**Purpose:** Replace Cloud Firestore

**Tables to Create:**

#### a. `Users` Table

```
Primary Key: userId (String)
Attributes:
  - email: String
  - displayName: String
  - photoURL: String
  - role: String (enum: buyer, seller)
  - profileCompleted: Boolean
  - createdAt: Number (timestamp)
  - updatedAt: Number (timestamp)
  - coordinates: Map { latitude: Number, longitude: Number }
  - city: String
  - phone: String
  - address: String
```

#### b. `Items` Table

```
Primary Key: itemId (String)
Sort Key: sellerId (String) - Global Secondary Index
Attributes:
  - sellerId: String
  - imageUrl: String
  - categories: List (StringSet)
  - itemTypes: List (StringSet)
  - title: String
  - description: String
  - price: Number
  - quantity: Number
  - status: String (enum: active, sold, pending)
  - createdAt: Number (timestamp)
  - updatedAt: Number (timestamp)
  - coordinates: Map { latitude: Number, longitude: Number }
```

#### c. `Cart` Table

```
Primary Key: userId (String)
Sort Key: itemId (String)
Attributes:
  - quantity: Number
  - sellerId: String
  - itemData: Map (denormalized for performance)
  - addedAt: Number (timestamp)
  - TTL: Number (expiry for abandoned carts - 30 days)
```

#### d. `Orders` Table

```
Primary Key: orderId (String)
Sort Key: userId (String) - Global Secondary Index
Attributes:
  - userId: String
  - sellerId: String
  - items: List (ItemReference)
  - totalPrice: Number
  - status: String (enum: pending, confirmed, shipped, delivered)
  - sellerLocation: Map { latitude: Number, longitude: Number }
  - buyerLocation: Map { latitude: Number, longitude: Number }
  - createdAt: Number (timestamp)
  - updatedAt: Number (timestamp)
  - deliveryNotes: String
```

#### e. `SellerProfiles` Table

```
Primary Key: sellerId (String)
Attributes:
  - name: String
  - email: String
  - city: String
  - coordinates: Map { latitude: Number, longitude: Number }
  - rating: Number
  - totalItems: Number
  - totalSales: Number
  - createdAt: Number (timestamp)
```

### 3. Amazon S3 (Image Storage)

**Purpose:** Replace Google Drive API for image storage

**Bucket Configuration:**

- Bucket name: `junkwunk-images-prod` (region: us-east-1)
- Public read access via Cognito-authenticated presigned URLs
- Folder structure:
  ```
  junkwunk-images-prod/
    ├─ user-profiles/{userId}/{filename}
    ├─ item-images/{itemId}/{filename}
    └─ uploads/{date}/{filename}
  ```

**Security:**

- Block public access
- Use Cognito-authenticated presigned URLs
- Enable versioning
- Set lifecycle policies for old uploads

### 4. AWS Lambda (Backend Functions)

**Functions to Create:**

| Function         | Trigger                     | Purpose                         |
| ---------------- | --------------------------- | ------------------------------- |
| `AuthHandler`    | Cognito PostAuthentication  | User initialization post-login  |
| `UserSignUp`     | Cognito PostSignUp          | Create user profile in DynamoDB |
| `ItemCreate`     | API Gateway POST /items     | Add new item to catalog         |
| `ItemList`       | API Gateway GET /items      | Fetch items with filtering      |
| `CartAdd`        | API Gateway POST /cart      | Add item to cart                |
| `CartRemove`     | API Gateway DELETE /cart    | Remove item from cart           |
| `OrderCreate`    | API Gateway POST /orders    | Create order from cart          |
| `GetUserProfile` | API Gateway GET /users/{id} | Fetch user profile              |
| `UpdateProfile`  | API Gateway PUT /users/{id} | Update user info                |
| `S3ImageUpload`  | API Gateway POST /upload    | Generate S3 presigned URL       |

### 5. AWS API Gateway (REST API)

**Endpoints to Create:**

```
Authentication:
  POST   /auth/login
  POST   /auth/signup
  POST   /auth/refresh-token
  POST   /auth/logout

Users:
  GET    /users/{userId}
  PUT    /users/{userId}
  GET    /users/{userId}/profile
  PUT    /users/{userId}/profile

Items:
  GET    /items (with filters)
  GET    /items/{itemId}
  POST   /items (seller only)
  PUT    /items/{itemId} (seller only)
  DELETE /items/{itemId} (seller only)

Cart:
  GET    /users/{userId}/cart
  POST   /users/{userId}/cart
  DELETE /users/{userId}/cart/{itemId}

Orders:
  GET    /users/{userId}/orders
  POST   /users/{userId}/orders
  GET    /orders/{orderId}

Files:
  POST   /upload/presigned-url
  GET    /images/{imageId}
```

### 6. AWS AppSync (Optional - for Real-time Features)

**Purpose:** Replace Firestore real-time listeners

**GraphQL Schema Example:**

```graphql
type User {
  userId: ID!
  email: String!
  role: String!
  profileCompleted: Boolean!
  coordinates: Coordinates
}

type Item {
  itemId: ID!
  sellerId: ID!
  title: String!
  price: Float!
  imageUrl: String
}

type Subscription {
  onCartUpdated(userId: ID!): Cart
  onItemsUpdated(category: String): [Item]
  onOrderStatusChanged(orderId: ID!): Order
}
```

---

## Feature-by-Feature Migration

### 1. Authentication

**Current Implementation:**

- Firebase Auth with email/password
- Google Sign-In
- Password reset via Firebase

**AWS Implementation:**

```
AWS Cognito User Pool:
  ├─ Email/Password auth
  ├─ MFA support
  ├─ Custom attributes (role, city, coordinates)
  └─ Google federated identity provider
```

**Files to Update:**

- `lib/screens/login_page.dart`
- `lib/main.dart`
- `lib/utils/auth_helpers.dart`
- `pubspec.yaml` (replace firebase_auth with amplify_auth)

### 2. User Profile Management

**Current Implementation:**

- Firestore: `users/{userId}`
- Multiple profile fields
- Role-based access

**AWS Implementation:**

```
DynamoDB: Users Table
  + Lambda: UpdateProfile function
  + API Gateway: PUT /users/{userId}
```

**Files to Update:**

- `lib/screens/profile/profile_setup_page.dart`
- `lib/screens/profile/profile_page.dart`
- `lib/screens/profile/edit_profile_page.dart`

### 3. Seller Dashboard & Item Management

**Current Implementation:**

- Firestore: `sellers/{userId}/items/{itemId}`
- Google Drive for images
- Real-time item listings

**AWS Implementation:**

```
DynamoDB: Items Table
  + S3: Image storage with presigned URLs
  + Lambda: ItemCreate, ItemUpdate, ItemList functions
  + AppSync: Real-time subscriptions
```

**Files to Update:**

- `lib/screens/seller/seller_dashboard1.dart`
- `lib/screens/seller/seller_dashboard.dart`
- `lib/screens/seller/summary_page.dart`
- `lib/services/google_drive_service.dart` → `lib/services/aws_s3_service.dart`

### 4. Buyer Dashboard & Browsing

**Current Implementation:**

- Firestore: Fetch from `sellers/{userId}/items`
- Real-time listeners
- Category filtering

**AWS Implementation:**

```
DynamoDB: Items Table with GSI
  + Lambda: ItemList function with filters
  + API Gateway: GET /items
  + AppSync: Real-time item updates
```

**Files to Update:**

- `lib/screens/buyer/buyer_dashboard1.dart`
- `lib/screens/buyer/buyer_dashboard.dart`
- `lib/screens/buyer/item_location.dart`

### 5. Shopping Cart

**Current Implementation:**

- Firestore: `users/{userId}/cart/{itemId}`
- Real-time cart count

**AWS Implementation:**

```
DynamoDB: Cart Table
  + Lambda: CartAdd, CartRemove functions
  + API Gateway: POST/DELETE /cart
  + TTL: Auto-cleanup after 30 days
```

**Files to Update:**

- `lib/screens/buyer/buyer_cart.dart`
- `lib/widgets/item_card.dart`

### 6. Orders

**Current Implementation:**

- Firestore: `users/{userId}/orders/{orderId}`
- Order history and status tracking

**AWS Implementation:**

```
DynamoDB: Orders Table
  + Lambda: OrderCreate, OrderStatus functions
  + API Gateway: POST /orders, GET /orders/{orderId}
```

**Files to Update:**

- `lib/screens/buyer/buyer_cart.dart` (order creation)
- New: `lib/screens/buyer/order_history.dart`

### 7. Image Management

**Current Implementation:**

- Google Drive API
- Service account authentication
- Public sharing via Drive links

**AWS Implementation:**

```
S3 Bucket: junkwunk-images-prod
  + Lambda: S3ImageUpload function
  + API Gateway: POST /upload/presigned-url
  + Cognito: Authorization
  + CloudFront: CDN for image delivery (optional)
```

**Files to Update:**

- `lib/services/google_drive_service.dart` → `lib/services/aws_s3_service.dart`
- Remove: `assets/credentials/service_account.json`
- Update: `pubspec.yaml` (remove googleapis, add aws_s3)

---

## Dependencies & Packages

### Current Firebase Dependencies (to remove)

```yaml
firebase_auth: ^5.3.4
firebase_auth_web: ^5.13.3
firebase_core: ^3.9.0
firebase_storage: ^12.3.7
cloud_firestore: ^5.6.0
googleapis: ^13.2.0
googleapis_auth: ^1.6.0
google_sign_in: ^6.2.2 # Keep for federated Cognito
```

### New AWS Dependencies (to add)

```yaml
amplify_auth_cognito: ^2.0.0 # AWS Cognito authentication
amplify_flutter: ^2.0.0 # Amplify framework
amplify_api: ^2.0.0 # REST/GraphQL API
aws_s3: ^3.0.0 # S3 operations (or use SDK)
aws_signature_v4: ^0.3.0 # AWS request signing
http: ^1.3.0 # (keep existing)
dio: ^5.3.0 # HTTP client with interceptors
uuid: ^4.5.1 # (keep existing)
shared_preferences: ^2.5.3 # (keep existing)
```

### AWS CLI Packages (Development)

```powershell
# Already installed (you confirmed this)
aws-cli/2.x.x
```

### Flutter SDK Requirements

```
Flutter: >=3.0.0
Dart: >=3.0.0 <4.0.0
```

---

## Step-by-Step Migration Process

### Phase 1: Preparation (Week 1)

#### 1.1 AWS Account Setup

```powershell
# Verify AWS CLI is configured
aws sts get-caller-identity

# Output should show your AWS account and IAM user
```

#### 1.2 Create AWS Services

- Create Cognito User Pool
- Create Cognito Identity Pool
- Create DynamoDB tables
- Create S3 bucket
- Create IAM roles and policies

#### 1.3 Create Infrastructure as Code (CloudFormation)

```powershell
# Deploy CloudFormation stack
aws cloudformation create-stack `
  --stack-name junkwunk-infrastructure `
  --template-body file://infrastructure.yaml `
  --capabilities CAPABILITY_NAMED_IAM

# Monitor stack creation
aws cloudformation describe-stacks `
  --stack-name junkwunk-infrastructure
```

### Phase 2: Backend Development (Week 2-3)

#### 2.1 Create Lambda Functions

```powershell
# For each Lambda function:
aws lambda create-function `
  --function-name junkwunk-auth-handler `
  --runtime provided.al2 `
  --role arn:aws:iam::ACCOUNT_ID:role/lambda-role `
  --handler index.handler `
  --zip-file fileb://function.zip

# Example functions to create:
# - UserSignUp
# - ItemCreate
# - ItemList
# - CartAdd
# - OrderCreate
```

#### 2.2 Create API Gateway Endpoints

```powershell
# Create REST API
aws apigateway create-rest-api `
  --name junkwunk-api `
  --description "JUNKWUNK Backend API"

# Create resources and methods for each endpoint
# Integrate with Lambda functions
```

#### 2.3 Configure DynamoDB

```powershell
# Create tables
aws dynamodb create-table `
  --table-name Users `
  --attribute-definitions AttributeName=userId,AttributeType=S `
  --key-schema AttributeName=userId,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST

# Create other tables: Items, Cart, Orders, SellerProfiles
```

### Phase 3: Frontend Migration (Week 3-4)

#### 3.1 Update Dependencies

```powershell
# Update pubspec.yaml
# Remove Firebase packages
# Add AWS/Amplify packages
flutter pub get
```

#### 3.2 Implement Authentication Service

```dart
# Create: lib/services/aws_auth_service.dart
# Replace firebase_auth calls with Amplify Auth
# Update: lib/screens/login_page.dart
# Update: lib/main.dart
```

#### 3.3 Implement Data Service

```dart
# Create: lib/services/aws_dynamodb_service.dart
# Replace Firestore queries with API Gateway calls
# Create: lib/services/aws_api_service.dart
# Handle all REST API calls
```

#### 3.4 Implement Storage Service

```dart
# Create: lib/services/aws_s3_service.dart
# Replace google_drive_service.dart
# Handle presigned URLs and uploads
```

#### 3.5 Update UI Components

- Update authentication flows
- Update data loading states
- Handle API errors
- Update real-time listeners (if using AppSync)

### Phase 4: Data Migration (Week 4)

#### 4.1 Export Firebase Data

```powershell
# Export Firestore data
firebase firestore:export export_data --export-path ./firestore_export

# Alternative: Use custom export scripts
```

#### 4.2 Transform and Import to DynamoDB

```python
# Create: scripts/migrate_data.py
# Read Firebase export
# Transform to DynamoDB format
# Insert into DynamoDB tables
```

#### 4.3 Migrate Images

```powershell
# Download from Google Drive
# Upload to S3 bucket
# Update image URLs in DynamoDB

# PowerShell script to batch upload to S3
Get-ChildItem "C:\images" | ForEach-Object {
    aws s3 cp $_.FullName "s3://junkwunk-images-prod/item-images/" `
        --recursive
}
```

### Phase 5: Testing & QA (Week 5)

#### 5.1 Unit & Integration Tests

```powershell
# Run tests
flutter test

# Add tests for AWS service calls
```

#### 5.2 User Acceptance Testing

- Test all user flows
- Verify data consistency
- Performance testing
- Load testing

#### 5.3 Security Testing

- Cognito auth flows
- API authorization
- S3 access controls
- DynamoDB permissions

### Phase 6: Deployment (Week 6)

#### 6.1 Build Production APK/Web

```powershell
flutter build apk --release
flutter build web --release
```

#### 6.2 Deploy to Production

- Update API endpoints in app
- Switch DNS/routing to AWS API
- Monitor CloudWatch logs

#### 6.3 Gradual Rollout

- Canary deployment (10% users)
- Monitor errors and performance
- Full rollout after validation

---

## Files to Modify

### Files to Create (New)

```
lib/
  ├─ services/
  │  ├─ aws_auth_service.dart         # Cognito authentication
  │  ├─ aws_dynamodb_service.dart     # DynamoDB queries
  │  ├─ aws_api_service.dart          # API Gateway REST calls
  │  ├─ aws_s3_service.dart           # S3 image operations
  │  └─ aws_config.dart               # AWS configuration
  ├─ models/
  │  ├─ aws_user.dart                 # AWS User model
  │  ├─ aws_item.dart                 # Item model for AWS
  │  ├─ aws_order.dart                # Order model
  │  └─ aws_responses.dart            # API response models
  └─ utils/
     └─ aws_exceptions.dart           # AWS error handling

scripts/
  ├─ migrate_data.py                  # Firestore→DynamoDB migration
  ├─ upload_images.ps1                # Google Drive→S3 migration
  └─ cloudformation_template.yaml     # Infrastructure as Code

docs/
  └─ AWS_MIGRATION_DETAILED.md        # Detailed API documentation
```

### Files to Modify (Major Changes)

```
lib/
  ├─ main.dart                        # Replace Firebase init with AWS init
  ├─ screens/login_page.dart          # Replace Firebase Auth with Cognito
  ├─ screens/profile/profile_setup_page.dart
  ├─ screens/profile/profile_page.dart
  ├─ screens/profile/edit_profile_page.dart
  ├─ screens/seller/seller_dashboard.dart
  ├─ screens/seller/seller_dashboard1.dart
  ├─ screens/seller/summary_page.dart
  ├─ screens/buyer/buyer_dashboard.dart
  ├─ screens/buyer/buyer_dashboard1.dart
  ├─ screens/buyer/buyer_cart.dart
  ├─ screens/buyer/item_location.dart
  ├─ widgets/item_card.dart
  └─ utils/auth_helpers.dart

pubspec.yaml                          # Update dependencies
```

### Files to Delete/Remove

```
lib/
  └─ services/google_drive_service.dart

firebase_options.dart                 # No longer needed (archive it)
android/app/google-services.json      # No longer needed (archive it)
firebase.json                         # No longer needed (archive it)
assets/credentials/service_account.json  # Remove completely
```

### Files to Keep (No Changes Needed)

```
lib/
  ├─ screens/buyer/item_location.dart (update API calls only)
  ├─ screens/seller/mediator/
  ├─ screens/buyer/mediator/
  ├─ widgets/app_bar.dart
  ├─ widgets/filter_button.dart
  ├─ widgets/image_uploader.dart
  ├─ utils/colors.dart
  ├─ utils/design_constants.dart
  └─ utils/custom_toast.dart

pubspec.yaml                          # (update sections only)
README.md
WARP.md
```

---

## AWS CLI Commands

### AWS Setup & Verification

```powershell
# 1. Verify AWS CLI installation and configuration
aws --version
aws sts get-caller-identity

# 2. Set default region and output format
aws configure set region us-east-1
aws configure set output json
```

### Cognito User Pool Setup

```powershell
# Create Cognito User Pool
$userPoolId = aws cognito-idp create-user-pool `
  --pool-name junkwunk-users `
  --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":true}}' `
  --auto-verified-attributes '["email"]' `
  --query 'UserPool.Id' `
  --output text

# Create User Pool Client (app)
aws cognito-idp create-user-pool-client `
  --user-pool-id $userPoolId `
  --client-name junkwunk-mobile `
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH

# Add Google as identity provider
# (Requires manual configuration in AWS Console or CLI setup)
```

### DynamoDB Table Creation

```powershell
# Create Users table
aws dynamodb create-table `
  --table-name Users `
  --attribute-definitions `
    AttributeName=userId,AttributeType=S `
  --key-schema `
    AttributeName=userId,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST

# Create Items table
aws dynamodb create-table `
  --table-name Items `
  --attribute-definitions `
    AttributeName=itemId,AttributeType=S `
    AttributeName=sellerId,AttributeType=S `
  --key-schema `
    AttributeName=itemId,KeyType=HASH `
  --global-secondary-indexes '[
    {
      "IndexName":"SellerIdIndex",
      "KeySchema":[
        {"AttributeName":"sellerId","KeyType":"HASH"}
      ],
      "Projection":{"ProjectionType":"ALL"},
      "ProvisionedThroughput":{"ReadCapacityUnits":10,"WriteCapacityUnits":10}
    }
  ]' `
  --billing-mode PROVISIONED `
  --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10

# Create Cart table with TTL
aws dynamodb create-table `
  --table-name Cart `
  --attribute-definitions `
    AttributeName=userId,AttributeType=S `
    AttributeName=itemId,AttributeType=S `
  --key-schema `
    AttributeName=userId,KeyType=HASH `
    AttributeName=itemId,KeyType=RANGE `
  --billing-mode PAY_PER_REQUEST

# Enable TTL on Cart table (30 days)
aws dynamodb update-time-to-live `
  --table-name Cart `
  --time-to-live-specification AttributeName=ttl,Enabled=true

# Create Orders table
aws dynamodb create-table `
  --table-name Orders `
  --attribute-definitions `
    AttributeName=orderId,AttributeType=S `
    AttributeName=userId,AttributeType=S `
  --key-schema `
    AttributeName=orderId,KeyType=HASH `
  --global-secondary-indexes '[
    {
      "IndexName":"UserIdIndex",
      "KeySchema":[
        {"AttributeName":"userId","KeyType":"HASH"}
      ],
      "Projection":{"ProjectionType":"ALL"},
      "ProvisionedThroughput":{"ReadCapacityUnits":10,"WriteCapacityUnits":10}
    }
  ]' `
  --billing-mode PROVISIONED `
  --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10

# Create SellerProfiles table
aws dynamodb create-table `
  --table-name SellerProfiles `
  --attribute-definitions `
    AttributeName=sellerId,AttributeType=S `
  --key-schema `
    AttributeName=sellerId,KeyType=HASH `
  --billing-mode PAY_PER_REQUEST
```

### S3 Bucket Setup

```powershell
# Create S3 bucket
aws s3 mb s3://junkwunk-images-prod --region us-east-1

# Block public access
aws s3api put-public-access-block `
  --bucket junkwunk-images-prod `
  --public-access-block-configuration `
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable versioning
aws s3api put-bucket-versioning `
  --bucket junkwunk-images-prod `
  --versioning-configuration Status=Enabled

# Set lifecycle policy (delete uploads older than 90 days)
aws s3api put-bucket-lifecycle-configuration `
  --bucket junkwunk-images-prod `
  --lifecycle-configuration file://lifecycle-policy.json

# Create folder structure (using empty object)
aws s3api put-object `
  --bucket junkwunk-images-prod `
  --key "user-profiles/"

aws s3api put-object `
  --bucket junkwunk-images-prod `
  --key "item-images/"

# Enable CORS (for web uploads)
aws s3api put-bucket-cors `
  --bucket junkwunk-images-prod `
  --cors-configuration file://cors-config.json
```

### Lambda Function Deployment

```powershell
# Create IAM role for Lambda
$lambdaRole = aws iam create-role `
  --role-name lambda-junkwunk-role `
  --assume-role-policy-document file://lambda-trust-policy.json `
  --query 'Role.Arn' `
  --output text

# Attach policies
aws iam attach-role-policy `
  --role-name lambda-junkwunk-role `
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam attach-role-policy `
  --role-name lambda-junkwunk-role `
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# Create Lambda function
aws lambda create-function `
  --function-name junkwunk-user-signup `
  --runtime python3.11 `
  --role $lambdaRole `
  --handler index.handler `
  --zip-file fileb://function.zip `
  --timeout 30 `
  --memory-size 256 `
  --environment Variables="{TABLE_NAME=Users}"

# Update function code
aws lambda update-function-code `
  --function-name junkwunk-user-signup `
  --zip-file fileb://updated-function.zip

# Invoke function for testing
aws lambda invoke `
  --function-name junkwunk-user-signup `
  --payload file://test-event.json `
  response.json

cat response.json
```

### API Gateway Setup

```powershell
# Create REST API
$apiId = aws apigateway create-rest-api `
  --name junkwunk-api `
  --description "JUNKWUNK Mobile App API" `
  --query 'id' `
  --output text

# Get root resource ID
$rootId = aws apigateway get-resources `
  --rest-api-id $apiId `
  --query 'items[0].id' `
  --output text

# Create resource: /items
$itemsId = aws apigateway create-resource `
  --rest-api-id $apiId `
  --parent-id $rootId `
  --path-part items `
  --query 'id' `
  --output text

# Create GET /items method
aws apigateway put-method `
  --rest-api-id $apiId `
  --resource-id $itemsId `
  --http-method GET `
  --authorization-type AWS_IAM

# Integrate with Lambda
aws apigateway put-integration `
  --rest-api-id $apiId `
  --resource-id $itemsId `
  --http-method GET `
  --type AWS_PROXY `
  --integration-http-method POST `
  --uri arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:ACCOUNT_ID:function:junkwunk-item-list/invocations

# Deploy API
aws apigateway create-deployment `
  --rest-api-id $apiId `
  --stage-name prod `
  --description "Production deployment"
```

### CloudWatch Monitoring

```powershell
# View Lambda logs
aws logs tail /aws/lambda/junkwunk-user-signup --follow

# Set up CloudWatch alarms
aws cloudwatch put-metric-alarm `
  --alarm-name lambda-errors-high `
  --alarm-description "Alert when Lambda errors exceed threshold" `
  --metric-name Errors `
  --namespace AWS/Lambda `
  --statistic Sum `
  --period 300 `
  --threshold 10 `
  --comparison-operator GreaterThanThreshold `
  --evaluation-periods 1
```

### Batch Operations

```powershell
# List all DynamoDB tables
aws dynamodb list-tables

# Describe table structure
aws dynamodb describe-table --table-name Users

# Scan table (get sample data)
aws dynamodb scan --table-name Users --limit 10

# Query table
aws dynamodb query `
  --table-name Items `
  --index-name SellerIdIndex `
  --key-condition-expression "sellerId = :sellerId" `
  --expression-attribute-values "{\":sellerId\":{\"S\":\"user-123\"}}"

# Enable DynamoDB Streams
aws dynamodb update-table `
  --table-name Items `
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES
```

---

## Data Migration Strategy

### Step 1: Export Firebase Data

```powershell
# Export Firestore collections to JSON
firebase firestore:export firestore_export --export-path ./firestore_backup

# Or manually export each collection:
# 1. Users collection
# 2. Sellers collection
# 3. Cart items
# 4. Orders
```

### Step 2: Transform Data Format

**Python Script** (`scripts/migrate_data.py`):

```python
import json
from datetime import datetime
import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
users_table = dynamodb.Table('Users')
items_table = dynamodb.Table('Items')

# Transform Firestore export to DynamoDB format
def transform_user(firestore_user):
    return {
        'userId': firestore_user['uid'],
        'email': firestore_user['email'],
        'role': firestore_user.get('role', 'buyer'),
        'profileCompleted': firestore_user.get('profileCompleted', False),
        'createdAt': int(datetime.fromisoformat(firestore_user['createdAt']).timestamp()),
        'updatedAt': int(datetime.now().timestamp()),
        'coordinates': {
            'latitude': firestore_user.get('coordinates', {}).get('latitude', 0),
            'longitude': firestore_user.get('coordinates', {}).get('longitude', 0)
        },
        'city': firestore_user.get('city', ''),
    }

def transform_item(firestore_item):
    return {
        'itemId': firestore_item['id'],
        'sellerId': firestore_item['sellerId'],
        'title': firestore_item['title'],
        'price': firestore_item.get('price', 0),
        'quantity': firestore_item.get('quantity', 0),
        'imageUrl': firestore_item.get('imageUrl', ''),
        'categories': firestore_item.get('categories', []),
        'itemTypes': firestore_item.get('itemTypes', []),
        'description': firestore_item.get('description', ''),
        'status': firestore_item.get('status', 'active'),
        'createdAt': int(datetime.fromisoformat(firestore_item['timestamp']).timestamp()),
    }

# Read and migrate
with open('firestore_export/users.json', 'r') as f:
    users = json.load(f)
    for user in users:
        transformed = transform_user(user)
        users_table.put_item(Item=transformed)
        print(f"Migrated user: {user['uid']}")

# Similar process for items, cart, orders
```

### Step 3: Migrate Images to S3

```powershell
# PowerShell Script to download from Google Drive and upload to S3

param (
    [string]$GoogleDriveExportPath = "C:\Google_Drive_Export",
    [string]$S3Bucket = "junkwunk-images-prod"
)

# Function to upload files to S3
function Upload-ToS3 {
    param(
        [string]$FilePath,
        [string]$S3Key
    )
    aws s3 cp $FilePath "s3://$S3Bucket/$S3Key" --metadata "migrated-from=google-drive"
    Write-Host "Uploaded: $FilePath to s3://$S3Bucket/$S3Key"
}

# Iterate through downloaded images
Get-ChildItem -Path $GoogleDriveExportPath -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($GoogleDriveExportPath.Length + 1)
    $s3Key = "item-images/$relativePath".Replace('\', '/')
    Upload-ToS3 -FilePath $_.FullName -S3Key $s3Key
}

Write-Host "Image migration complete!"
```

### Step 4: Validate Migration

```powershell
# Compare record counts
$firebaseCount = # (from Firestore export)
$dynamodbCount = aws dynamodb scan --table-name Users --select COUNT_ONLY --query 'Count'

Write-Host "Firebase Users: $firebaseCount"
Write-Host "DynamoDB Users: $dynamodbCount"

# Verify data integrity
$sampleUsers = aws dynamodb scan --table-name Users --limit 5 --query 'Items'
$sampleUsers | ConvertTo-Json | Out-File "migration-validation.json"
```

---

## Testing & Validation

### Unit Testing

**File:** `test/services/aws_auth_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:junk_wunk/services/aws_auth_service.dart';

void main() {
  group('AWS Auth Service Tests', () {
    late AwsAuthService authService;

    setUp(() {
      authService = AwsAuthService();
    });

    test('Sign up creates user successfully', () async {
      final result = await authService.signUp(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );
      expect(result.isSuccess, true);
    });

    test('Sign in with valid credentials', () async {
      final result = await authService.signIn(
        email: 'test@example.com',
        password: 'TestPassword123!',
      );
      expect(result.isSuccess, true);
      expect(result.user, isNotNull);
    });

    test('Invalid password format rejected', () async {
      final result = await authService.signUp(
        email: 'test@example.com',
        password: 'weak',  // Too weak
      );
      expect(result.isSuccess, false);
    });
  });
}
```

### Integration Testing

**File:** `test/integration/auth_flow_test.dart`

```dart
void main() {
  group('Authentication Flow Integration Tests', () {
    test('Complete signup and login flow', () async {
      // 1. Sign up
      final signUpResult = await authService.signUp(...);

      // 2. Verify email (mock)
      // 3. Sign in
      final signInResult = await authService.signIn(...);

      // 4. Check user profile created in DynamoDB
      final userProfile = await dynamoDbService.getUser(signInResult.user.id);

      expect(userProfile, isNotNull);
      expect(userProfile.email, equals('test@example.com'));
    });
  });
}
```

### API Testing

```powershell
# Test API Gateway endpoints with curl (or Postman)

# 1. Get authentication token
curl -X POST https://junkwunk-api.execute-api.us-east-1.amazonaws.com/prod/auth/signup `
  -H "Content-Type: application/json" `
  -d "{\"email\":\"test@example.com\",\"password\":\"TestPassword123!\"}"

# 2. Fetch items
curl -X GET https://junkwunk-api.execute-api.us-east-1.amazonaws.com/prod/items `
  -H "Authorization: Bearer $token"

# 3. Create item
curl -X POST https://junkwunk-api.execute-api.us-east-1.amazonaws.com/prod/items `
  -H "Authorization: Bearer $token" `
  -H "Content-Type: application/json" `
  -d @item-payload.json
```

### Performance Testing

```powershell
# Load test API endpoints
# Using Apache JMeter or similar tool

# Test configurations:
# 1. 100 concurrent users
# 2. 5 minute duration
# 3. Ramp-up: 2 minutes
# 4. Monitor response times and error rates
```

---

## Rollback Plan

### If Issues Occur During Migration

**Option 1: Switch Back to Firebase (Zero Downtime)**

```powershell
# Keep Firebase running in parallel during transition

# If AWS implementation has issues:
# 1. Update API endpoints back to Firebase
flutter pub remove amplify_flutter amplify_auth_cognito
flutter pub add firebase_core firebase_auth cloud_firestore

# 2. Revert code changes
git checkout lib/main.dart lib/screens/login_page.dart # etc.

# 3. Rebuild and redeploy
flutter run
```

**Option 2: Gradual Rollout**

```powershell
# 1. Deploy to 10% of users first
# 2. Monitor CloudWatch metrics
# 3. If error rate exceeds 5%, trigger rollback
# 4. Otherwise, increase to 50%, then 100%
```

**Option 3: Database Sync (Dual-Write)**

```dart
// During migration, write to both Firebase and AWS
await Future.wait([
  firebaseService.updateUser(user),  // Old
  awsService.updateUser(user),        # New
]);

// If AWS fails, Firebase is still source of truth
```

### Data Restoration

```powershell
# If data is corrupted, restore from backup

# DynamoDB point-in-time recovery
aws dynamodb restore-table-to-point-in-time `
  --source-table-name Users `
  --target-table-name Users-Restored `
  --use-latest-restorable-time

# Rename tables
aws dynamodb rename-table `
  --current-table-name Users `
  --new-table-name Users-Backup

aws dynamodb rename-table `
  --current-table-name Users-Restored `
  --new-table-name Users
```

---

## Security Considerations

### Authentication & Authorization

- ✅ Cognito MFA for enhanced security
- ✅ JWT token validation on all API calls
- ✅ Role-based access control (RBAC)
- ✅ API Gateway usage plans and throttling

### Data Protection

- ✅ DynamoDB encryption at rest
- ✅ S3 bucket encryption
- ✅ VPC endpoints for private communication
- ✅ Audit logging with CloudTrail

### Compliance

- ✅ GDPR: Data export and deletion capabilities
- ✅ Data retention policies
- ✅ Access logs and monitoring
- ✅ Regular security audits

### API Security

```powershell
# Enable API Gateway logging
aws apigateway update-stage `
  --rest-api-id $apiId `
  --stage-name prod `
  --patch-operations `
    op=replace,path=/*/*/logging/loglevel,value=INFO `
    op=replace,path=/*/*/logging/dataFullyClaudedLoggingEnabled,value=true

# Enable WAF on API Gateway (optional)
aws wafv2 create-web-acl `
  --name junkwunk-api-waf `
  --region us-east-1 `
  --scope REGIONAL
```

---

## Post-Migration Tasks

### 1. Monitoring & Alerting

```powershell
# Set up CloudWatch dashboards
# Monitor:
# - Lambda execution time
# - DynamoDB throttling
# - API Gateway latency
# - S3 upload failures
```

### 2. Cost Optimization

```powershell
# Review costs after migration
aws ce get-cost-and-usage `
  --time-period Start=2025-11-01,End=2025-11-30 `
  --granularity DAILY `
  --metrics BlendedCost `
  --filter file://cost-filter.json

# Optimize DynamoDB capacity
# Switch to on-demand if unpredictable
# Or reserved capacity if predictable
```

### 3. Documentation

- Update API documentation
- Create runbooks for common issues
- Document AWS architecture
- Update development guides

### 4. Team Training

- AWS service overview
- Debugging with CloudWatch
- DynamoDB query patterns
- Cost management

---

## Estimated Costs (Monthly)

| Service             | Usage                    | Estimated Cost      |
| ------------------- | ------------------------ | ------------------- |
| **Cognito**         | 50,000 MAU               | ~$500               |
| **DynamoDB**        | On-demand (10GB storage) | ~$50-200            |
| **Lambda**          | 1M invocations/month     | ~$20                |
| **API Gateway**     | 1M requests/month        | ~$50                |
| **S3**              | 100GB storage            | ~$2.50              |
| **CloudWatch**      | Logs + monitoring        | ~$30                |
| **Total Estimated** |                          | **~$650-800/month** |

_Note: Actual costs depend on usage patterns. Use AWS Cost Calculator for precise estimates._

---

## Conclusion

This migration plan provides a comprehensive roadmap for transitioning JUNKWUNK from Firebase to AWS. The phased approach allows for:

1. ✅ Parallel infrastructure setup while maintaining existing app
2. ✅ Gradual code migration and testing
3. ✅ Controlled data migration
4. ✅ Rollback capabilities if needed
5. ✅ Minimal downtime during transition

**Next Steps:**

1. Review and approve this plan
2. Set up AWS infrastructure (Phase 1)
3. Develop Lambda functions (Phase 2)
4. Migrate frontend code (Phase 3)
5. Perform comprehensive testing (Phase 4)
6. Deploy to production (Phase 5)

---

## Appendix

### A. CloudFormation Template Overview

Create `infrastructure.yaml` to automate AWS setup:

- Cognito User Pool configuration
- DynamoDB tables with indexes
- S3 bucket configuration
- Lambda execution roles
- API Gateway basic setup

### B. Environment Variables

Create `.env` file for local development:

```
AWS_REGION=us-east-1
AWS_COGNITO_USER_POOL_ID=us-east-1_xxxxx
AWS_COGNITO_CLIENT_ID=xxxxx
AWS_API_ENDPOINT=https://junkwunk-api.execute-api.us-east-1.amazonaws.com/prod
AWS_S3_BUCKET=junkwunk-images-prod
DYNAMODB_TABLE_PREFIX=junkwunk_
```

### C. Useful References

- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [AWS Lambda with Flutter](https://aws.amazon.com/blogs/mobile/amplify-flutter/)
- [S3 Presigned URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)

---

**Document prepared for:** JUNKWUNK Development Team  
**Date:** November 8, 2025  
**Status:** Ready for Implementation Planning
