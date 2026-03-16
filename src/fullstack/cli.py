"""CLI entry point: scaffold a new full-stack project."""

import argparse
import os
import stat
import subprocess
import sys
from importlib import metadata, resources
from pathlib import Path


def validate_name(name: str) -> str:
    """Ensure project name is a valid Python identifier."""
    if not name.isidentifier():
        raise argparse.ArgumentTypeError(
            f"{name!r} is not a valid Python identifier"
        )
    if name.startswith("_"):
        raise argparse.ArgumentTypeError(
            "Project name should not start with an underscore"
        )
    return name


def render(content: str, name: str, title: str, context: dict[str, bool]) -> str:
    """Process ##if/##else/##endif conditionals, then replace placeholders."""
    lines = content.splitlines(keepends=True)
    output: list[str] = []
    # Stack of (emitting, seen_true) — emitting = should we include lines?
    stack: list[tuple[bool, bool]] = []

    for line in lines:
        stripped = line.strip()

        if stripped.startswith("##if "):
            var = stripped[5:].strip()
            parent_emitting = all(s[0] for s in stack) if stack else True
            val = context.get(var, False)
            stack.append((parent_emitting and val, val))
            continue

        if stripped == "##else":
            if not stack:
                output.append(line)
                continue
            parent_emitting = all(s[0] for s in stack[:-1]) if len(stack) > 1 else True
            _, seen_true = stack[-1]
            stack[-1] = (parent_emitting and not seen_true, True)
            continue

        if stripped == "##endif":
            if stack:
                stack.pop()
            continue

        # Only emit if all conditions on the stack are true
        if all(s[0] for s in stack) if stack else True:
            output.append(line)

    result = "".join(output)
    return result.replace("{{name}}", name).replace("{{title}}", title)


# Files that are only included when auth is enabled
_AUTH_ONLY_FILES = {
    "src/__package__/auth.py.tpl",
    "src/__package__/routes/auth_routes.py.tpl",
    "tests/test_auth.py.tpl",
    "frontend/src/contexts/AuthContext.tsx.tpl",
    "frontend/src/components/ProtectedRoute.tsx",
    "frontend/src/pages/Login.tsx.tpl",
}


def scaffold(name: str, dest: Path, *, db: str, auth: bool) -> None:
    """Copy and render templates into dest directory."""
    title = name.replace("_", " ").title()
    context: dict[str, bool] = {
        "AUTH": auth,
        "NOAUTH": not auth,
        "SQLITE": db == "sqlite",
        "POSTGRES": db == "postgres",
    }
    templates = resources.files("fullstack") / "templates"

    for item in _walk(templates):
        rel = str(item).split("templates/", 1)[1]

        # Skip the _variants directory during main walk
        if rel.startswith("_variants/"):
            continue

        # Skip auth-only files when auth is disabled
        if not auth and rel in _AUTH_ONLY_FILES:
            continue

        # Rename __package__ directory to project name
        rel = rel.replace("__package__", name)

        # Determine if this is a template or verbatim file
        is_template = rel.endswith(".tpl")
        if is_template:
            rel = rel[:-4]  # strip .tpl extension

        out_path = dest / rel
        out_path.parent.mkdir(parents=True, exist_ok=True)

        content = item.read_text(encoding="utf-8")
        if is_template:
            content = render(content, name, title, context)

        out_path.write_text(content, encoding="utf-8")

    # Copy variant files (database.py, conftest.py) from _variants/{db}/
    variants_dir = templates / "_variants" / db
    for item in _walk(variants_dir):
        rel = str(item).split(f"_variants/{db}/", 1)[1]
        rel = rel.replace("__package__", name)

        is_template = rel.endswith(".tpl")
        if is_template:
            rel = rel[:-4]

        out_path = dest / rel
        out_path.parent.mkdir(parents=True, exist_ok=True)

        content = item.read_text(encoding="utf-8")
        if is_template:
            content = render(content, name, title, context)

        out_path.write_text(content, encoding="utf-8")


def _walk(directory: resources.abc.Traversable) -> list[resources.abc.Traversable]:
    """Recursively collect all files in a traversable directory."""
    files: list[resources.abc.Traversable] = []
    for item in directory.iterdir():
        if item.is_file():
            files.append(item)
        elif item.is_dir():
            files.extend(_walk(item))
    return files


def run_cmd(cmd: list[str], cwd: Path, *, quiet: bool = False) -> bool:
    """Run a shell command, returning True on success."""
    try:
        subprocess.run(cmd, cwd=cwd, check=True, capture_output=True, text=True)
        return True
    except FileNotFoundError:
        if not quiet:
            print(f"  ⚠ {cmd[0]} not found, skipping")
        return False
    except subprocess.CalledProcessError as e:
        if not quiet:
            print(f"  ⚠ {' '.join(cmd)} failed:")
            if e.stderr:
                for line in e.stderr.strip().splitlines()[:5]:
                    print(f"    {line}")
        return False


