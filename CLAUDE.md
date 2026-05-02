# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FootHeroes — Flutter mobile app for grassroots football players and coaches. iOS + Android. Dart SDK `^3.11.4`, Flutter stable.

## Common Commands

```bash
flutter run                      # Run on connected device
flutter run -d <device_id>       # Run on specific device
flutter analyze                  # Static analysis (run before every commit)
flutter test                     # All tests
flutter test test/path/to/test.dart  # Single test file
flutter test --coverage          # With coverage
flutter pub get                  # Install dependencies
flutter build apk                # Android build
flutter build ios                # iOS build (macOS only)
flutter pub run build_runner build --delete-conflicting-outputs  # Code gen (freezed, json_serializable, riverpod_generator)
```

## Architecture

### State & Routing

- **Riverpod** (`flutter_riverpod`) for all state. No `setState` beyond local UI. Providers in `lib/providers/` and `lib/core/providers/`.
- **GoRouter** (`go_router`) for navigation. All routes in `lib/core/router/app_router.dart`. Route constants in `AppRoutes` class — use these, never hardcode path strings. Shell route wraps bottom nav. Redirect guards on auth state.
- **Hive** for offline persistence — `pending_events`, `active_match`, `local_ratings`, `app_preferences` boxes.

### Backend

- **Appwrite** backend (`appwrite: 23.0.0`). Single service class `lib/services/appwrite_service.dart` wraps `Client`, `Databases`, `Account`, `Storage`, `Functions`, `Messaging`, `Realtime`. All collection IDs in `lib/environment.dart`.
- No local REST API — providers delegate to repositories which call Appwrite directly.
- Repositories in `lib/repositories/` handle data access + computation. Example: `PlayerProfileRepository.getCareerStats()` fetches matches + events, then computes goals/assists/ratings/hat-tricks/WDL entirely in Dart.

### Feature Structure

Features live in `lib/features/<name>/`. Each feature follows a loose clean-architecture pattern with `data/`, `domain/`, `presentation/` subdirectories (most heavily used in `find_nearby`). Simpler features skip domain layer and use flat files.

Key features:
| Feature | Path | Purpose |
|---------|------|---------|
| Home | `features/home/` | Player + coach dashboards, tab switching |
| Match | `features/match/` | Match creation, live tracking, formations, lineups, half-time, summary |
| Find Nearby | `features/find_nearby/` | Location-based match discovery, join requests, venue picker |
| Tournament | `features/tournament/` | Tournament creation, brackets, standings |
| Team | `features/team/` | Squad management, team chat |
| Learning | `features/learning/` | Learning hub, drills library, skill challenges |
| Profile | `features/profile/` | Player profile, season stats |
| Leaderboard | `features/leaderboard/` | Rankings, pro comparison |
| Auth | `features/auth/` | Login, signup, position selection, splash |

### Dual-Mode App

App has two personas via `UserMode` enum (`player`, `coach`). Toggled through `userModeProvider`. The `HomeScreen` switches between `PlayerHomeWidget` and `CoachHomeWidget`. Bottom nav tabs differ per mode.

### Theme System

`lib/theme/app_theme.dart` — large static class with all design tokens. Uses Google Fonts (Outfit, Bebas Neue, DM Sans, Chakra Petch). Dark colour system with brand colors: `brandOrange` (#E65100), `cardinal` (alias for brandOrange), `warmDark` (#1C0A00), `parchment`, `gold`, `voidBg`, `cardSurface` (#FFFFFF). Pre-built gradients: `heroCtaGradient`, `heroGradient`, `accentCardGradient`, `radialGlowOverlay`, `scaffoldGradient`. Standardized card decorations: `standardCard`, `cardShadow`, `cardBorder`, `cardBorderLight`. Pre-built text styles: `bebasDisplay`, `dmSans`, `bodyReg`, `bodyBold`, `heroName`, `heroStat`, `cardNumber`, `cardLabel`, etc.

### Season System

`lib/core/utils/season_util.dart` — season = Jul 1 through Jun 30. `seasonLabel(DateTime)` → "2025/26". `seasonDateRange("2025/26")` → (2025-07-01, 2026-06-30). Repository `getCareerStats()` accepts optional `seasonStart`/`seasonEnd` to filter match date ranges.

### Shared Widgets

`lib/widgets/cards.dart` — stat card system: `HeroCard` (gradient hero), `GlassCard` (white glass), `AccentCard` (orange gradient + progress), `BreakdownCard` (horizontal stat row), `DarkCard` (light orange gradient + form badges), `EmptyStateCard`.
`lib/widgets/premium_app_bar.dart` — translucent glass appbar with backdrop blur.
`lib/widgets/custom_bottom_nav.dart` — 5-tab floating glass nav with animated pill indicator.

## Tests

Tests in `test/`. Uses `flutter_test` + `mocktail` for mocking. Target: `lib/` mirror under `test/`.

## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use code-review-graph MCP tools BEFORE Grep/Glob/Read to explore the codebase.** Faster, cheaper, structural context that file scanning cannot provide.

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — risk-scored analysis |
| `get_review_context` | Source snippets for review — token-efficient |
| `get_impact_radius` | Blast radius of a change |
| `get_affected_flows` | Which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | High-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

Fall back to Grep/Glob/Read only when graph doesn't cover what you need.

## Skill Routing

When user request matches an available skill, invoke it via Skill tool FIRST. Do not answer directly.

- Product ideas, brainstorming → office-hours
- Bugs, errors, "why is this broken" → investigate
- Ship, deploy, push, create PR → ship
- QA, test the site, find bugs → qa
- Code review, check my diff → review
- Update docs after shipping → document-release
- Weekly retro → retro
- Design system, brand → design-consultation
- Visual audit, design polish → design-review
- Architecture review → plan-eng-review
- Save progress, checkpoint, resume → checkpoint
- Code quality, health check → health
- Frontend/UI design → frontend-design
