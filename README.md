# fullstack

AI-native full-stack starter kit. Go from zero to a running app in one command, then build on it by talking to Claude.

Designed for rapid ideation and local prototyping — not production use. You're on your own for hardening, security, deployment, etc.

## Quick Start

```bash
uvx --from git+https://github.com/jason-weddington/fullstack.git fullstack my_app
cd my_app
./start.sh
```

Or install it first:

```bash
uv pip install git+https://github.com/jason-weddington/fullstack.git
fullstack my_app
```

## What You Get

- **Backend**: Python 3.13 + FastAPI + async SQLite (aiosqlite)
- **Frontend**: React 19 + TypeScript + Material UI 7 + Vite
- **Auth**: JWT + bcrypt, login/register flow
- **Example app**: Notes CRUD to demonstrate patterns
- **Tooling**: ruff, mypy (strict), pre-commit hooks, pytest, ESLint
- **CLAUDE.md**: The real product — tells Claude how to build on your project

## The Key Insight

The **CLAUDE.md** is the product. It turns non-technical users into product owners who can build real software by talking to Claude. Every project gets an opinionated CLAUDE.md with build commands, project structure, design principles, and patterns to follow.

## Requirements

- Python 3.13+
- Node.js 18+
- [uv](https://docs.astral.sh/uv/) (Python package manager)
