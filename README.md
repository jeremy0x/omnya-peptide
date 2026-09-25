# <img src="assets/logo.png" width="44" height="44" alt="Omnya Peptide Logo" style="vertical-align: middle; margin-right: 8px;" /> Omnya Peptide

A mobile protocol tracker for iOS and Android built for women managing peptides, glow blends, and GLP-1 wellness routines.

Existing trackers record what went in. Omnya Peptide tracks what came out, designed as a calm wellness product rather than a laboratory tool.

## Project Structure

This monorepo contains the mobile client and the backend synchronization API:

```text
peptide/
├── apps/
│   ├── mobile/             # Flutter mobile app for iOS and Android
│   │   ├── lib/
│   │   │   ├── core/       # Colors, typography, glass components, buttons
│   │   │   ├── data/       # Local storage, repositories, API sync client
│   │   │   ├── domain/     # Reconstitution dilution math and outcome correlation
│   │   │   └── ui/         # Onboarding, Today, Progress, Stack, Circle, Photo Read
│   │   └── test/           # Unit, widget, and integration tests
│   └── server/             # Fastify TypeScript server
│       ├── src/            # Auth, data sync, circles, and RevenueCat webhooks
│       └── Dockerfile      # Production container build
├── docker-compose.yml       # Local PostgreSQL and API setup
└── README.md
```

## Design System

- Tone: Warm minimal, comfortable to open in public.
- Explicit constraints: No clinical blue, no needles or syringes, no chemical formulas, no neon accents on black.
- Palette:
  - Cream (`#FDFBF7`): Main canvas
  - Sand (`#F4EFEA`): Card surfaces
  - Taupe (`#B5A496` / `#8C7A6B`): Outlines and labels
  - Plum (`#4A1E35` / `#361325`): Primary actions and accents
  - Charcoal (`#1F1D1C`): Text and dark mode surface
- Typography:
  - Headlines and numbers: Fraunces (serif with tabular figures)
  - Body and controls: Instrument Sans
- Interaction details:
  - Tactile button compression (`scale 0.96`) with light haptic feedback.
  - Horizontal sliding route transitions on non-root screens.
  - Optical liquid glass surfaces with backdrop blur.
  - Linear icons from `hugeicons`.

## Core Screens

### Today
- Next Dose Card: Shows scheduled compound, dose, site rotation, and a one-tap log action.
- Daily Check-in: Three taps for energy, appetite, and optional photo in under 10 seconds.
- Weekly Insight: Contextual note flagging normal cycle water retention (*"Scale is up 2 lb, period is due Thursday. Ignore it."*).

### Progress
- Before/After Slider: Drag to compare baseline with current photo.
- Weight and Cycle Band: Plots weight curve against shaded cycle phases to contextualize water weight.
- Plain-English Correlation: Directly ties adherence to visible changes (*"Since GHK-Cu started: +14% skin brightness, 3 weeks"*).
- Social Export: Generates 9:16 progress cards for Instagram and TikTok stories.

### Stack
- Inventory: Shows compounds, runout dates, cadence, and monthly spend ($312/month).
- Reconstitution Calculator: Volumetric dilution tool calculating insulin syringe units (U-100 and U-40).

### Circle
- Private Group: Invite-only accountability group capped at 5 members.
- Consistency Only: Displays check-in streaks (*"4 of 5 checked in today"*). Weight metrics are hidden by default.

### Weekly Photo Read
- Ghost Camera: Overlays previous week's capture with adjustable opacity to match framing and lighting.
- Honest Deltas: Tracks face fullness, skin evenness, and waistline trends in plain English without fake praise.

## App Store Compliance and Privacy
 
Because most peptides are not FDA-approved, the app follows strict App Store guidelines:
- No vendor links or sourcing information anywhere in the app.
- The reconstitution calculator is framed strictly as a mathematical dilution tool.
- The user enters their own compounds and doses; the app never prescribes dosing.
- Photos remain strictly in an on-device vault protected by Face ID and are never uploaded without explicit export.
- No account is required to start logging protocols.

## Getting Started

### Prerequisites
- Flutter SDK 3.44+
- Node.js 20+
- Docker (optional)

### Mobile App
```bash
cd apps/mobile
flutter pub get
flutter run
```

### Backend Server
```bash
cd apps/server
npm install
npm run build
npm start
```
Default port is 3000. Health check endpoint is at `GET /health`.

### Docker Compose
```bash
docker compose up --build -d
```

## Testing

### Mobile
```bash
cd apps/mobile
flutter analyze
flutter test
```

### Server
```bash
cd apps/server
npm test
```
