# Animated Football Splash Screen

> **Status:** Approved | **Date:** 2026-05-04

## Goal

Replace current `SplashScreen` with a three-phase animated splash: abstract geometric footballer kicks ball → ball impact burst → "FOOT HEROES" name reveal in Rosnoc font.

## Flow

| Phase | Timing | What happens |
|-------|--------|-------------|
| 1 — Kick | 0-1200ms | Abstract polygonal player winds up, kicks. Hexagon-patterned ball launches. Motion blur trail on leg. |
| 2 — Flight & Impact | 1200-1800ms | Ball arcs diagonally with rotation. Burst particles + concentric ripple on impact. Brief white flash. |
| 3 — Name Reveal | 1800-2600ms | "FOOT HEROES" in Rosnoc scales 0.3→1.0 with overshoot bounce. Letter-spacing wide→tight. "Find Your Game" subtitle fades in. Orange-to-gold gradient fill. |
| 4 — Hold | 2600-3200ms | Settle, fade to black, navigate. |

## Visual Spec

- **Background**: `warmDark` (#1C0A00) with subtle grass-blade texture lines (thin gold lines at low opacity)
- **Player**: Abstract low-poly silhouette, `brandOrange`/`cardinal` (#E65100) fills with `gold` stroke accents. Angular geometry — triangles and quads forming head, torso, legs
- **Ball**: Circle with inner hexagon pattern in white/gold. Rotates during flight
- **Burst**: `sparkBlue` + `cardinal` particles radiating from impact. Concentric gold ring expanding + fading
- **Text**: Rosnoc font, weight 400, 68px "FOOT HEROES" with gradient fill (`cardinal` → `gold`). 14px "Find Your Game" in DM Sans below
- **Particles**: Small circles/diamonds, 15-20 total, random velocities, fade out over 600ms

## Implementation

- **File**: Replace `lib/features/auth/splash_screen.dart`
- **Route**: Stays at `AppRoutes.splash` (`/splash`) — no router changes
- **Auth flow**: Same `_handleNavigation()` — wait 3200ms, check session, route to home/login
- **Animation**: Single `AnimationController` with staggered intervals for each phase. CustomPainters for player, ball, particles, grass texture
- **Font**: `fontFamily: 'Rosnoc'` (already registered in pubspec.yaml, file at `assets/fonts/Rosnoc.otf`)

## Dependencies

None new. Uses existing: `flutter` (CustomPainter, AnimationController), `google_fonts` (for DM Sans subtitle).
