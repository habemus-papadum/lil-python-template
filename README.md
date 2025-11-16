# lil-python-template

A [Copier](https://copier.readthedocs.io/) template for Python packages using UV for dependency management.

## What This Template Creates

This template generates a modern Python package with:

- **UV-based dependency management** - Fast, reliable Python package management
- **PEP 517/518 compliant** - Uses `pyproject.toml` with Hatchling as the build backend
- **Source layout** - Package code in `src/` directory following best practices
- **Pytest configuration** - Pre-configured testing with pytest and example tests
- **VSCode integration** - Ready-to-use settings for Python testing and debugging
- **Ruff configuration** - Modern, fast Python linter and formatter
- **Type hints support** - Includes `py.typed` marker for type checking
- **MIT License** - Open source license ready to go
- **Comprehensive .gitignore** - Pre-configured for Python projects
- **Automatic Git & GitHub setup** - Optionally initializes git and creates GitHub repo with one command
- **Optional mkdocs documentation** - Material theme with mkdocstrings for API docs
- **Optional GitHub Actions** - Automated documentation deployment to GitHub Pages

## Prerequisites

- [UV](https://docs.astral.sh/uv/) - Install with: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [Copier](https://copier.readthedocs.io/) - Install with: `uv tool install copier`
- [GitHub CLI](https://cli.github.com/) (optional) - Required if you want automatic GitHub repo creation

## Usage

### Creating a New Project

```bash
copier copy gh:habemus-papadum/lil-python-template /path/to/your/new/project
```

Or if you have this repo cloned locally:

```bash
copier copy /path/to/lil-python-template /path/to/your/new/project
```

You'll be prompted for:

- **package_name** - The package name (default: directory name)
- **package_slug** - Python module name (auto-derived from package_name)
- **package_description** - Brief description of your package
- **python_version** - Python version (default: `3.12`)
- **author_name** - Your name (default: `Nehal Patel`)
- **author_email** - Your email (default: `nehal@alum.mit.edu`)
- **github_username** - GitHub username (default: `habemus-papadum`)
- **init_git_and_github** - Initialize git and create GitHub repository (default: `true`)

### After Generation

The template automatically runs `uv sync` to set up your environment.

**If `init_git_and_github` is enabled (default: `true`):**
- Initializes a git repository
- Makes an initial commit with all files
- Creates a public GitHub repository under your account
- Sets the remote origin to the GitHub repository
- Pushes the initial commit to GitHub
- Optionally publishes to PyPI to reserve the package name (if `publish_to_pypi` is true)

This requires:
- [GitHub CLI](https://cli.github.com/) to be installed and authenticated (`gh auth login`)
- PyPI credentials configured for publishing (via `~/.pypirc` or environment variables) if `publish_to_pypi` is enabled

**Then you can:**

```bash
cd /path/to/your/new/project

# Activate the virtual environment (if not using uv run)
source .venv/bin/activate

# Run your package
uv run python -c "import your_package; print(your_package.__version__)"

# Run tests
uv run pytest

# Format and lint
uv run ruff format .
uv run ruff check .

# Build documentation (if included)
uv run mkdocs serve
```

## Project Structure

```
your-package/
├── .github/
│   └── workflows/
│       └── docs.yml          # GitHub Actions workflow (optional)
├── .vscode/
│   └── settings.json         # VSCode Python testing configuration
├── docs/                      # Documentation (optional)
│   ├── index.md
│   └── reference.md
├── src/
│   └── your_package/
│       ├── __init__.py
│       └── py.typed
├── tests/                     # Test directory
│   ├── __init__.py
│   └── test_example.py
├── .env.vscode                # Environment variables for VSCode
├── .gitignore
├── .python-version
├── LICENSE
├── mkdocs.yml                 # mkdocs config (optional)
├── publish.sh                 # Script to build and publish to PyPI
├── pyproject.toml
├── README.md
└── uv.lock                    # Created by UV
```

## Features

### UV Dependency Management

This template uses UV, which provides:
- Fast dependency resolution
- Reliable virtual environment management
- Compatible with pip, but much faster
- Support for PEP 621 `pyproject.toml` format

### Dependency Groups

The template includes a `dev` dependency group in `pyproject.toml`:
- `hatch` - For building and publishing
- `pytest` - For running tests
- `ruff` - For linting and formatting
- `mkdocs` packages (if documentation is enabled)

Add more dependencies with:

```bash
# Runtime dependency
uv add requests

# Development dependency
uv add --group dev pytest-cov
```

### Ruff Configuration

Pre-configured with sensible defaults:
- Line length: 120
- Target version: Matches your Python version
- Selects: E (errors), F (pyflakes), W (warnings), I (isort)

Customize in `pyproject.toml` under `[tool.ruff]`.

### Testing with Pytest

The template comes with pytest pre-configured and ready to use:
- Test directory: `tests/`
- Configuration in `pyproject.toml` under `[tool.pytest.ini_options]`
- Includes `-s` flag by default (shows print statements)
- Example test file included to get you started

Run tests with:
```bash
uv run pytest
```

The pytest configuration includes:
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-s"
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
```

Add test coverage with:
```bash
uv add --group dev pytest-cov
uv run pytest --cov=src
```

### VSCode Integration

The template includes pre-configured VSCode settings for Python development:
- **`.vscode/settings.json`** - Pytest configuration for VSCode's testing UI
  - Tests automatically discovered in `tests/` directory
  - `-s` flag enabled by default (shows print statements)
  - Points to `.env.vscode` for environment variables
- **`.env.vscode`** - Environment variables file for VSCode Python extension
  - Add any environment variables needed for development/debugging
  - Not ignored by git (intentionally committed with examples)

**VSCode Testing UI:**
Open the Testing view in VSCode (flask icon in the sidebar) to:
- Run individual tests or entire test suites
- Debug tests with breakpoints
- See test output and results inline

### Git & GitHub Integration

When `init_git_and_github` is enabled (default), the template automatically:
- Initializes a new git repository
- Creates an initial commit with message "Initial commit from lil-python-template"
- Creates a public GitHub repository using the GitHub CLI
- Sets the remote origin to `https://github.com/{username}/{package-name}`
- Pushes the initial commit to GitHub

This streamlines the process of going from template to published repository in seconds.

**Requirements:**
- GitHub CLI must be installed: `brew install gh` (macOS) or see [cli.github.com](https://cli.github.com/)
- Must be authenticated: `gh auth login`

**To skip this feature:**
Set `init_git_and_github` to `false` when prompted, or use:
```bash
copier copy -d init_git_and_github=false gh:habemus-papadum/lil-python-template /path/to/project
```

### GitHub Pages Deployment

If you included GitHub Actions (`include_github_actions=true`), you need to enable GitHub Pages once before the workflow can deploy:

**One-time Setup:**
1. Push your initial commit to GitHub (or let `init_git_and_github` do this automatically)
2. Go to your repository on GitHub
3. Click on **Settings** → **Pages** (in the left sidebar)
4. Under "Build and deployment", set **Source** to **GitHub Actions**
5. Click **Save**

After this one-time setup, the workflow will automatically:
- Build your mkdocs documentation on every push to `main`
- Deploy it to GitHub Pages
- Make your docs available at `https://{username}.github.io/{package-name}/`

**Why manual setup is needed:**
The default `GITHUB_TOKEN` used by GitHub Actions doesn't have permission to enable Pages automatically. This is a one-time manual step that takes less than 30 seconds.

### PyPI Publishing

The template includes a `publish.sh` script for easy publishing to PyPI:

```bash
./publish.sh
```

This script:
- Removes the old `dist/` directory
- Builds the package using `uv run hatch build`
- Publishes to PyPI using `uv run hatch publish`

**Automatic Publishing (Optional):**
If you enable `publish_to_pypi` when generating the template, it will automatically attempt to publish your package to PyPI immediately after creating the GitHub repository. This is useful for:
- Reserving your package name on PyPI early
- Ensuring the name is available before setting up the project

**Prerequisites:**
Configure your PyPI credentials before publishing:
- Create a PyPI API token at https://pypi.org/manage/account/token/
- Configure it in `~/.pypirc`:
  ```ini
  [pypi]
  username = __token__
  password = pypi-YourTokenHere
  ```

**Note:** If automatic publishing fails (e.g., name already taken), you can manually delete the created GitHub repository if needed. The package name availability check happens early in the process to avoid wasted effort.

## Updating Projects

If you update this template, you can update existing projects:

```bash
cd /path/to/your/project
copier update
```

## License

MIT License - see LICENSE file for details.