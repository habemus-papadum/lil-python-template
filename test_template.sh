#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing lil-python-template copier template${NC}"

# Clean up any previous test runs
TEST_DIR="test-generated-project"
if [ -d "$TEST_DIR" ]; then
    echo -e "${YELLOW}Cleaning up previous test directory...${NC}"
    rm -rf "$TEST_DIR"
fi

# Create test project using copier
echo -e "${YELLOW}Running copier to generate test project...${NC}"
copier copy --defaults --trust --vcs-ref=HEAD \
    -d package_name="test-awesome-package" \
    -d package_description="A test package generated from the template" \
    -d python_version="3.12" \
    -d author_name="Test User" \
    -d author_email="test@example.com" \
    -d github_username="testuser" \
    -d init_git_and_github=false \
    . "$TEST_DIR"

cd "$TEST_DIR"

echo -e "${YELLOW}Generated project structure:${NC}"
find . -type f -not -path './.git/*' -not -path './.venv/*' | sort

# Verify critical files exist
echo -e "${YELLOW}Verifying critical files exist...${NC}"
REQUIRED_FILES=(
    "pyproject.toml"
    "README.md"
    "LICENSE"
    ".gitignore"
    ".python-version"
    ".env.vscode"
    ".vscode/settings.json"
    "src/test_awesome_package/__init__.py"
    "src/test_awesome_package/py.typed"
    "tests/__init__.py"
    "tests/test_example.py"
    "mkdocs.yml"
    "docs/index.md"
    "docs/reference.md"
    "docs/demos/README.md"
    "docs/demos/topics/README.md"
    "release.sh"
    "nb.sh"
    "test_notebooks.sh"
    "AGENTS.md"
    ".github/workflows/ci.yml"
    ".github/workflows/docs.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ] || [ -L "$file" ]; then
        echo -e "${GREEN}✓${NC} $file exists"
    else
        echo -e "${RED}✗${NC} $file is missing!"
        exit 1
    fi
done

# Verify docs/index.md is a symlink to README.md
echo -e "${YELLOW}Verifying docs/index.md symlink...${NC}"
if [ -L "docs/index.md" ]; then
    TARGET=$(readlink "docs/index.md")
    if [ "$TARGET" = "../README.md" ]; then
        echo -e "${GREEN}✓${NC} docs/index.md is a symlink to ../README.md"
    else
        echo -e "${RED}✗${NC} docs/index.md symlink target is wrong: $TARGET"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} docs/index.md is not a symlink!"
    exit 1
fi

# Check Python version
echo -e "${YELLOW}Checking Python version...${NC}"
EXPECTED_VERSION="3.12"
ACTUAL_VERSION=$(cat .python-version)
if [ "$ACTUAL_VERSION" = "$EXPECTED_VERSION" ]; then
    echo -e "${GREEN}✓${NC} Python version is correct: $ACTUAL_VERSION"
else
    echo -e "${RED}✗${NC} Python version mismatch! Expected: $EXPECTED_VERSION, Got: $ACTUAL_VERSION"
    exit 1
fi

# Check that uv sync was run (should have created .venv)
if [ -d ".venv" ]; then
    echo -e "${GREEN}✓${NC} Virtual environment created by post-generation task"
else
    echo -e "${YELLOW}!${NC} Virtual environment not found, running uv sync manually..."
    uv sync
fi

# Test that the package can be imported
echo -e "${YELLOW}Testing package import...${NC}"
if uv run python -c "import test_awesome_package; print(f'Package version: {test_awesome_package.__version__}')"; then
    echo -e "${GREEN}✓${NC} Package imports successfully"
else
    echo -e "${RED}✗${NC} Package import failed!"
    exit 1
fi

# Run pytest tests
echo -e "${YELLOW}Running pytest tests...${NC}"
if uv run pytest; then
    echo -e "${GREEN}✓${NC} All tests passed"
else
    echo -e "${RED}✗${NC} Tests failed!"
    exit 1
fi

# Test ruff check
echo -e "${YELLOW}Running ruff check...${NC}"
if uv run ruff check .; then
    echo -e "${GREEN}✓${NC} Ruff check passed"
