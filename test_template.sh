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
copier copy --defaults --trust \
    -d package_name="test-awesome-package" \
    -d package_description="A test package generated from the template" \
    -d python_version="3.12" \
    -d author_name="Test User" \
    -d author_email="test@example.com" \
    -d github_username="testuser" \
    -d include_docs=true \
    -d include_github_actions=true \
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
    ".github/workflows/docs.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file exists"
    else
        echo -e "${RED}✗${NC} $file is missing!"
        exit 1
    fi
done

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

# Test without docs
cd ..
TEST_DIR_NO_DOCS="test-generated-project-no-docs"
if [ -d "$TEST_DIR_NO_DOCS" ]; then
    rm -rf "$TEST_DIR_NO_DOCS"
fi

echo -e "${YELLOW}Testing template without docs...${NC}"
copier copy --defaults --trust \
    -d package_name="test-minimal-package" \
    -d python_version="3.11" \
    -d include_docs=false \
    -d include_github_actions=false \
    -d init_git_and_github=false \
    . "$TEST_DIR_NO_DOCS"

cd "$TEST_DIR_NO_DOCS"

# Verify docs files don't exist when not included
if [ ! -f "mkdocs.yml" ] && [ ! -d "docs" ] && [ ! -f ".github/workflows/docs.yml" ]; then
    echo -e "${GREEN}✓${NC} Documentation files correctly excluded"
else
    echo -e "${RED}✗${NC} Documentation files exist when they shouldn't"
    exit 1
fi

# Verify it still works
echo -e "${YELLOW}Testing minimal package import...${NC}"
if uv run python -c "import test_minimal_package; print(f'Version: {test_minimal_package.__version__}')"; then
    echo -e "${GREEN}✓${NC} Minimal package works correctly"
else
    echo -e "${RED}✗${NC} Minimal package failed"
    exit 1
fi

# Run pytest tests for minimal package
echo -e "${YELLOW}Running pytest tests for minimal package...${NC}"
if uv run pytest; then
    echo -e "${GREEN}✓${NC} All tests passed"
else
    echo -e "${RED}✗${NC} Tests failed!"
    exit 1
fi

# Check Python 3.11 version
ACTUAL_VERSION=$(cat .python-version)
if [ "$ACTUAL_VERSION" = "3.11" ]; then
    echo -e "${GREEN}✓${NC} Python version 3.11 is correct"
else
    echo -e "${RED}✗${NC} Python version should be 3.11, got: $ACTUAL_VERSION"
    exit 1
fi

cd ..

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}All tests passed! ✓${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Clean up
echo -e "${YELLOW}Cleaning up test directories...${NC}"
rm -rf "$TEST_DIR" "$TEST_DIR_NO_DOCS"
echo -e "${GREEN}Done!${NC}"
