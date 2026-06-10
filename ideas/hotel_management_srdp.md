# Software Requirements and Development Plan
## Hotel Management Android Application (Flutter + Appwrite)

**Document Version:** 1.0  
**Prepared By:** Senior Software Architect & Project Manager  
**Date:** June 2026  
**Status:** Implementation-Ready Draft

---

## 1. Project Overview

This document outlines the complete Software Requirements and Development Plan for a **multi-tenant Hotel Management Android Application** built with Flutter and powered by Appwrite as the cloud backend. The application is designed to digitize and streamline front-desk operations across two currently active hotel properties, with the architectural foundation to support additional hotels in the future.

The system replaces manual booking registers and paper-based processes with a role-aware, cloud-synchronized mobile platform. It supports real-time booking management, guest identity verification (including photo and ID proof capture), item-level service tracking per guest tab, and an operational dashboard for revenue and occupancy insights.

The app is **offline-first**: all core operations are available without an internet connection, and data is synced to Appwrite cloud whenever connectivity is restored.

---

## 2. Objectives

- Digitize the complete guest lifecycle — from check-in booking to check-out — across multiple hotel properties managed by the same organization.
- Implement granular role-based access control (RBAC) so that Admin, Manager, and Staff users each have appropriate and restricted access to data and operations.
- Capture comprehensive guest KYC data at the time of booking, including photo, ID proof, and demographic information, to meet regulatory compliance requirements.
- Enable per-guest item tracking (e.g., beverages, services) on a running "tab" that is linked to the booking.
- Provide an actionable real-time dashboard for management to monitor occupancy, revenue, and guest engagement.
- Ensure data integrity and traceability: every booking and payment action is traceable to the staff member who performed it, via authenticated login.
- Build on a scalable multi-hotel data architecture, so new properties can be onboarded by admin without code changes.

---

## 3. Target Users

| Role | Primary Responsibilities | Access Level |
|------|--------------------------|--------------|
| **Admin** | System configuration, hotel & room management, full data access, user management | Full Read / Write / Delete |
| **Manager** | Create and manage guest bookings, process check-outs, edit existing bookings | Read + Create + Edit (bookings) |
| **Staff** | View assigned bookings; add consumable items to guest tabs | Read + Add Items to Booking |
| **Guest (Indirect)** | Receives bill/confirmation via messaging (future) | No app login |

---

## 4. Core Features

### 4.1 Multi-Hotel Property Management
- Admin can create, configure, and manage multiple hotel properties.
- Each hotel has its own room inventory with configurable room numbers, types, and capacity.

### 4.2 Role-Based Access Control (RBAC)
- Three internal user roles: Admin, Manager, Staff.
- Permissions enforced at both UI layer (Flutter) and backend layer (Appwrite Permissions / Functions).
- Admin can create, deactivate, and assign roles to users.

### 4.3 Guest Booking with Full KYC
- Comprehensive booking form capturing all guest data fields.
- Auto-age calculation from Date of Birth.
- ID proof capture: Aadhaar Card, PAN Card, or Government-issued ID — with photo upload.
- Guest photograph capture.
- Configurable check-in/check-out date-time with hotel-standard defaults (12:00 PM check-in / 11:00 AM check-out).
- Checkout date-time editable at the time of guest departure.

### 4.4 Guest Tab / Item Management
- After booking creation, a live "Guest Tab" is opened for the booking.
- Staff can add items (e.g., Water, Tea, Coffee, Meals, Laundry) to the tab.
- Item additions are timestamped and linked to the staff member who added them.
- Tab total auto-reflects in the booking record.

### 4.5 Payment Tracking & Attribution
- Mode of payment recorded at check-in: Cash, Card, UPI, or Advance.
- Payment recorded with the logged-in user's identity, creating an audit trail of "Collected By" and "Booked By".
- Dashboard reflects payment collection per staff/manager.

### 4.6 Booking Edit / Checkout Flow
- Admin and Manager can edit confirmed bookings (guest info, room, dates, payment).
- Checkout flow allows filling in actual departure time and finalizing the bill.

