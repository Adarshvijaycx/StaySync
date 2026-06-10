# Hotel Management App — Phased Implementation Plan
### Flutter + Appwrite | Based on SRDP v1.0

---

## Phase Overview

| Phase | Name | Weeks | Key Output |
|-------|------|-------|------------|
| **1** | Project Setup & Dependency Check | 1 | Clean build, all packages resolved, folder structure |
| **2** | Auth, Routing & Session | 2–3 | Login → Role-based home screen |
| **3** | Hotel & Room Management | 4–5 | Admin CRUD for hotels + rooms |
| **4** | Booking & KYC Module | 6–8 | Full booking form, photo upload, checkout |
| **5** | Guest Tab & Item Management | 9–10 | Staff tab, running total, bill |
| **6** | Dashboard | 11–12 | KPIs, charts, payment attribution |
| **7** | Offline Sync | 13 | Write queue, conflict resolution |
| **8** | Polish, UAT & Release | 14 | Signed APK |

---

---

# ✅ PHASE 1 — Project Setup & Dependency Check

> **Goal:** Create the Flutter project, verify your environment, install all packages,
> and generate the folder skeleton. At the end of Phase 1, `flutter run` should
> show a blank Material 3 screen with zero errors.

---

## 1.1 Environment Requirements Checklist

Open a terminal **inside your Antigravity IDE** and run each command.
Every item must pass before moving to dependency installation.

### Flutter & Dart SDK

```bash
# Check Flutter version (must be ≥ 3.22.x for Dart 3.3+)
flutter --version

# Full environment diagnostic — fix every "!" item
flutter doctor -v
```

**Required checklist:**
- [ ] Flutter SDK ≥ 3.22.0
- [ ] Dart SDK ≥ 3.3.0  (bundled with Flutter)
- [ ] Android toolchain — `flutter doctor` shows ✓
- [ ] Android SDK Build-tools installed
- [ ] `cmdline-tools` component installed (`sdkmanager --list` shows it)
- [ ] An Android emulator OR physical device connected (`flutter devices`)
- [ ] Java / JDK 17 or 21 (required by Gradle 8.x)

```bash
# Confirm Java version
java -version
```

### Android SDK

```bash
# Inside Antigravity IDE terminal or standalone terminal:
flutter doctor --android-licenses   # Accept all licenses if prompted
```

- [ ] All Android licenses accepted
- [ ] minSdkVersion target: **26** (Android 8.0) — set in `android/app/build.gradle`

---

## 1.2 Create the Flutter Project

```bash
# Replace <path> with your workspace folder
flutter create hotel_management --org com.yourcompany --platforms android

cd hotel_management
```

---

## 1.3 Install pubspec.yaml Dependencies

Copy `phase1_pubspec.yaml` (provided alongside this document) into the project
root as `pubspec.yaml`, replacing the default one. Then:

```bash
# Fetch all packages
flutter pub get
```

**Expected output:** `Got dependencies!` with no version conflicts.

> ✅ `appwrite` is already installed — it will resolve from cache.

If you hit a version conflict, run:

```bash
flutter pub outdated
flutter pub upgrade --major-versions   # Only if you know it's safe
```

---

## 1.4 Verify Code Generators Work

