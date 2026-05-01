# Repository Guidelines

## Project Structure & Module Organization

This is a Flutter/Dart app named `rep_swim`. App startup lives in `lib/main.dart`, with top-level app wiring in `lib/app.dart`. Shared utilities, constants, and theme code belong in `lib/core/`. SQLite-related code is grouped in `lib/database/`, with DAOs under `lib/database/daos/`.

Feature code is organized under `lib/features/<feature>/` using layered folders where needed:

- `domain/` for entities, repositories, and services.
- `data/` for datasources and repository implementations.
- `presentation/` for screens and Riverpod providers.

Tests mirror source areas under `test/`, for example `test/core/utils/duration_utils_test.dart` and `test/features/pb/pb_service_test.dart`.

## Build, Test, and Development Commands

- `dart pub get` installs Dart and Flutter dependencies from `pubspec.yaml`.
- `flutter test` runs the test suite.
- `flutter analyze` runs static analysis using `analysis_options.yaml`.
- `dart format lib test` formats Dart files.
- `flutter run` launches the app on an available device or emulator.

Run analysis and tests before opening a pull request.

## Coding Style & Naming Conventions

Use standard Dart formatting with two-space indentation. Follow `package:flutter_lints/flutter.yaml`; this repo also enables `prefer_const_constructors` and `prefer_const_literals_to_create_immutables`.

Use `snake_case.dart` file names, `PascalCase` types, and `camelCase` members. Keep feature-specific code inside its feature folder. Prefer immutable entities and `const` widgets where possible. Riverpod providers should live in the relevant `presentation/providers/` folder and use descriptive names such as `swimRepositoryProvider`.

## Testing Guidelines

Use `flutter_test` for unit and widget tests; use `mocktail` when collaborators need to be mocked. Name test files with the `_test.dart` suffix and group tests by class or behavior, as in `DurationUtils.formatDuration`.

Add or update tests for new business logic, services, utility functions, and data transformations. For UI work, include widget tests when behavior or state changes are non-trivial.

## Commit & Pull Request Guidelines

The current history uses concise conventional-style commits, for example `feat: Build repSwim Flutter app from scratch (#1)`. Prefer messages like `feat: add dryland workout summary`, `fix: handle zero swim distance`, or `test: cover PB calculations`.

Pull requests should include a short description, linked issue when applicable, test results (`flutter test`, `flutter analyze`), and screenshots or recordings for visible UI changes. Keep PRs focused on one feature or fix.

## Agent-Specific Instructions

Do not rewrite unrelated files or generated project metadata. Preserve the feature-layer structure, add tests with behavior changes, and keep documentation updates concise and repository-specific.