### 4.7 Operational Dashboard
- KPI Cards: Today's Occupancy, Available Rooms, Monthly Revenue, Pending Checkouts.
- Charts: Monthly earnings trend, Room occupancy heatmap, Customer check-ins over time.
- Payment attribution: Breakdown of collections per staff member.

### 4.8 Offline-First Operation
- Core data (bookings, rooms, items) cached locally using Hive or Isar.
- All write operations queued when offline and synced to Appwrite on reconnect.
- Conflict resolution strategy: last-write-wins with server timestamp.

---

## 5. Functional Requirements

### 5.1 Authentication & User Management

| ID | Requirement |
|----|-------------|
| FR-AUTH-01 | The system shall authenticate users via Appwrite Auth (email/password). |
| FR-AUTH-02 | On login, the system shall fetch and cache the user's role from the `users` collection. |
| FR-AUTH-03 | Admin shall be able to create new user accounts with an assigned role (Admin / Manager / Staff). |
| FR-AUTH-04 | Admin shall be able to deactivate user accounts. |
| FR-AUTH-05 | Session tokens shall be persisted locally for offline use, with expiry handling on reconnect. |

### 5.2 Hotel & Room Management

| ID | Requirement |
|----|-------------|
| FR-HOTEL-01 | Admin shall be able to add a new hotel with name, address, and contact details. |
| FR-HOTEL-02 | Admin shall be able to add, update, and delete rooms for each hotel (room number, type, floor, capacity, rate). |
| FR-HOTEL-03 | Room availability status (Available, Occupied, Maintenance) shall update automatically based on active bookings. |
| FR-HOTEL-04 | Managers and Staff shall view rooms in read-only mode. |

### 5.3 Booking Management

| ID | Requirement |
|----|-------------|
| FR-BOOK-01 | Manager and Admin shall be able to create a new booking. |
| FR-BOOK-02 | The booking form shall collect: Guest Name, Date of Birth (with auto-computed age), Phone Number, Email (optional), Father/Mother Name, Full Address (with Pincode), Room Number, Number of Guests, ID Proof Type & Photo, Guest Photo, Check-In Date & Time (default: current timestamp), Check-Out Date & Time (default: 1 day after check-in at 11:00 AM), Mode of Payment. |
| FR-BOOK-03 | The system shall auto-record the logged-in user as "Booked By" at time of booking creation. |
| FR-BOOK-04 | The system shall auto-record the logged-in user as "Collected By" when payment mode is set. |
| FR-BOOK-05 | Admin and Manager shall be able to edit an existing confirmed booking. |
| FR-BOOK-06 | Staff shall view booking details but shall not modify them. |
| FR-BOOK-07 | The system shall prevent double-booking of the same room for overlapping dates. |
| FR-BOOK-08 | Checkout shall allow updating the actual departure time and marking the booking as Checked Out. |

### 5.4 Guest Tab & Item Management

| ID | Requirement |
|----|-------------|
| FR-ITEM-01 | Upon booking creation, the system shall automatically create an open tab linked to the booking. |
| FR-ITEM-02 | Admin, Manager, and Staff shall be able to add items to a guest's tab. |
| FR-ITEM-03 | Each item entry shall record: item name, quantity, unit price, timestamp, and the user who added it. |
| FR-ITEM-04 | The running tab total shall be visible on the booking detail screen. |
| FR-ITEM-05 | Admin shall be able to configure a master item catalogue (item name, default price). |
| FR-ITEM-06 | The final bill at checkout shall include room charges and all tab items. |

### 5.5 Dashboard

| ID | Requirement |
|----|-------------|
| FR-DASH-01 | The dashboard shall display today's date, logged-in user name, and hotel selector. |
| FR-DASH-02 | KPI tiles shall show: Total Available Rooms, Currently Occupied Rooms, Pending Checkouts Today, Total Monthly Revenue. |
| FR-DASH-03 | A monthly earnings bar chart shall display revenue per month for the current year. |
| FR-DASH-04 | A room occupancy section shall show which rooms are occupied, available, or under maintenance. |
| FR-DASH-05 | A payment attribution panel shall list total collections per staff/manager for the current day. |
| FR-DASH-06 | Dashboard data shall refresh on app open and be available in read-only mode when offline. |

### 5.6 Image & File Handling