```bash
# Run a dry-run to confirm build_runner, isar_generator,
# riverpod_generator, and freezed are all wired up
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] Build completes with no errors (warnings are OK at this stage)

---

## 1.5 android/app/build.gradle — Required Settings

Open `android/app/build.gradle` and ensure:

```gradle
android {
    compileSdkVersion 34       // or 35

    defaultConfig {
        minSdkVersion 26       // ← Required: Android 8.0+
        targetSdkVersion 34
        multiDexEnabled true   // Needed for large dependency count
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
```

Add `multidex` dependency in the same file under `dependencies {}`:

```gradle
dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

---

## 1.6 AndroidManifest.xml — Required Permissions

Open `android/app/src/main/AndroidManifest.xml` and add inside `<manifest>`:

```xml
<!-- Network access for Appwrite API calls -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Camera + storage for guest photo / ID proof capture -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>

<!-- Required by image_picker for Android 13+ -->
<uses-feature android:name="android.hardware.camera" android:required="false"/>
```

---

## 1.7 Create the Folder Structure

Run this script from the project root to scaffold all feature folders:

```bash
# Core structure
mkdir -p lib/core/{constants,errors,network,utils}

# Data layer
mkdir -p lib/data/{datasources,models,repositories}

# Domain layer
mkdir -p lib/domain/{entities,usecases}

# Presentation — one folder per feature
mkdir -p lib/presentation/{auth,dashboard,bookings,rooms,hotels,items,users}

# Shared UI
mkdir -p lib/shared/{widgets,theme}

# Assets (fill later)
mkdir -p assets/{images,icons}

echo "✅ Folder structure created"
```

---

## 1.8 Phase 1 Core Files to Create

Create these minimal files so the project compiles:

### `lib/core/constants/appwrite_constants.dart`
```dart
class AppwriteConstants {
  static const String projectId   = 'YOUR_PROJECT_ID';   // ← replace
  static const String endpoint    = 'https://cloud.appwrite.io/v1';
  static const String databaseId  = 'YOUR_DATABASE_ID';  // ← replace

  // Collection IDs (fill as you create them in Appwrite Console)
  static const String hotelsCollection       = 'hotels';
  static const String roomsCollection        = 'rooms';
  static const String bookingsCollection     = 'bookings';
  static const String customersCollection    = 'customers';
  static const String bookingItemsCollection = 'booking_items';
  static const String usersCollection        = 'users';
  static const String itemCatalogueCollection= 'item_catalogue';

  // Storage bucket IDs
  static const String guestPhotosBucket  = 'guest_photos';
  static const String idProofsBucket     = 'id_proofs';
}
```

### `lib/core/constants/app_constants.dart`
```dart
class AppConstants {
  static const String appName = 'Hotel Manager';

  // Default check-in/check-out times
  static const int defaultCheckInHour    = 12; // 12:00 PM
  static const int defaultCheckOutHour   = 11; // 11:00 AM
  static const int defaultStayDays       = 1;

  // Image compression
  static const int maxImageSizeKB        = 500;
  static const int imageQuality          = 75;  // percent
}
```

### `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HotelManagementApp()));
}

class HotelManagementApp extends StatelessWidget {
  const HotelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel Manager',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(child: Text('Phase 1 — Setup Complete ✅')),
      ),
    );
  }
}
```

### `lib/shared/theme/app_theme.dart`
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A6EBF),
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A6EBF),
      brightness: Brightness.dark,
    ),
  );
}
```

---

## 1.9 Phase 1 Completion Checklist

Before calling Phase 1 done, verify every item:

- [ ] `flutter doctor -v` — zero `!` errors
- [ ] `flutter pub get` — `Got dependencies!`
- [ ] `flutter pub run build_runner build` — completes cleanly
- [ ] `flutter run` — app launches, shows "Phase 1 — Setup Complete ✅"
- [ ] `minSdkVersion 26` confirmed in `build.gradle`
- [ ] All AndroidManifest permissions added
- [ ] Appwrite project ID + endpoint filled in `AppwriteConstants`
- [ ] Folder structure exists (`lib/core`, `lib/data`, `lib/domain`, `lib/presentation`, `lib/shared`)

---

---

# PHASE 2 — Authentication & Role-Based Routing

**Deliverable (M1):** Login → session persisted → user lands on role-specific home screen.

### Tasks
1. **Appwrite setup** — Enable Email/Password auth in Appwrite Console. Create the `users` collection with fields: `user_id`, `name`, `email`, `role` (Enum), `hotel_id`, `is_active`.
2. **Appwrite client provider** — `lib/data/datasources/appwrite_client.dart` — singleton `Client` using `AppwriteConstants`.
3. **Auth repository** — `login(email, password)`, `logout()`, `currentSession()`.
4. **User role model** — Freezed class with roles: `admin`, `manager`, `staff`.
5. **Login screen** — Email/password form with `reactive_forms`, inline validation.
6. **Session persistence** — On app launch, check for existing session; skip login if valid.
7. **GoRouter setup** — `lib/core/routes/app_router.dart` with:
   - `/login` — unauthenticated
   - `/admin` — Admin home (guard: role == admin)
   - `/manager` — Manager home (guard: role == manager)
   - `/staff` — Staff home (guard: role == staff)
   - Redirect logic in `redirect` callback
