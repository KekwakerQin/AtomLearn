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
    Services/
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

## Adding a new screen

1. **Create Presentation layer**
   - `Modules/<Feature>/Presentation/<Screen>ViewController.swift`
   - `Modules/<Feature>/Presentation/<Screen>ViewModel.swift`
   - If there are UI helpers: `Modules/<Feature>/Presentation/UI/`.
2. **Create Domain layer**
   - `Modules/<Feature>/Domain/Entities/` for models.
   - `Modules/<Feature>/Domain/Services/` for service protocols/business logic.
3. **Create Data layer**
   - `Modules/<Feature>/Data/` for repositories, mappers, and storage.
   - Implement repository protocols defined in Domain (no UIKit dependencies).
4. **Create Coordinator**
   - `Modules/<Feature>/Coordinator/<Feature>Coordinator.swift` for navigation and screen assembly.
   - Coordinator creates VC/VM and injects dependencies (services/repositories).
5. **Wire dependencies**
   - Use factories from `Modules/Common/Services` to select source (Firestore/Supabase/Local).
   - Pass concrete services into ViewModel via initializer.

## Adding new data sources

- **Data layer integration**
  - For each service, define a `...RepositoryProtocol` (or service protocol) in `Domain/Services`.
  - Implement concrete repositories in `Data/` for each source (Firestore/Supabase/Local).
- **Factory connection**
  - Add a `...Factory` conforming to `ServiceProtocol` in the feature module.
  - Use `ServiceFactory.make(..., source:)` to select implementation at runtime.
- **Where it lives**
  - Base factory/types: `Modules/Common/Services/ServiceFactory.swift`.
  - Feature-specific factories/repositories: `Modules/<Feature>/Data/` and `Modules/<Feature>/Domain/Services/`.

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
