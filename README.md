<div align="center">

```
███████╗████████╗ █████╗ ██╗   ██╗███████╗██╗   ██╗███╗   ██╗  ██████╗
██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝██╔════╝╚██╗ ██╔╝████╗  ██║ ██╔════╝
███████╗   ██║   ███████║ ╚████╔╝ ███████╗ ╚████╔╝ ██╔██╗ ██║ ██║
╚════██║   ██║   ██╔══██║  ╚██╔╝  ╚════██║  ╚██╔╝  ██║╚██╗██║ ██║
███████║   ██║   ██║  ██║   ██║   ███████║   ██║   ██║ ╚████║ ╚██████╗
╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚══════╝   ╚═╝   ╚═╝  ╚═══╝  ╚═════╝
```

### 🏨 Multi-Tenant Hotel Management — Built from Zero. Shipped in 14 Weeks.

[![Flutter](https://img.shields.io/badge/Flutter-3.44.1-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Appwrite](https://img.shields.io/badge/Appwrite-Cloud-F02E65?style=flat-square&logo=appwrite&logoColor=white)](https://appwrite.io)
[![Dart](https://img.shields.io/badge/Dart-3.12.1-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=flat-square)]()
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android&logoColor=white)]()

> *From a paper booking register to a full-stack Android app — real problem, real product, real code.*

[📱 Features](#-features) · [🏗 Architecture](#-architecture) · [🚀 Getting Started](#-getting-started) · [📸 Screenshots](#-screenshots) · [🧩 Tech Stack](#-tech-stack)

</div>

---

## 💡 The Problem This Solves

Two hotel properties in Patna. One paper register. Zero visibility into occupancy, revenue, or guest history.

**StaySync** replaces that paper chaos with a production-grade Android app — offline-first, multi-property, role-protected — built entirely with Flutter and Appwrite from scratch in 8 iterative phases over 14 weeks.

This is **not a tutorial clone**. Every line of code was written to solve a real operational problem.

---

## ✨ Features

| Module | What It Does |
|---|---|
| 🔐 **Auth + RBAC** | Email/password login via Appwrite with 3 role tiers — Admin, Manager, Staff. Session persisted locally. |
| 🏨 **Hotel & Room Management** | Admin-only CRUD for properties and rooms. Room status auto-updates on booking events. |
| 📋 **Bookings + KYC** | Full guest form — DOB, ID proof photo, guest photo, double-booking prevention (client-side + Appwrite). |
| 🧾 **Guest Tab (POS)** | Per-booking charge tracking (beverages, meals, extras) with staff attribution. |
| 💰 **Smart Billing** | Auto-calculated checkout: `Total = (nights × room rate) + tab items`. |
| 📊 **Dashboard Analytics** | KPI cards, `fl_chart` monthly revenue graph, colour-coded room occupancy grid. |
| 🔄 **Offline-First Sync** | SQLite write queue — works without internet, syncs in background. Conflict resolution: *server-wins* for bookings, *client-wins* for items. |
| 🌙 **Polish & UX** | Empty states, error states, form validation (regex), ₹ Indian currency, Dark mode — Material 3. |

---

## 🏗 Architecture

StaySync uses a **Clean Architecture** approach with 4 distinct layers:

```
lib/
├── core/               # Constants, errors, routing (GoRouter), utils
│   ├── constants/      # AppwriteConstants, app-wide config
│   ├── errors/         # Failure types, exception handling
│   └── routes/         # GoRouter + RBAC navigation guards
│
├── data/               # Data sources, repositories, models
│   ├── datasources/    # Appwrite (remote) + SQLite (local) DAOs
│   ├── models/         # JSON serialisation / deserialisation
│   └── repositories/  # Offline-first: local-first fetch, background remote sync
│
├── domain/             # Pure business logic — no Flutter, no Appwrite
│   ├── entities/       # AppUser, Hotel, Room, Booking, Customer, BookingItem
│   └── usecases/       # (planned for v2 expansion)
│
└── presentation/       # UI — Riverpod AsyncNotifiers, GoRouter screens
    ├── auth/           # Login screen, AuthNotifier
    ├── hotels/         # Hotel list, form, room list, room form
    ├── bookings/       # Booking list, detail, form (KYC + imagepicker)
    ├── items/          # Item catalogue, add-item bottom sheet
    ├── dashboard/      # KPI cards, fl_chart revenue graph, occupancy grid
    └── shared/         # Reusable widgets, theme, empty/error states
```

### Key Design Decisions

```
┌─────────────────────────────────────────────────────────┐
│                     PRESENTATION                        │
│         Riverpod 2.x AsyncNotifiers + GoRouter          │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────┐
│                    REPOSITORIES                         │
│   Local-first read → background Appwrite sync           │
│   Write Queue for offline mutations                     │
└────────────┬─────────────────────────┬──────────────────┘
             │                         │
┌────────────▼──────────┐  ┌───────────▼──────────────────┐
│  LOCAL (sqflite)      │  │  REMOTE (Appwrite Cloud)      │
│  7 SQLite tables      │  │  7 Collections + 2 Buckets    │
│  Instant reads        │  │  Auth, DB, Storage, Realtime  │
└───────────────────────┘  └──────────────────────────────┘
```

---

## 🧩 Tech Stack

```
Frontend        Flutter 3.44.1 · Dart 3.12.1 · Material 3
State Mgmt      Riverpod 2.x (AsyncNotifier pattern)
Routing         GoRouter with RBAC redirect guards
Local DB        sqflite (offline-first write queue)
Backend         Appwrite Cloud (Auth · Database · Storage · Realtime)
Charts          fl_chart
Forms           reactive_forms + reactive_date_time_picker
Media           image_picker + flutter_image_compress
CI/CD           GitHub Actions → Firebase App Distribution
Platform        Android (minSdk 21, compileSdk 36)
```

---

## 🗄 Database Schema

**7 Appwrite Collections · 2 Storage Buckets**

```
hotels          id, name, address, phone, hotelId
rooms           id, roomNo, type, status, rate, hotelId
bookings        id, customerId, roomId, checkIn, checkOut,
                status, totalBill, payment, hotelId
customers       id, name, dob, phone, idProofType, idProofUrl, photoUrl
bookingitems    id, bookingId, itemId, qty, unitPrice, staffId
itemcatalogue   id, name, category, price, hotelId
users           id, name, email, role, hotelId, isActive

Storage Buckets:
  guest-photos    → KYC guest photos
  id-proofs       → Government ID document images
```

---

## 🚀 Getting Started

### Prerequisites

```bash
Flutter >= 3.22.0
Dart   >= 3.3.0
Java   >= 21
Android Studio / VS Code
Appwrite Cloud account (free tier works)
```

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/AdarshvijaycX/StaySync.git
cd StaySync

# 2. Install dependencies
flutter pub get

# 3. Configure Appwrite
#    Open lib/core/constants/appwrite_constants.dart
#    Fill in your Project ID, Database ID, and Collection IDs

# 4. Run the app
flutter run
```

### Appwrite Setup

Provision all 7 collections and 2 storage buckets automatically:

```bash
# Run the provisioning script (requires Appwrite API key)
node scripts/provision_appwrite.js
```

> The script creates all collections with correct attributes, indexes, and permissions — and patches `appwrite_constants.dart` automatically.

### Demo Credentials

| Role | Email | Password |
|---|---|---|
| Admin | admin@nami.in | password123 |
| Manager | manager@nami.in | password123 |
| Staff | staff@nami.in | password123 |

---

## 📅 Build Phases

This app was built in 8 structured phases — each with a written implementation plan, approved before coding:

| Phase | What Was Built | Duration |
|---|---|---|
| 1 | Project scaffold, folder structure, all dependencies | Week 1–2 |
| 2 | Auth, RBAC, role-based home screens, session cache | Week 2–3 |
| 3 | Hotel & Room Management (CRUD, offline sync) | Week 3–5 |
| 4 | Booking & KYC module (imagepicker, double-booking) | Week 5–7 |
| 5 | Guest Tab / POS (item catalogue, add-item sheet) | Week 7–9 |
| 6 | Dashboard Analytics (fl_chart, KPI grid) | Week 9–11 |
| 7 | Offline sync queue + conflict resolution | Week 11–13 |
| 8 | Polish — empty states, validation, dark mode, APK | Week 13–14 |

---

## 🧠 Engineering Highlights

**Offline-First Architecture**
All reads hit SQLite first — zero network latency for the user. Writes go to the local queue immediately and sync to Appwrite in the background. If the network is down, operations never block.

**Conflict Resolution Strategy**
- Bookings: *server-wins* — the Appwrite record is the source of truth for check-in/check-out to prevent race conditions.
- Guest tab items: *client-wins* — staff additions are trusted locally since they happen in real-time at point of sale.

**RBAC Navigation Guards**
GoRouter's `redirect` callback checks the cached user role on every navigation. Attempting to access an admin-only route as Staff silently redirects to the role home — no flash, no error.

**KYC Photo Pipeline**
`image_picker` → `flutter_image_compress` (80% quality) → Appwrite Storage bucket → URL stored in customer document. Works from both camera and gallery for emulator compatibility.

---

## 🗺 Roadmap

- [ ] iOS platform support
- [ ] Web dashboard (Flutter Web)
- [ ] Appwrite Functions for server-side double-booking validation
- [ ] Push notifications (check-in reminders, payment alerts)
- [ ] Multi-currency support
- [ ] PDF invoice generation on checkout
- [ ] Analytics export (CSV / Excel)

---

## 👨‍💻 About the Developer

**Adarsh Vijay** — Engineering student passionate about building products that solve real problems.

This project demonstrates:
- ✅ End-to-end mobile app development (idea → production APK)
- ✅ Clean Architecture and separation of concerns in Flutter
- ✅ Backend-as-a-service integration (Appwrite)
- ✅ Offline-first data strategy with conflict resolution
- ✅ Role-based access control design
- ✅ Real-world UX decisions (KYC flows, double-booking prevention, billing logic)
- ✅ Iterative, phase-based delivery with written implementation plans

> *"I didn't build this to learn Flutter. I built it to solve a real problem — and Flutter was the right tool."*

📧 Connect on [GitHub](https://github.com/AdarshvijaycX) · [LinkedIn](#)

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

**⭐ Star this repo if StaySync impressed you — it helps more than you know.**

*Built with Flutter · Powered by Appwrite · Made in Patna, India 🇮🇳*

</div>
