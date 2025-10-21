# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Junk-Wunk is a Flutter-based marketplace app connecting rag pickers (sellers) and buyers for recyclable, non-recyclable, and donation materials. Built during the HACK-N-DROID hackathon (24 hours, 2nd place winner).

**Tech Stack:**
- Frontend: Flutter (Dart)
- Backend: Firebase (Auth, Firestore, Storage)
- Additional: Google Drive API, Google Maps, Geocoding

## Development Commands

### Setup
```powershell
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run for specific platform
flutter run -d windows    # Windows
flutter run -d chrome     # Web
flutter run -d android    # Android (with device/emulator)
```

### Build
```powershell
# Build for production (Windows)
flutter build windows

# Build APK (Android)
flutter build apk

# Build for web
flutter build web
```

### Testing & Linting
```powershell
# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
flutter format lib/
```

### Clean & Reset
```powershell
# Clean build artifacts
flutter clean
flutter pub get
```

## Architecture

### App Entry Point & Navigation
- **lib/main.dart**: Initializes Firebase, handles authentication state, routes users to login/profile setup/dashboards based on role
- Authentication flow: Login → Profile Setup → Role-based Dashboard (Seller/Buyer)
- Uses StreamBuilder to listen to `FirebaseAuth.authStateChanges()` and SharedPreferences for logout state
- Global logout handler: `handleLogout()` function sets logout flag and clears auth state

### User Roles & Dual Dashboard System
The app has two distinct user roles with separate UI flows:

**Seller Dashboard** (`screens/seller/`):
- `seller_dashboard1.dart`: Landing page with 3-page swipe view (Page1/2/3)
- `seller_dashboard.dart`: Main form to list items (upload image, select categories, set price/quantity)
- `summary_page.dart`: Preview item before publishing to Firestore
- Sellers list items under `sellers/{userId}/items/` collection

**Buyer Dashboard** (`screens/buyer/`):
- `buyer_dashboard1.dart`: Landing page with 3-page swipe view (Page1/2/3)
- `buyer_dashboard.dart`: Browse items with TabBar filtering (All/Donate/Recyclable/Non-Recyclable)
- `buyer_cart.dart`: Shopping cart with item management and order placement
- `item_location.dart`: Map view showing seller's location with route navigation

### Firebase Data Structure
```
users/{userId}
  - role: "buyer" | "seller"
  - profileCompleted: boolean
  - coordinates: GeoPoint
  - (other profile fields)

sellers/{userId}
  - name, email, city, coordinates
  items/{itemId}
    - imageUrl, categories[], itemTypes[], title, description
    - price, quantity, status, timestamp

users/{userId}/cart/{itemId}
  - (cart items for buyers)

users/{userId}/orders/{orderId}
  - (order history)
```

### Core Services
- **services/google_drive_service.dart**: Uploads images to Google Drive (service account auth), returns public viewing URLs. Handles both web (bytes) and mobile (File) uploads.
- Images stored in specific Drive folder (ID: `1GduVgC80KAdbbfu0FVZ94CLdCLf98WT9`)

### Reusable Widgets
- **widgets/image_uploader.dart**: Cross-platform image picker (uses `image_picker` package)
- **widgets/item_card.dart**: Product card with image, title, price, "Add to Cart" button
- **widgets/app_bar.dart**: Custom AppBar with consistent styling
- **widgets/filter_button.dart**: Category filter buttons

### Profile Management
- **screens/profile/profile_setup_page.dart**: First-time setup for role selection and profile completion
- **screens/profile/profile_page.dart**: View/edit user profile
- **screens/profile/edit_profile_page.dart**: Edit profile form with location picker

### Authentication
- **screens/login_page.dart**: Google Sign-In authentication
- **utils/auth_helpers.dart**: Helper functions for user creation and role management

### Mediator Pattern
Both seller and buyer dashboards use a 3-page mediator pattern:
- `screens/seller/mediator/page1.dart` → Navigate to `SellerDashboard`
- `screens/buyer/mediator/page1.dart` → Navigate to `BuyerDashboard`
- Pages 2 and 3 contain additional navigation/features (check respective directories)

## Key Patterns & Conventions

### Firebase Integration
- Always check `FirebaseAuth.instance.currentUser` before Firestore operations
- Use `FieldValue.serverTimestamp()` for timestamps
- Use `SetOptions(merge: true)` when updating existing documents
- Firestore collections: `users`, `sellers/{userId}/items`, `users/{userId}/cart`

### Location Handling
- User coordinates stored as `GeoPoint` in Firestore
- City names resolved using `geocoding` package (`placemarkFromCoordinates`)
- Google Maps integration for seller location display and navigation

### Image Uploads
- Images uploaded to Google Drive, not Firebase Storage
- Requires service account credentials at `assets/credentials/service_account.json`
- Returns direct view URLs in format: `https://drive.google.com/uc?export=view&id={fileId}`

### State Management
- Uses `provider` package (available in dependencies)
- StatefulWidget for local state, StreamBuilder for Firebase real-time updates
- Cart count refreshed via `loadCartItemCount()` after cart operations

### Color Scheme
- Primary: `Color(0xFF371f97)` (deep purple)
- Secondary: `Color(0xFFf5f5f5)` or `Color(0xFFEEE8F6)` (light purple/gray)
- Used consistently across dashboards and widgets

### Platform-Specific Code
- Web vs Mobile file handling in `google_drive_service.dart` (bytes vs File)
- Image picker handles platform differences automatically

## Firebase Configuration

Firebase is configured via FlutterFire CLI:
- Configuration file: `lib/firebase_options.dart`
- Project ID: `junkwunk`
- Platforms: Android, iOS, Windows, Web
- Config file: `firebase.json`

## Assets

Located in `assets/` directory:
- `credentials/service_account.json`: Google Drive API service account (DO NOT COMMIT real credentials)
- `default_picture.jpg`: Placeholder profile image

## Common Development Patterns

### Adding a New Screen
1. Create file in appropriate `screens/` subdirectory
2. Add route in `main.dart` routes map if needed
3. Use existing color scheme and AppBarWidget for consistency

### Firestore Query Pattern
```dart
// Fetch items from all sellers
FirebaseFirestore.instance
  .collection('sellers')
  .get()
  .then((sellersSnapshot) {
    for (var seller in sellersSnapshot.docs) {
      seller.reference.collection('items').get();
    }
  });
```

### Adding to Cart
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('cart')
  .doc(itemId)
  .set({...itemData});
```

## Testing

- Widget tests located in `test/widget_test.dart`
- Run with: `flutter test`
- Currently minimal test coverage (hackathon project)

## Windows-Specific Notes

- Current environment is Windows (PowerShell)
- Use PowerShell commands for file operations
- Flutter supports Windows as a target platform (Desktop app)
- CMake configuration warnings can be ignored if building for other platforms
