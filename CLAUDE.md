# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter mobile application (iOS/Android) using Dart. The project is a newly generated Flutter app with the default counter template.

## Common Commands

```bash
# Run the app
flutter run

# Run on a specific device
flutter run -d <device_id>

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Analyze code for errors and warnings
flutter analyze

# Build for iOS (requires macOS)
flutter build ios

# Build for Android
flutter build apk

# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade
```

## Code Architecture

- **Entry point**: `lib/main.dart` - Contains `MyApp` widget and `MyHomePage` stateful widget
- **Platform folders**: `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` - Platform-specific code
- **Tests**: `test/widget_test.dart` - Default smoke test for the counter widget
- **Dependencies**: Managed in `pubspec.yaml` with Flutter SDK constraint `^3.11.4`

## Code Style

- Uses `flutter_lints` (from `package:flutter_lints/flutter.yaml`)
- Material Design 3 with `uses-material-design: true`
- Lint rules can be customized in `analysis_options.yaml`

## Notes

- The app uses `ColorScheme.fromSeed(seedColor: Colors.deepPurple)` for theme generation (line 31 in main.dart has a syntax issue - `ColorScheme.` is incomplete)
- Main widget state is managed with `setState` in `_MyHomePageState`

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