| ID | Requirement |
|----|-------------|
| FR-FILE-01 | Guest photo and ID proof photos shall be captured via device camera or gallery. |
| FR-FILE-02 | Images shall be compressed before upload to Appwrite Storage. |
| FR-FILE-03 | Uploaded image URLs shall be stored in the booking document. |
| FR-FILE-04 | Images shall be accessible to Admin and Manager; Staff shall view but not delete. |

---

## 6. Non-Functional Requirements

### 6.1 Performance

| ID | Requirement |
|----|-------------|
| NFR-PERF-01 | The app shall launch from cold start to home screen in ≤ 3 seconds on a mid-range Android device (4 GB RAM). |
| NFR-PERF-02 | Booking list with up to 500 records shall load within 2 seconds using local cache. |
| NFR-PERF-03 | Image upload (up to 5 MB) shall not block the UI thread; progress shall be shown. |
| NFR-PERF-04 | Dashboard data shall render within 1.5 seconds from locally cached data. |

### 6.2 Security

| ID | Requirement |
|----|-------------|
| NFR-SEC-01 | All API calls to Appwrite shall use authenticated sessions with JWT tokens. |
| NFR-SEC-02 | Appwrite Collection Permissions shall enforce RBAC server-side to prevent unauthorized data access even via API. |
| NFR-SEC-03 | Guest KYC photos (ID proof) shall be stored in a restricted Appwrite Storage bucket, accessible only to Admin and Manager roles. |
| NFR-SEC-04 | The app shall not store raw passwords or sensitive credentials locally. |
| NFR-SEC-05 | Sensitive screens (e.g., booking creation, user management) shall require active authenticated session validation. |

### 6.3 Reliability & Availability

| ID | Requirement |
|----|-------------|
| NFR-REL-01 | The app shall operate in full offline mode for booking reads, item additions, and dashboard view using the local cache. |
| NFR-REL-02 | Write operations performed offline shall be queued and synced to Appwrite upon connectivity restoration. |
| NFR-REL-03 | Sync conflicts shall be resolved using server-side timestamps (server-wins for bookings; client-wins for item tab additions). |
| NFR-REL-04 | Data sync status shall be visible to the user (synced / pending / failed indicators). |

### 6.4 Usability

| ID | Requirement |
|----|-------------|
| NFR-UX-01 | The app shall support Android 8.0 (API Level 26) and above. |
| NFR-UX-02 | The booking form shall use inline validation with clear error messages for all required fields. |
| NFR-UX-03 | The interface shall use Material Design 3 (Material You) components for consistency and accessibility. |
| NFR-UX-04 | All date/time fields shall use native Android date-time pickers. |
| NFR-UX-05 | The app shall support both Light and Dark themes. |

### 6.5 Scalability

| ID | Requirement |
|----|-------------|
| NFR-SCALE-01 | The data architecture shall support adding new hotel properties without schema changes. |
| NFR-SCALE-02 | The Appwrite backend shall support horizontal scaling via its cloud infrastructure. |
| NFR-SCALE-03 | The item catalogue shall support up to 500 items without UI performance degradation. |

---

## 7. Tech Stack Recommendations

### 7.1 Frontend (Mobile)

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Framework | Flutter (Dart) | Cross-platform, single codebase, excellent Material 3 support |
| State Management | Riverpod 2.x | Type-safe, scalable, async-friendly; ideal for Appwrite reactive data |
| Local Database | Isar (preferred) or Hive | High-performance NoSQL local DB with offline-first support |
| Navigation | GoRouter | Declarative, supports deep links and role-based guard routes |
| Image Handling | `image_picker` + `flutter_image_compress` | Camera/gallery access with compression before upload |
| Forms | `reactive_forms` or `flutter_form_builder` | Declarative validation logic, cleaner than manual controllers |
| Charts (Dashboard) | `fl_chart` | Lightweight, customizable Flutter-native charting library |
| Connectivity | `connectivity_plus` | Detect online/offline state to trigger sync |

### 7.2 Backend (BaaS)

