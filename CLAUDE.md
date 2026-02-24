# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A pip-installable CLI (`fullstack`) that scaffolds new AI-native full-stack projects. It generates a complete app with FastAPI + React + MUI, opinionated tooling, and a CLAUDE.md that teaches Claude how to build on the generated project. The generated CLAUDE.md *is* the product — it turns non-technical users into product owners.

## Build and Test Commands
```bash
# This repo has no tests or linting of its own — it's a scaffolding tool.
# To test, scaffold a project and verify it works:
uv sync                                          # Install fullstack CLI deps
uv run fullstack my_test_app                     # Scaffold a new project
cd my_test_app && ./start.sh                     # Verify it runs (backend :8000, frontend :5173)
fullstack --version                              # Check installed version

# Inside a generated project, these commands apply:
uv run pytest                                    # Backend tests
uv run pytest --cov=<project_name>               # Backend tests with coverage
uv run pytest tests/test_specific.py::test_name  # Run a single test
uv run ruff check .                              # Lint
uv run ruff format .                             # Format
uv run mypy src/                                 # Type check (strict)
uv run pre-commit run --all-files                # All pre-commit hooks
npm --prefix frontend install                    # Install frontend deps
npm --prefix frontend run test                   # Frontend tests (vitest)
npm --prefix frontend run build                  # Production build

# Release workflow (in this repo):
uvx semantic-release version                     # Bump version, update CHANGELOG.md, tag
uvx semantic-release publish                     # (if publishing to PyPI)
```

## Architecture

### Scaffolding Engine (`src/fullstack/cli.py`)

The CLI walks `src/fullstack/templates/`, processes `.tpl` files by replacing `{{name}}` and `{{title}}` placeholders, renames `__package__` directories to the project name, then runs `git init`, `uv sync`, `npm install`, `pre-commit install` (with both pre-commit and pre-push hook types), and an initial commit.

Files without `.tpl` are copied verbatim. The `.tpl` extension is stripped in the output.

### Generated Project Stack

**Backend** (`templates/src/__package__/`):
- FastAPI with async lifespan (init/close database)
- Async SQLite via aiosqlite with WAL mode, singleton connection
- JWT auth (HS256, 72h expiry) + bcrypt, `get_current_user` dependency
- Pydantic v2 models, prefix-based routers (`/api/auth`, `/api/notes`)
- PATCH for partial updates, 204 on DELETE, ownership checks on all resources

**Frontend** (`templates/frontend/src/`):
- React 19 + TypeScript + MUI 7 + Vite
- Context API for state: `AuthContext` (login/register/logout/token) and `ThemeContext` (dark/light)
- `api.ts`: namespaced API client with automatic snake_case/camelCase conversion on all request/response payloads
- `ProtectedRoute` component wraps authenticated pages
- Vite proxies `/api` to `localhost:8000` in dev

**Key conventions in generated code:**
- localStorage keys are prefixed with the project name (`{{name}}-token`, `{{name}}-user`)
- 401 responses auto-clear tokens and redirect to `/login`
- Shared create/edit dialogs distinguished by null/non-null editing state
- Notes app is example scaffolding meant to be replaced, not built alongside

### Tooling in Generated Projects
- **Python**: Ruff (linting + formatting), mypy strict, Google-style docstrings, hypothesis for property-based tests
- **TypeScript**: ESLint, strict tsconfig (noUnusedLocals, noUnusedParameters)
- **Pre-commit**: ruff, mypy, eslint, tsc, gitleaks (secrets detection), trailing whitespace, end-of-file fixer, YAML/TOML checks, file size limits
- **Pre-push**: Test coverage enforcement via pytest-cov with `fail_under` threshold (blocks `git push` if coverage drops)
- **DeprecationWarning as error**: pytest treats DeprecationWarnings as errors to prevent deprecated code from accumulating
- `planning/` directory excluded from Python linting

## Commit Convention

This repo uses **conventional commits** enforced by a `commit-msg` hook. All commit messages must follow the format:

```
type(optional-scope): description

optional body
```

Common types:
- `feat:` — new feature (bumps minor version)
- `fix:` — bug fix (bumps patch version)
- `chore:` — maintenance, deps, config (no version bump)
- `docs:` — documentation only (no version bump)
- `refactor:` — code change that neither fixes a bug nor adds a feature (no version bump)
- Add `!` after type for breaking changes: `feat!:` (bumps major version)

`python-semantic-release` reads these prefixes to auto-determine version bumps and generate CHANGELOG.md.

## Modifying Templates

When editing templates, keep in mind:
- `.tpl` files undergo placeholder substitution; non-`.tpl` files are copied as-is
- `__package__` in directory paths gets renamed to the project name
- Only `{{name}}` and `{{title}}` placeholders are supported (title is name with underscores replaced by spaces, title-cased)
- The generated `CLAUDE.md.tpl` is the most important template — it teaches Claude how to work with generated projects
- After changing templates, scaffold a test project to verify the output