8. **Offline session** — Cache session token in Isar or `shared_preferences`; if offline at launch, use cached token.

### Key Files to Create
```
lib/data/datasources/appwrite_client.dart
lib/data/datasources/auth_remote_datasource.dart
lib/data/repositories/auth_repository.dart
lib/domain/entities/app_user.dart
lib/presentation/auth/login_screen.dart
lib/core/routes/app_router.dart
```

---

---

# PHASE 3 — Hotel & Room Management

**Deliverable (M2):** Admin can add hotels, add rooms with status; Manager/Staff see read-only list.

### Tasks
1. **Appwrite collections** — Create `hotels` and `rooms` in Appwrite Console per DB schema.
2. **Hotel CRUD** — Create / Read / Update / Delete hotel documents (Admin only).
3. **Room CRUD** — Add rooms to a hotel; edit room type, rate, status (Admin only).
4. **Room status auto-update** — Cloud Function (or client-side logic) to set room `status → Occupied` when a booking is confirmed, `→ Available` on checkout.
5. **Room list view** — For Manager/Staff: read-only card list with color-coded availability badge.
6. **Isar local models** — `HotelModel` and `RoomModel` with `@collection` annotations; sync from Appwrite on open.

### Key Files
```
lib/data/models/hotel_model.dart    (Isar collection)
lib/data/models/room_model.dart     (Isar collection)
lib/data/repositories/hotel_repository.dart
lib/data/repositories/room_repository.dart
lib/presentation/hotels/hotel_list_screen.dart
lib/presentation/hotels/hotel_form_screen.dart
lib/presentation/rooms/room_list_screen.dart
lib/presentation/rooms/room_form_screen.dart
```

---

---

# PHASE 4 — Booking & KYC Module

**Deliverable (M3):** End-to-end booking: create → view → edit → checkout.

### Tasks
1. **Appwrite collections** — `customers` and `bookings`; set Collection Permissions (Admin+Manager write, Staff read).
2. **Booking form** — All fields from FR-BOOK-02:
   - Guest name, DOB (date picker) → auto-computed age display
   - Phone, email (optional), parent name, full address + pincode
   - Room selector (shows available rooms only)
   - Number of guests
   - Check-in / check-out date-time pickers (defaults per `AppConstants`)
   - Payment mode dropdown
   - ID proof type + photo capture (`image_picker` → compress → Appwrite Storage upload)
   - Guest photo capture
3. **Auto-fill "Booked By" / "Collected By"** — inject logged-in user ID at save.
4. **Double-booking guard** — Appwrite Function (Node.js): query `bookings` for room+dates overlap before confirming.
5. **Booking list screen** — With filters: date range, status (Confirmed / Checked Out), hotel.
6. **Booking detail screen** — Full guest info, room info, tab total, action buttons (Edit, Checkout, Add Item).
7. **Edit booking** — Admin + Manager; re-validates all fields.
8. **Checkout flow** — Modal: fill actual departure time → `booking_status = 'checked_out'` → room status → Available.
9. **Isar offline** — `BookingModel` and `CustomerModel` with Isar collection; offline cache + write queue.

### Key Files
```
lib/data/models/booking_model.dart
lib/data/models/customer_model.dart
lib/data/repositories/booking_repository.dart
lib/presentation/bookings/booking_list_screen.dart
lib/presentation/bookings/booking_form_screen.dart
lib/presentation/bookings/booking_detail_screen.dart
lib/presentation/bookings/checkout_sheet.dart
```

---

---

# PHASE 5 — Guest Tab & Item Management

**Deliverable (M4):** Staff can add items; correct bill generated at checkout.

