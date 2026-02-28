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


def render(content: str, name: str, title: str) -> str:
    """Replace template placeholders."""
    return content.replace("{{name}}", name).replace("{{title}}", title)


def scaffold(name: str, dest: Path) -> None:
    """Copy and render templates into dest directory."""
    title = name.replace("_", " ").title()
    templates = resources.files("fullstack") / "templates"

    for item in _walk(templates):
        rel = str(item).split("templates/", 1)[1]

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
            content = render(content, name, title)

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
    args = parser.parse_args()

    name: str = args.project_name
    dest = Path.cwd() / name

    if dest.exists() and any(dest.iterdir()):
        print(f"Error: {dest} already exists and is not empty")
        sys.exit(1)

    title = name.replace("_", " ").title()
    print(f"Creating {title} at ./{name}/\n")

    # 1. Scaffold files
    scaffold(name, dest)
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

    print(f"""
Done! Next steps:

  cd {name}
  ./start.sh          # Start dev servers (backend :8000, frontend :5173)
  open http://localhost:5173

  # Or talk to Claude:
  claude

Your CLAUDE.md is ready — Claude knows how to build on this project.
""")


if __name__ == "__main__":
    main()