| Layer | Technology | Rationale |
|-------|------------|-----------|
| Platform | Appwrite Cloud | Auth, DB, Storage, Functions — fully managed; requested by client |
| Auth | Appwrite Auth (Email/Password) | Session-based, JWT, role claims via user labels or custom attributes |
| Database | Appwrite Databases | NoSQL collections; document-level permissions aligned with RBAC |
| Storage | Appwrite Storage | Restricted buckets for guest photos and ID proof images |
| Server Functions | Appwrite Functions (Node.js / Dart) | Business logic: double-booking prevention, sync conflict resolution, alert triggers |
| Realtime | Appwrite Realtime (WebSocket) | Live dashboard updates when multiple front-desk devices are active |

### 7.3 DevOps & Tooling

| Tool | Purpose |
|------|---------|
| GitHub | Version control, feature branches per module |
| GitHub Actions | CI: lint, test, build APK on pull request |
| Firebase App Distribution | Internal APK distribution to hotel staff for UAT |
| Appwrite Console | Database and storage management during development |
| Figma | UI wireframes and design handoff |

---

## 8. Database Schema

### Collections (Appwrite Databases)

#### `hotels`
| Field | Type | Notes |
|-------|------|-------|
| `hotel_id` | String (auto) | Primary key |
| `name` | String | Hotel name |
| `address` | String | Full address |
| `phone` | String | Contact number |
| `created_by` | String | Admin user ID |
| `created_at` | DateTime | Auto-timestamp |

#### `rooms`
| Field | Type | Notes |
|-------|------|-------|
| `room_id` | String (auto) | Primary key |
| `hotel_id` | String | Foreign key → hotels |
| `room_number` | String | e.g., "101", "201" |
| `room_type` | Enum | Single / Double / Suite |
| `capacity` | Integer | Max guests |
| `rate_per_night` | Float | Base price |
| `status` | Enum | Available / Occupied / Maintenance |

#### `customers`
| Field | Type | Notes |
|-------|------|-------|
| `customer_id` | String (auto) | Primary key |
| `name` | String | Guest full name |
| `dob` | Date | For age calculation |
| `phone` | String | Required |
| `email` | String | Optional |
| `parent_name` | String | Father/Mother name |
| `address` | String | Full address |
| `pincode` | String | Postal code |
| `id_proof_type` | Enum | Aadhaar / PAN / ID Card |
| `id_proof_photo_url` | String | Appwrite Storage file URL |
| `guest_photo_url` | String | Appwrite Storage file URL |

#### `bookings`
| Field | Type | Notes |
|-------|------|-------|
| `booking_id` | String (auto) | Primary key |
| `hotel_id` | String | FK → hotels |
| `room_id` | String | FK → rooms |
| `customer_id` | String | FK → customers |
| `num_guests` | Integer | Number of guests |
| `check_in` | DateTime | Default: now |
| `check_out` | DateTime | Default: +1 day at 11:00 AM |
| `actual_check_out` | DateTime | Filled at departure |
| `payment_mode` | Enum | Cash / Card / UPI / Advance |
| `booking_status` | Enum | Confirmed / Checked Out / Cancelled |
| `booked_by` | String | User ID of staff who created booking |
| `collected_by` | String | User ID of staff who took payment |
| `total_amount` | Float | Room + tab total |
| `created_at` | DateTime | Auto-timestamp |

#### `booking_items` (Guest Tab)
| Field | Type | Notes |
|-------|------|-------|
| `item_id` | String (auto) | Primary key |
| `booking_id` | String | FK → bookings |
| `item_name` | String | e.g., "Tea", "Water" |
| `quantity` | Integer | |
| `unit_price` | Float | |
| `added_by` | String | User ID of staff who added item |
| `added_at` | DateTime | Auto-timestamp |

#### `users`
| Field | Type | Notes |
|-------|------|-------|
| `user_id` | String | Appwrite Auth user ID |
| `name` | String | Full name |
| `email` | String | Login email |
| `role` | Enum | Admin / Manager / Staff |
| `hotel_id` | String | Assigned hotel (nullable for Admin) |
| `is_active` | Boolean | Soft deactivation |

#### `item_catalogue`
| Field | Type | Notes |
|-------|------|-------|
| `catalogue_id` | String (auto) | Primary key |
| `item_name` | String | Display name |
| `default_price` | Float | Editable per booking |
| `category` | String | e.g., Beverages, Food, Services |
| `is_active` | Boolean | |