### Tasks
1. **Appwrite collection** — `booking_items` and `item_catalogue`.
2. **Item catalogue screen** — Admin manages items: name, default price, category, active flag.
3. **Guest tab screen** — Linked to booking detail; shows all added items + running total.
4. **Add item flow** — Bottom sheet: pick item from catalogue → set quantity → save. Auto-records `added_by` (logged-in user), `added_at` (timestamp).
5. **Running total** — Tab total = Σ(unit_price × quantity); reflect on booking detail.
6. **Role enforcement** — Staff: add only; Admin/Manager: edit price/quantity or remove item.
7. **Final bill** — At checkout: room charges (nights × rate) + tab total = `total_amount` on booking.

### Key Files
```
lib/data/models/booking_item_model.dart
lib/data/models/item_catalogue_model.dart
lib/data/repositories/item_repository.dart
lib/presentation/items/guest_tab_screen.dart
lib/presentation/items/add_item_sheet.dart
lib/presentation/items/item_catalogue_screen.dart
```

---

---

# PHASE 6 — Dashboard

**Deliverable (M5):** All KPIs and charts display real data.

### Tasks
1. **KPI cards** — Today's Occupancy, Available Rooms, Pending Checkouts, Monthly Revenue. Read from Isar cache; refresh on open.
2. **Monthly earnings bar chart** — `fl_chart` `BarChart`; query bookings grouped by month.
3. **Room occupancy grid** — Color-coded grid: green = available, red = occupied, grey = maintenance.
4. **Payment attribution panel** — Group today's `collected_by` → sum `total_amount` → list per staff name.
5. **Hotel selector** — Admin: dropdown to switch between hotels; filters all dashboard data.
6. **Appwrite Realtime** — Subscribe to `bookings` collection changes; live-update KPI cards when another device checks in/out.

### Key Files
```
lib/presentation/dashboard/dashboard_screen.dart
lib/presentation/dashboard/kpi_card.dart
lib/presentation/dashboard/earnings_chart.dart
lib/presentation/dashboard/room_grid.dart
lib/presentation/dashboard/payment_attribution_panel.dart
```

---

---

# PHASE 7 — Offline Sync

**Deliverable (M6):** App works fully offline; syncs on reconnect with no data loss.

### Tasks
1. **Write queue model** — Isar collection `PendingOperation` with fields: `id`, `collectionId`, `operationType` (create/update/delete), `payload` (JSON), `createdAt`, `retryCount`.
2. **Sync service** — `connectivity_plus` listener; on `ConnectivityResult.mobile/wifi`, flush the queue in order.
3. **Conflict resolution** — Bookings: server-wins (check `$updatedAt` server timestamp). Tab items: client-wins (append; no overwrite).
4. **Retry with backoff** — On Appwrite network error: wait 2s → 4s → 8s (max 3 retries) → mark `failed`; surface in UI.
5. **Sync status indicator** — A small icon in the app bar: ✅ Synced, 🔄 Syncing, ⚠️ Pending (N items), ❌ Failed.

### Key Files
```
lib/core/network/sync_queue.dart
lib/core/network/connectivity_service.dart
lib/core/network/sync_service.dart
lib/data/models/pending_operation_model.dart
lib/shared/widgets/sync_status_indicator.dart
```

---

---

# PHASE 8 — Polish, UAT & Release

**Deliverable (M7):** Signed APK + training session.

### Tasks
1. **Loading states** — Every async screen: skeleton loader or `CircularProgressIndicator`.
2. **Empty states** — Illustrated empty state widget for booking list, room list, tab.
3. **Error states** — Network error banners with retry button.
4. **Dark mode** — Verify all custom colors use `ColorScheme` tokens (no hardcoded hex).
5. **Form validation** — Re-audit all `reactive_forms` validators: required, phone format, email format, pincode 6-digit.
6. **Physical device testing** — Run on Android 8, 10, 13, 14 devices.
7. **Firebase App Distribution** — Upload debug APK for hotel staff UAT.
8. **UAT feedback** — Collect issues; fix critical ones before release build.
9. **Release APK** — `flutter build apk --release`; sign with keystore.
10. **Appwrite permissions audit** — Confirm all Collection Permissions match the Role Permission Matrix (Appendix A of SRDP).

---

*End of Implementation Plan — Hotel Management App v1.0*
