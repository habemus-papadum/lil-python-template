# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Copier template for generating modern Python packages with UV dependency management. It generates project scaffolding with pre-configured tooling, optional documentation, and optional GitHub integration.

## Architecture

**Copier Template Structure:**
- `copier.yml` - Template configuration defining user prompts, conditional file exclusions, and post-generation tasks
- `template/` - The template directory containing all Jinja2 templates (`.jinja` files) that are rendered during project generation
- `test_template.sh` - Comprehensive test script that validates template generation with different configurations

**Key Design Patterns:**
- Template uses Jinja2 templating with the `jinja2_time.TimeExtension` for date/time support
- Conditional file inclusion/exclusion based on user responses (docs, GitHub Actions)
- Post-generation tasks run automatically via `_tasks` in `copier.yml` to initialize git, create GitHub repo, and optionally publish to PyPI
- Variable naming convention: `package_name` (kebab-case) vs `package_slug` (snake_case for Python modules)

**Generated Project Structure:**
- `src/` layout (best practice for Python packages)
- PEP 517/518 compliant with `pyproject.toml` and Hatchling build backend
- Dependency groups in `pyproject.toml` (not requirements.txt) - dev dependencies are in `[dependency-groups]`
- Type hints supported via `py.typed` marker file
- VSCode integration via `.vscode/settings.json` and `.env.vscode`

## Common Commands

### Testing the Template

Run the full template test suite:
```bash
./test_template.sh
```

This script:
- Generates a test project with docs enabled
- Verifies all expected files exist
- Tests package import, pytest, ruff, build, and mkdocs
- Generates a minimal project without docs
- Validates both configurations work correctly

### Generating a Project from Template

Local template generation (for testing):
```bash
copier copy . /tmp/test-project
```

With specific options (bypassing prompts):
```bash
copier copy --defaults --trust \
  -d package_name="my-package" \
  -d python_version="3.12" \
  -d include_docs=true \
  -d include_github_actions=true \
  -d init_git_and_github=false \
  . /path/to/output
```

### Working with Generated Projects

From within a generated project:
```bash
# Install dependencies
uv sync

# Run tests
uv run pytest

# Lint and format
uv run ruff check .
uv run ruff format .

# Build package
uv build

# Build docs (if included)
uv run mkdocs build
uv run mkdocs serve  # Serve locally at http://127.0.0.1:8000

# Publish to PyPI
./publish.sh
```

## Important Implementation Notes

### Template Variables

The main variables defined in `copier.yml`:
- `package_name` - Kebab-case package name (e.g., "my-awesome-package")
- `package_slug` - Snake_case Python module name derived from package_name
- `python_version` - Python version requirement (e.g., "3.12")
- `include_docs` - Boolean for mkdocs documentation setup
- `include_github_actions` - Boolean for GitHub Actions workflow
- `init_git_and_github` - Boolean to auto-initialize git and create GitHub repo
- `publish_to_pypi` - Boolean to auto-publish after GitHub repo creation (only shown if `init_git_and_github` is true)

### Conditional File Exclusion

Files/directories are excluded via `_exclude` in `copier.yml`:
- Docs files excluded when `include_docs=false`
- `.github/` excluded when `include_github_actions=false`

### Post-Generation Tasks

The `_tasks` section in `copier.yml` runs these commands after generation:
1. `uv sync` - Always runs to create venv and install dependencies
2. Git initialization (if `init_git_and_github=true`)
3. GitHub repo creation via `gh repo create` (if `init_git_and_github=true`)
4. PyPI publishing via `./publish.sh` (if both `init_git_and_github=true` and `publish_to_pypi=true`)

### Testing Strategy

The `test_template.sh` script validates:
1. File generation (all expected files exist)
2. Template variable substitution (correct names, versions in files)
3. Functionality (package import, pytest, ruff, build, mkdocs)
4. Conditional exclusions (docs files absent when `include_docs=false`)
5. Multiple Python versions (3.11 vs 3.12)

## Template File Patterns

All template files use `.jinja` extension and Jinja2 syntax:
- `{{ variable }}` - Variable substitution
- `{% if condition %}...{% endif %}` - Conditional content
- Dynamic file/directory names use `{{ package_slug }}` in path

Example: `template/src/{{ package_slug }}/__init__.py.jinja` becomes `src/my_package/__init__.py` after rendering.

## UV Dependency Management

Generated projects use UV (not pip):
- Add dependencies: `uv add package-name`
- Add dev dependencies: `uv add --group dev package-name`
- Dependencies defined in `pyproject.toml` under `[project.dependencies]` and `[dependency-groups]`
- `uv.lock` file tracks exact versions (similar to `poetry.lock` or `package-lock.json`)

## GitHub Integration Details

When `init_git_and_github=true`, post-generation tasks:
1. Initialize git repository
2. Create initial commit with message "Initial commit from lil-python-template"
3. Create public GitHub repository using GitHub CLI (`gh repo create`)
4. Set remote origin to `https://github.com/{username}/{package-name}`
5. Push initial commit

Requires:
- GitHub CLI installed and authenticated (`gh auth login`)
- PyPI credentials configured (if `publish_to_pypi=true`)
