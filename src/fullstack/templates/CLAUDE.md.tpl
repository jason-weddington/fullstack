## Build and Test Commands
```bash
uv sync                              # Install Python dependencies
uv run pytest                        # Run tests
uv run pytest --cov={{name}}         # Tests with coverage report
uv run ruff check .                  # Lint
uv run ruff format .                 # Format
uv run mypy src/                     # Type check
uv run pre-commit run --all-files    # Run all pre-commit hooks

# Install git hooks (not carried by git clone)
uv run pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type post-commit --hook-type pre-push

npm --prefix frontend install        # Install frontend dependencies
npm --prefix frontend run dev        # Start frontend dev server (port 5173)
npm --prefix frontend run test       # Run frontend tests (vitest)
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

## Commit Convention
This repo uses **conventional commits** enforced by a `commit-msg` hook. Format: `type(optional-scope): description`

- `feat:` — new feature (bumps minor)
- `fix:` — bug fix (bumps patch)
- `chore:` — maintenance, deps, config (no bump)
- `docs:` — documentation only (no bump)
- `refactor:` — restructuring (no bump)
- `feat!:` or `fix!:` — breaking change (bumps major)

Releases are automated via a post-commit hook on main. When a `feat:` or `fix:` commit lands on main, `semantic-release version` runs automatically — bumps pyproject.toml, updates CHANGELOG.md and uv.lock, commits, and tags. You just need to `git push origin main --tags` after.

## Code Style
- **Python**: Ruff (linting + formatting), mypy strict mode, Google-style docstrings
- **TypeScript**: ESLint + strict tsconfig (noUnusedLocals, noUnusedParameters)
- **Pre-commit hooks**: Enforced on every commit (ruff, mypy, eslint, tsc, gitleaks secrets detection, trailing whitespace, etc.)
- **Pre-push hooks**: Test coverage enforcement — `git push` is blocked if coverage drops below the `fail_under` threshold in `pyproject.toml`
- Planning directory is excluded from Python linting
- Local hooks that use `uv run` (mypy, pytest, etc.) use `uv run --frozen` to prevent uv from rebuilding the package mid-hook

## Testing Discipline
Tests must be written alongside the code they cover, not bolted on after the fact. When implementing a new feature or fixing a bug:
- **Backend**: Write unit tests for any new pure functions, model defaults, or service logic. Use `hypothesis` for property-based tests where inputs have mathematical invariants (distances, roundtrips, encodings). Privacy-critical paths require explicit test coverage before merging.
- **Frontend**: Write vitest tests for any new pure/exported utility functions. Keep testable logic in pure functions (e.g., `utils.ts`) separate from React components.
- **Run tests before committing**: `uv run pytest` and `npm --prefix frontend run test` should both pass.
- **Ratchet coverage**: After adding tests, increase `fail_under` in `pyproject.toml [tool.coverage.report]` up to the new coverage floor. Coverage should only ever go up.

## Design Principles
- **Proximity** — related controls live next to the content they affect
- **Consistency** — same patterns for same problems (dialogs, loading states, error handling)
- **Sensible defaults** — every setting has a smart default so users can start immediately
- **Keyboard composability** — keyboard shortcuts for common actions, forms submit on Enter
- **Adapt to context** — empty states guide users, populated states show data efficiently
- **Progressive disclosure** — show core actions up front, advanced options in settings/dialogs
- **Minimal chrome** — content-first layout, UI gets out of the way
- **No dead ends** — app logo/title in the header always navigates home; every screen should be escapable
- **Privacy by default** — users who don't understand and just click OK must be protected. Defaults are always the safest option. Users who understand the implications can explicitly open things up.
- **Human verification for critical paths** — AI-generated code that handles privacy or security must produce outputs a human can independently verify. Write scripts, tests, or tooling that make verification easy. "The AI wrote it" is not a defense — the human is accountable, so make accountability painless.

## Patterns to Follow
The notes app (`note_routes.py`, `Dashboard.tsx`, etc.) is example scaffolding that demonstrates the project's patterns. Replace it with your actual domain — don't build alongside it.

- **Backend CRUD**: See `note_routes.py` — ownership checks, PATCH with partial updates, 204 on DELETE
- **API client**: See `api.ts` — namespaced methods, automatic snake/camelCase conversion, token handling
- **Dialogs**: See `Dashboard.tsx` — shared create/edit dialog distinguished by null/non-null editing state
- **State management**: `useState` + `useEffect` for API data, `useCallback` for stable fetch functions
- **Auth flow**: JWT tokens stored in localStorage, `AuthContext` provides login/register/logout
- **Theme**: Dark/light toggle via `ThemeContext`, persisted in localStorage