def prompt_db() -> str:
    """Prompt user to choose a database backend."""
    print("Database backend:")
    print("  1) SQLite  (zero-config, file-based — great for dev & single-server)")
    print("  2) PostgreSQL  (production-grade, requires DATABASE_URL)")
    while True:
        choice = input("Choose [1]: ").strip()
        if choice in ("", "1"):
            return "sqlite"
        if choice == "2":
            return "postgres"
        print("  Please enter 1 or 2.")


def prompt_auth() -> bool:
    """Prompt user to choose auth mode."""
    print("\nAuthentication:")
    print("  1) Multi-user JWT auth  (registration, login, per-user data)")
    print("  2) No auth  (single-user / local tool — no login required)")
    while True:
        choice = input("Choose [1]: ").strip()
        if choice in ("", "1"):
            return True
        if choice == "2":
            return False
        print("  Please enter 1 or 2.")


def main() -> None:
    """Entry point for the fullstack CLI."""
    parser = argparse.ArgumentParser(
        prog="fullstack",
        description="Scaffold a new AI-native full-stack project",
    )
    parser.add_argument(
        "-v", "--version",
        action="version",
        version=f"%(prog)s {metadata.version('fullstack')}",
    )
    parser.add_argument(
        "project_name",
        type=validate_name,
        help="Project name (must be a valid Python identifier)",
    )
    parser.add_argument(
        "--db",
        choices=["sqlite", "postgres"],
        default=None,
        help="Database backend (default: prompt)",
    )
    parser.add_argument(
        "--no-auth",
        action="store_true",
        default=False,
        help="Skip auth scaffolding (single-user / local tool mode)",
    )
    args = parser.parse_args()

    name: str = args.project_name
    dest = Path.cwd() / name

    if dest.exists() and any(dest.iterdir()):
        print(f"Error: {dest} already exists and is not empty")
        sys.exit(1)

    # Determine options (prompt if not provided via flags)
    db: str = args.db if args.db else prompt_db()
    auth: bool = not args.no_auth
    if args.db is None and not args.no_auth:
        # Only prompt for auth if user didn't pass --no-auth
        auth = prompt_auth()

    title = name.replace("_", " ").title()
    db_label = "PostgreSQL" if db == "postgres" else "SQLite"
    auth_label = "JWT auth" if auth else "no auth"
    print(f"\nCreating {title} at ./{name}/ ({db_label}, {auth_label})\n")

    # 1. Scaffold files
    scaffold(name, dest, db=db, auth=auth)
    print("  ✓ Project files created")

    # 2. Make start.sh executable
    start_sh = dest / "start.sh"
    if start_sh.exists():
        start_sh.chmod(start_sh.stat().st_mode | stat.S_IEXEC)
        print("  ✓ start.sh made executable")

    # 3. Git init
    if run_cmd(["git", "init"], dest):
        print("  ✓ Git repository initialized")

    # 4. Install Python deps
    if run_cmd(["uv", "sync"], dest):
        print("  ✓ Python dependencies installed")

    # 5. Install frontend deps
    if run_cmd(["npm", "--prefix", "frontend", "install"], dest):
        print("  ✓ Frontend dependencies installed")

    # 6. Install git hooks (pre-commit, commit-msg, post-commit, pre-push)
    if run_cmd(
        [
            "uv", "run", "pre-commit", "install",
            "--hook-type", "pre-commit",
            "--hook-type", "commit-msg",
            "--hook-type", "post-commit",
            "--hook-type", "pre-push",
        ],
        dest,
    ):
        print("  ✓ Git hooks installed")

    # 7. Initial commit (retry once — pre-commit hooks may fix whitespace)
    run_cmd(["git", "add", "-A"], dest)
    if not run_cmd(
        ["git", "commit", "-m", "chore: initial scaffold from fullstack"],
        dest,
        quiet=True,
    ):
        run_cmd(["git", "add", "-A"], dest)
        if run_cmd(
            ["git", "commit", "-m", "chore: initial scaffold from fullstack"], dest
        ):
            print("  ✓ Initial commit created")
        else:
            print("  ⚠ Initial commit failed — run manually")
    else:
        print("  ✓ Initial commit created")

    # 8. Post-scaffold instructions
    print(f"\nDone! Next steps:\n")
    print(f"  cd {name}")

    if db == "postgres":
        print("  cp .env.example .env       # Set DATABASE_URL")

    print("  ./start.sh          # Start dev servers (backend :8000, frontend :5173)")
    print("  open http://localhost:5173")
    print()
    print("  # Or talk to Claude:")
    print("  claude")
    print()
    print("Your CLAUDE.md is ready — Claude knows how to build on this project.")
    print()


if __name__ == "__main__":
    main()