---

## 9. Development Phases

### Phase 1 — Foundation & Authentication (Weeks 1–2)
- Flutter project setup with folder structure (feature-based architecture)
- Appwrite project creation: configure Auth, initial Collections, Storage buckets
- User authentication screens: Login, session persistence, logout
- Role-based routing with GoRouter guards
- Local database (Isar) setup with sync queue model
- Basic connectivity monitoring

### Phase 2 — Hotel & Room Management (Weeks 3–4)
- Hotel CRUD screens (Admin only)
- Room CRUD with status management (Admin only)
- Room list view for Manager and Staff (read-only)
- Room availability indicator on room list

### Phase 3 — Booking & KYC Module (Weeks 5–7)
- Booking form: all fields as per FR-BOOK-02
- Date of Birth picker with real-time age computation
- Check-in / check-out date-time pickers with hotel defaults
- Camera and gallery integration for guest photo and ID proof
- Image compression and Appwrite Storage upload
- Double-booking prevention via Appwrite Function
- Booking list view with filters (date, status, hotel)
- Booking detail view
- Edit booking (Admin + Manager)
- Checkout flow (update actual departure time, finalize status)

### Phase 4 — Guest Tab & Item Management (Weeks 8–9)
- Item catalogue management (Admin)
- Guest tab screen linked to booking
- Add item flow with quantity and price fields
- Item list per booking with running total
- Role access enforcement on tab (Staff: add only)

### Phase 5 — Dashboard (Weeks 10–11)
- KPI card components
- Monthly earnings bar chart (`fl_chart`)
- Room occupancy grid view
- Payment attribution panel
- Hotel selector for Admin (switch between hotels)
- Offline cache read for dashboard data

### Phase 6 — Offline Sync & Polish (Weeks 12–13)
- Offline write queue implementation
- Sync on reconnect with conflict resolution
- Sync status indicators (bottom bar / icon)
- UI polish: loading states, empty states, error states
- Dark mode implementation
- End-to-end testing on physical devices

### Phase 7 — UAT & Deployment (Week 14)
- Internal beta via Firebase App Distribution
- UAT with hotel front-desk staff
- Bug fixes and feedback incorporation
- Final APK build and release

---

## 10. Milestones

| # | Milestone | Target Week | Deliverable |
|---|-----------|-------------|-------------|
| M1 | Auth + Routing Complete | Week 2 | Working login flow with role-based home screens |
| M2 | Hotel & Room Management Live | Week 4 | Admin can manage hotels and rooms |
| M3 | Booking Module Complete | Week 7 | End-to-end booking creation, edit, and checkout |
| M4 | Guest Tab Feature Live | Week 9 | Staff can add items; bills generate correctly |
| M5 | Dashboard Operational | Week 11 | All KPIs and charts display real data |
| M6 | Offline Sync Stable | Week 13 | App functions fully offline; syncs on reconnect |
| M7 | UAT Sign-Off & Release | Week 14 | Signed APK delivered; training session conducted |

---

## 11. Deliverables

| Deliverable | Description | Format |
|-------------|-------------|--------|
| Flutter Source Code | Complete, version-controlled codebase | GitHub Repository |
| APK (Debug + Release) | Android application binaries | `.apk` files |
| Appwrite Config Export | Database schema, Storage rules, Function code | JSON + source files |
| API Integration Guide | Document describing all Appwrite collection queries and permissions | Markdown |
| User Manual | Role-specific usage guide for Admin, Manager, Staff | PDF |
| Database Schema Diagram | Visual ERD of all collections and relationships | PNG / PDF |
| UAT Report | Test cases and results from hotel staff testing | Excel / PDF |

---

## 12. Risks & Mitigations

