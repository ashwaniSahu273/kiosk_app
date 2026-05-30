# Kiosk App — Multi-Tenant Masjid Kiosk

A standalone Flutter kiosk application for masjids and organizations. An administrator signs in once and the kiosk displays prayer times, programs, donation categories, and a scan-to-donate QR code — all themed and scoped to that organization.

---

## Overview

The app is designed to run on a wall-mounted landscape touchscreen. After an administrator authenticates, the kiosk renders content exclusively for their organization: branding colors, logo, prayer schedule, available programs, donation categories, and a QR code linking to the organization's donation page.

Multi-tenant behavior is fully data-driven. Onboarding a new organization requires no source code changes — only a new data entry.

---

## How to Run

```bash
flutter run
```

To target a specific device:

```bash
flutter run -d <device-id>
```

List available devices with `flutter devices`.

The app forces landscape orientation and full-screen immersive mode on launch, matching a wall-mounted kiosk display.

---

## Demo Credentials

Two organizations are seeded for offline demo use:

| Organization   | Email                  | Password    |
|----------------|------------------------|-------------|
| Palos Masjid   | `admin@palos.org`      | `palos123`  |
| Masjid An-Noor | `admin@annoor.org`     | `annoor123` |

The login screen also shows these credentials as a hint.

---

## Key Features

- **Multi-tenant theming** — each organization's primary, secondary, and accent colors are applied app-wide at login; switching organizations re-themes the entire UI within 2 seconds.
- **Prayer countdown** — the Next Prayer card shows the day's prayer schedule and a live countdown to the next upcoming prayer, refreshing every second.
- **Available programs** — lists the active organization's programs with a registration form accessible directly from the kiosk.
- **Donation categories** — lists giving options with a donate action per category; an empty list surfaces a disabled donate control per spec.
- **QR code (scan to donate)** — renders a QR code encoding the organization's donation URL so visitors can donate from their own phone.
- **Session persistence** — a completed session survives app restarts; the kiosk resumes the home screen without requiring re-login.
- **Per-section independent loading** — each home screen section loads, retries, and fails independently; one section's error never blocks another.
- **Shimmer placeholders** — animated skeleton loaders shaped like the target content are shown while data is in flight.

---

## Architecture Overview

| Layer | Details |
|---|---|
| **State management** | [GetX](https://pub.dev/packages/get) — controllers, observables, dependency injection, and routing |
| **Modular layout** | `lib/app/modules/<feature>/` — each feature owns its controller, view, and binding |
| **Core services** | `lib/app/core/` — `AuthService`, `KioskRepository`, `OrganizationContext`, `ThemeEngine`, `StorageService`, `NotificationService`, `ApiClient` |
| **Shared widgets** | `lib/app/widgets/` — `KioskButton`, `KioskHeader`, `KioskSidebar`, `KioskTextField`, `SectionCard`, `ShimmerLoader`, and destination scaffold |
| **Config / demo data** | `lib/app/config/demo/palos_demo_config.dart` — seeded organizations; add a new `OrganizationData` entry to onboard another tenant |
| **Routing** | `lib/app/routes/` — `AppRoutes` (named constants) + `AppPages` (GetX page list with `AuthMiddleware` on protected routes) |

### Service wiring (bootstrap order in `main.dart`)

1. `StorageService` — persists sessions and cached branding
2. `NotificationService` — single shared snackbar entry point
3. `ThemeEngine` — builds `ThemeData` from a `BrandingProfile`
4. `OrganizationContext` — drives the observable theme via the engine
5. `DemoDataSource` + `KioskRepository` — back the offline demo
6. `AuthService` — coordinates auth, storage, and organization context
7. `ApiClient` — wired with `AuthService` as its auth/organization context

---

## Project Structure

```
lib/
  main.dart                    # Bootstrap and root widget
  app/
    config/                    # App constants and demo data
    core/
      data/                    # Repository, data source, models
      network/                 # ApiClient, ApiResult
      notifications/           # NotificationService
      services/                # OrganizationContext, ThemeEngine, StorageService
      middleware/               # AuthMiddleware
    modules/
      auth/                    # Login screen, AuthService, LoginController
      home/                    # Home screen, HomeController, section states
      donate/                  # Donate screen and controller
      prayers/                 # Prayers screen and controller
      programs/                # Programs screen and controller
    routes/                    # AppRoutes, AppPages
    widgets/                   # Shared kiosk widgets
assets/
  images/
    kiosk_default_logo.png     # Bundled default logo placeholder
```
