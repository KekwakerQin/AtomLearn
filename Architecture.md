# Architecture

## Module tree

```
Modules/
  Auth/
    Coordinator/
    Data/
    Domain/
    Presentation/
      UI/
  Boards/
  Cards/
  Common/
    UI Extensions/
  Core/
    Networking/
    Supabase/
```

## Placement rules

- **Feature modules** live under `Modules/<FeatureName>` and are split into `Presentation`, `Domain`, `Data`, and `Coordinator` when applicable.
- **Shared UI** belongs in `Modules/Common`, especially reusable views, modifiers, and helpers.
- **Infrastructure and integrations** (networking stacks, SDK wrappers, persistence) belong in `Modules/Core`.
- Avoid placing new code at the repo root; instead, create or reuse an appropriate module folder.

## Roles

- **ViewController**: only UI setup, binding, and rendering (no business logic).
- **ViewModel**: state, business logic, error handling, and service calls.
- **Coordinator**: navigation, screen creation, and flow management.
- **Services**: networking/DB/SDK work without UIKit dependencies.

## Style guide

- **MARK order**:
  1. Dependencies
  2. UI
  3. Init
  4. Lifecycle
  5. Actions
  6. Public API
  7. Private helpers
- **Doc-comments**: add `///` documentation for every non-`private` method/property exposed outside the type.
- **Naming**: use plural names for list screens and match file/class names (e.g., `BadgesViewController` in `BadgesViewController.swift`).
