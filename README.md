# SpeedCode Labs Staff ERP

Flutter mobile client for the SpeedCode Labs staff ERP. The app mirrors the
burgundy corporate identity of the desktop dashboard and adapts the experience
to Android with bottom navigation, compact cards and mobile-first workflows.

## Features

- Splash, session restore and demo login
- Dashboard: greeting, live attendance time-in/out with reason selection,
  yesterday/today duration chips, attendance timeline and admin notice board
- Attendance time-in/out with optional notes and a completed-day summary
- Notice board with role-gated posting and read tracking
- QR scanner for employee/attendance codes (scan, copy and display only)
- Task board with list/kanban views, filters, search, task details, comments,
  status updates and lightweight attachments
- Chat list and conversation thread with attachments
- Live meetings, leave applications, calendar, shared files, performance
  summary, mailbox and profile/settings
- Notifications with mark-read and mark-all-read
- Fixed five-tab navigation: Dashboard, Chat, Leave, Summary and More; task
  board and calendar remain available from the dashboard menu and More screen
- Light/dark/system theme, persisted preferences and local profile updates
- Mock data mode (default) and a production Dio API layer behind the same
  repository interfaces

## Demo credentials

| Field | Value |
| --- | --- |
| Employee ID | `SCL-001` |
| Password | `password123` |

The mock layer is compiled in by default and only used when `USE_MOCK` is true.
Screens never read mock data directly; only `*_mock_repository.dart` classes do.

## Run

```bash
flutter pub get
flutter run -d chrome          # quick desktop/browser preview
flutter run -d <android-id>    # Android device or emulator
```

### Real backend

```bash
flutter run \
  --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://erp.example.com/api/v1
```

`API_BASE_URL` defaults to `https://api.speedcodelabs.com/api/v1`. Endpoint
paths are declared only in `lib/core/network/api_endpoints.dart`.

The client expects JSON responses and unwraps a top-level `data` envelope when
present. The production repositories map the following areas:

- `/auth/login`, `/auth/logout`, `/auth/me`, `/auth/change-password`
- `/employees/me` and `/employees/status`
- `/dashboard`, `/notices`, `/notifications`
- `/attendance/today`, `/attendance/summary`, `/attendance/time-in`, `/attendance/time-out`
- `/tasks`, `/tasks/stats`, `/tasks/team-progress`, `/tasks/:id`, `/tasks/:id/comments`
- `/chat/conversations`, `/chat/conversations/:id`, `/chat/conversations/:id/messages`
- `/live/meetings`, `/leave/requests`, `/leave/requests/:id`, `/leave/balance`
- `/calendar/events`, `/sharing/files`, `/summary/me`
- `/mailbox`, `/mailbox/:id`, `/mailbox/send`

## Architecture

```text
lib/
  app/                 app widget, theme, router and navigation shell
  core/
    constants/         AppConfig (mock/API flags, version, demo credentials)
    errors/            shared exception types
    mock/              in-memory demo database
    models/            shared Employee model
    network/           Dio client, endpoint constants, response helpers
    storage/           secure tokens and preferences
    utils/             date formatting helpers
    widgets/           cards, buttons, fields, avatars, badges and states
  features/
    authentication/    login, splash, session controller and repository
    dashboard/         dashboard, notifications, notices and widgets
    attendance/        attendance record, repository and controller
    tasks/             task board, detail, domain and repositories
    chat/              conversation list/thread, mappers and repositories
    live/              meetings and join flows
    leave/             leave balance and applications
    calendar/          events, holidays and calendar views
    sharing/           shared file listing and downloads
    summary/           performance and attendance summary
    mailbox/           inbox, folders, detail and compose
    profile/           More grid, settings, profile editing
```

State management uses Riverpod notifiers. Navigation uses GoRouter with a
`StatefulShellRoute` for the five main tabs and top-level routes for full-screen
destinations. Repositories are exposed through providers, which makes swapping
mock and API implementations a compile-time concern.

## Android notes

- The app targets Android by default; the web target is available for previews.
- If Android licenses are not accepted on this machine, run
  `flutter doctor --android-licenses` and accept them before building.
- Check available devices with `flutter devices`; start an emulator from Android
  Studio or with `flutter emulators --launch <id>` if needed.
- Build an APK with `flutter build apk --release`.

## Verification

```bash
flutter analyze
flutter test
flutter build web --release
```

`flutter analyze` currently reports no issues. Tests cover the shared Employee
model, date helpers, and 360px-wide dashboard widget smoke checks.

## Demo limitations

- Chat and email attachments are local demo selections; files are not uploaded.
- Mailbox sending returns a demo outbox result and the UI states that the email
  was not delivered until the backend is connected.
- File downloads are disabled in demo mode and shown as unavailable.
- Push notifications are represented by the in-app notification feed; no FCM
  integration is included.
- The QR scanner is UI-only and does not submit attendance; no backend QR
  attendance endpoint is available.
- Notice attachments are displayed when present but cannot be uploaded because
  no attachment endpoint is implemented.
- Profile edits are limited to name, phone and location; department,
  designation and email are treated as HR-managed fields.
- Reference screenshots can be placed in `assets/reference/` and are bundled at
  build time.