else
    echo -e "${RED}✗${NC} Ruff check failed!"
    exit 1
fi

# Test ruff format (dry run)
echo -e "${YELLOW}Running ruff format check...${NC}"
if uv run ruff format --check .; then
    echo -e "${GREEN}✓${NC} Ruff format check passed"
else
    echo -e "${RED}✗${NC} Code needs formatting!"
    exit 1
fi

# Test building the package
echo -e "${YELLOW}Building the package...${NC}"
if uv build; then
    echo -e "${GREEN}✓${NC} Package built successfully"
    echo "Build artifacts:"
    ls -lh dist/
else
    echo -e "${RED}✗${NC} Package build failed!"
    exit 1
fi

# Test mkdocs build
echo -e "${YELLOW}Building documentation...${NC}"
if uv run mkdocs build; then
    echo -e "${GREEN}✓${NC} Documentation built successfully"
else
    echo -e "${RED}✗${NC} Documentation build failed!"
    exit 1
fi

# Note: Skipping notebook tests as no notebooks exist initially
# Users should add notebooks and test with ./test_notebooks.sh

# Verify scripts are executable
echo -e "${YELLOW}Verifying scripts are executable...${NC}"
EXECUTABLE_SCRIPTS=(
    "release.sh"
    "publish.sh"
    "nb.sh"
    "test_notebooks.sh"
)

for script in "${EXECUTABLE_SCRIPTS[@]}"; do
    if [ -x "$script" ]; then
        echo -e "${GREEN}✓${NC} $script is executable"
    else
        echo -e "${RED}✗${NC} $script is not executable!"
        exit 1
    fi
done

# Verify pyproject.toml has correct content
echo -e "${YELLOW}Verifying pyproject.toml content...${NC}"
if grep -q 'name = "test-awesome-package"' pyproject.toml; then
    echo -e "${GREEN}✓${NC} Package name is correct in pyproject.toml"
else
    echo -e "${RED}✗${NC} Package name is incorrect in pyproject.toml"
    exit 1
fi

if grep -q 'requires-python = ">=3.12"' pyproject.toml; then
    echo -e "${GREEN}✓${NC} Python version requirement is correct"
else
    echo -e "${RED}✗${NC} Python version requirement is incorrect"
    exit 1
fi

# Verify coverage configuration exists
echo -e "${YELLOW}Verifying coverage configuration...${NC}"
if grep -q '\[tool.coverage.run\]' pyproject.toml; then
    echo -e "${GREEN}✓${NC} Coverage configuration found in pyproject.toml"
else
    echo -e "${RED}✗${NC} Coverage configuration missing from pyproject.toml"
    exit 1
fi

# Verify pytest-cov dependency
if grep -q 'pytest-cov' pyproject.toml; then
    echo -e "${GREEN}✓${NC} pytest-cov dependency found"
else
    echo -e "${RED}✗${NC} pytest-cov dependency missing"
    exit 1
fi

# Verify mkdocs-jupyter dependency
if grep -q 'mkdocs-jupyter' pyproject.toml; then
    echo -e "${GREEN}✓${NC} mkdocs-jupyter dependency found"
else
    echo -e "${RED}✗${NC} mkdocs-jupyter dependency missing"
    exit 1
fi

# Verify CI workflow includes coverage
echo -e "${YELLOW}Verifying CI workflow...${NC}"
if grep -q 'pytest --cov=' .github/workflows/ci.yml; then
    echo -e "${GREEN}✓${NC} CI workflow includes coverage reporting"
else
    echo -e "${RED}✗${NC} CI workflow missing coverage reporting"
    exit 1
fi

# Verify docs workflow triggers on release
if grep -q 'release:' .github/workflows/docs.yml; then
    echo -e "${GREEN}✓${NC} Docs workflow triggers on release"
else
    echo -e "${RED}✗${NC} Docs workflow doesn't trigger on release"
    exit 1
fi

cd ..

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}All tests passed! ✓${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Clean up
echo -e "${YELLOW}Cleaning up test directories...${NC}"
rm -rf "$TEST_DIR"
echo -e "${GREEN}Done!${NC}"
