# Hostel Management System - Folder Responsibilities

## Root
- `apps/hostel_app/`: Flutter application (Android + Web).
- `firebase/`: Firebase rules, indexes, and backend functions.
- `docs/`: Architecture, engineering decisions, onboarding notes.
- `scripts/`: Local and CI helper scripts (build/test/deploy tasks).

## Flutter App (`apps/hostel_app/lib`)
- `main.dart`: App bootstrap (Flutter binding, global error handling, Firebase initialization, top-level providers).
- `app/`: Application shell and composition root.
  - `app.dart`: `MaterialApp.router` setup, theme, and app-level provider consumption.
  - `app_router.dart`: Route map, auth/role guards, navigation orchestration.
- `core/`: Shared, framework-agnostic primitives reused across features.
  - `auth/`: Session and identity contracts/state (`AuthSessionProvider`).
  - `theme/`: Material Design theme tokens and ThemeData definitions.
  - `errors/`, `utils/`, `constants/`, `network/`: Shared technical foundations.
- `services/`: Cross-feature integrations (notifications, storage, auth adapters, etc.).
- `shared/`: Reusable UI widgets and extensions independent of one feature.
- `features/`: Feature-first clean architecture modules.

## Feature Module Pattern (`features/<feature_name>/`)
- `domain/`: Pure business logic (`entities`, repository contracts, use-cases).
- `data/`: Data access implementations (`datasources`, models/DTOs, repository implementations).
- `presentation/`: UI layer (pages, widgets, providers/controllers).

## Role Separation
- Student flows live under relevant feature presentation folders (`student/`).
- Warden flows live under (`warden/`).
- Admin flows live under (`admin/`).

This separation enforces authorization boundaries at both routing and feature level, and keeps domain logic reusable across roles.