| # | Risk | Severity | Probability | Mitigation Strategy |
|---|------|----------|-------------|---------------------|
| R1 | Unreliable internet at hotel front desk causes sync loss | High | Medium | Offline-first architecture with persistent write queue; sync retry with exponential backoff |
| R2 | Double-booking race condition when two devices book simultaneously | High | Low | Server-side Appwrite Function checks room availability atomically before confirming booking |
| R3 | Large KYC image uploads slow down booking creation | Medium | High | Client-side image compression to ≤500 KB before upload; background upload with local bookmark |
| R4 | Role escalation: staff accesses restricted data via API manipulation | High | Low | Appwrite Collection Permissions enforced server-side; UI restrictions alone are insufficient |
| R5 | Appwrite cloud outage during peak hotel hours | High | Low | Offline cache handles reads; write queue ensures no data loss; status page monitoring |
| R6 | Flutter version upgrade breaks plugin compatibility | Medium | Medium | Lock Flutter SDK version in `pubspec.yaml`; upgrade only after compatibility testing |
| R7 | Staff resistance to adopting digital system | Medium | High | Simple, minimal-tap UI for staff flows; conduct in-hotel training session before launch |
| R8 | Incorrect checkout date/time causing billing errors | Medium | Medium | Default values enforced by system; checkout form requires explicit confirmation step |
| R9 | Appwrite Storage costs exceed budget with image growth | Low | Medium | Image compression policy; periodic archival of old KYC images after 1 year |

---

## 13. Future Enhancements

The following features are scoped for post-launch releases and are explicitly excluded from the current development plan to maintain focused delivery:

### V2.0 — Aadhaar OCR Autofill
- Integrate an on-device OCR library (e.g., Google ML Kit Text Recognition) to scan Aadhaar card photos and auto-populate guest name, DOB, address, and pincode in the booking form.
- Reduces manual data entry errors at check-in and speeds up the booking process significantly.

### V2.1 — Messaging & Notifications
- **SMS/WhatsApp Bill Delivery**: At checkout, send itemized bill to guest's registered phone number via Twilio or MSG91 API triggered by an Appwrite Function.
- **Admin Checkout Alerts**: Push notifications (Firebase Cloud Messaging) to Admin/Manager when a guest's checkout time is within 1 hour.
- **Advance Booking Reminder**: Automated reminder to the front-desk staff for next-day check-ins.

### V2.2 — Advanced Reporting
- Exportable monthly revenue reports as PDF or Excel.
- Occupancy rate trend analysis (weekly, monthly, quarterly).
- Staff performance reports: bookings handled, items added, collections.

### V2.3 — Web Admin Panel
- Flutter Web companion app for Admin users to manage hotels, run reports, and manage user accounts from a desktop browser — sharing the same Appwrite backend.

### V2.4 — Multi-Language Support
- Hindi (hi_IN) locale support for hotel staff in regional markets.

### V2.5 — Online Booking Integration
- Customer-facing web booking form that creates a pre-booking record in the system, pending front-desk confirmation.

---

## Appendix A: Role Permission Matrix

| Action | Admin | Manager | Staff |
|--------|-------|---------|-------|
| Add / Edit Hotel | ✅ | ❌ | ❌ |
| Add / Edit / Delete Room | ✅ | ❌ | ❌ |
| Create Booking | ✅ | ✅ | ❌ |
| View Booking Details | ✅ | ✅ | ✅ |
| Edit Confirmed Booking | ✅ | ✅ | ❌ |
| Delete Booking | ✅ | ❌ | ❌ |
| Add Item to Guest Tab | ✅ | ✅ | ✅ |
| Edit / Remove Item from Tab | ✅ | ✅ | ❌ |
| View Dashboard | ✅ | ✅ | ❌ |
| Manage Users | ✅ | ❌ | ❌ |
| Manage Item Catalogue | ✅ | ❌ | ❌ |
| Process Checkout | ✅ | ✅ | ❌ |

---

## Appendix B: Folder Structure (Flutter)

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/          # Connectivity & sync queue
│   └── utils/
├── data/
│   ├── datasources/      # Appwrite + Isar data sources
│   ├── models/           # Data models (booking, room, user, etc.)
│   └── repositories/     # Repository pattern implementations
├── domain/
│   ├── entities/
│   └── usecases/
├── presentation/
│   ├── auth/
│   ├── dashboard/
│   ├── bookings/
│   ├── rooms/
│   ├── hotels/
│   ├── items/
│   └── users/
├── shared/
│   ├── widgets/          # Reusable UI components
│   └── theme/            # Material 3 theme config
└── main.dart
```

---

*End of Document — Version 1.0*
