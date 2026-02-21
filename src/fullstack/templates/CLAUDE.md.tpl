## Build and Test Commands
```bash
uv sync                              # Install Python dependencies
uv run pytest                        # Run tests
uv run ruff check .                  # Lint
uv run ruff format .                 # Format
uv run mypy src/                     # Type check
uv run pre-commit run --all-files    # Run all pre-commit hooks

npm --prefix frontend install        # Install frontend dependencies
npm --prefix frontend run dev        # Start frontend dev server (port 5173)
npm --prefix frontend run build      # Production build

./start.sh                           # Start both backend + frontend dev servers
```

## Project Structure
```
{{name}}/
├── src/{{name}}/              # Python backend (FastAPI)
│   ├── main.py                # App entry point, lifespan, CORS
│   ├── auth.py                # JWT + bcrypt auth utilities
│   ├── database.py            # Async SQLite (aiosqlite, WAL mode)
│   ├── models.py              # Pydantic v2 domain + API models
│   └── routes/
│       ├── auth_routes.py     # Register, login, logout, me
│       └── note_routes.py     # Notes CRUD (example resource)
├── tests/                     # Python tests (pytest)
├── frontend/                  # React + TypeScript + MUI 6 (Vite)
│   └── src/
│       ├── api.ts             # Typed API client with snake/camelCase conversion
│       ├── types.ts           # TypeScript interfaces
│       ├── contexts/          # Auth + Theme providers
│       ├── components/        # Layout, Sidebar, ProtectedRoute
│       └── pages/             # Login, Dashboard, Settings
├── docs/                      # Project documentation
├── planning/                  # Feature planning docs
│   ├── templates/             # feature.md template
│   └── <branch-name>/        # Per-branch planning (mirrors git branch)
│       └── feature.md         # Feature requirements and design
├── pyproject.toml             # Python config (deps, ruff, mypy, pytest)
└── start.sh                   # Dev server launcher
```

## Planning Convention
When starting a feature branch, create `planning/<branch-name>/feature.md` to capture requirements and design decisions before coding. This serves as a durable reference artifact. Use Claude's built-in task tools for implementation tracking.

## Code Style
- **Python**: Ruff (linting + formatting), mypy strict mode, Google-style docstrings
- **TypeScript**: ESLint + strict tsconfig (noUnusedLocals, noUnusedParameters)
- **Pre-commit hooks**: Enforced on every commit (ruff, mypy, trailing whitespace, etc.)
- Planning directory is excluded from Python linting

## Design Principles
- **Proximity** — related controls live next to the content they affect
- **Consistency** — same patterns for same problems (dialogs, loading states, error handling)
- **Sensible defaults** — every setting has a smart default so users can start immediately
- **Keyboard composability** — keyboard shortcuts for common actions, forms submit on Enter
- **Adapt to context** — empty states guide users, populated states show data efficiently
- **Progressive disclosure** — show core actions up front, advanced options in settings/dialogs
- **Minimal chrome** — content-first layout, UI gets out of the way
- **No dead ends** — app logo/title in the header always navigates home; every screen should be escapable

## Patterns to Follow
- **Backend CRUD**: See `note_routes.py` — ownership checks, PATCH with partial updates, 204 on DELETE
- **API client**: See `api.ts` — namespaced methods, automatic snake/camelCase conversion, token handling
- **Dialogs**: See `Dashboard.tsx` — shared create/edit dialog distinguished by null/non-null editing state
- **State management**: `useState` + `useEffect` for API data, `useCallback` for stable fetch functions
- **Auth flow**: JWT tokens stored in localStorage, `AuthContext` provides login/register/logout
- **Theme**: Dark/light toggle via `ThemeContext`, persisted in localStorage
