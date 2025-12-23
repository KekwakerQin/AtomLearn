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
