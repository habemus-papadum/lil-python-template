#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TEMPLATE_VARS=(
    "package_name=test-awesome-package"
    "package_description=A test package generated from the template"
    "python_version=3.12"
    "author_name=Test User"
    "author_email=test@example.com"
    "github_username=testuser"
    "init_git_and_github=false"
)

run_copier() {
    local target_dir=$1
    shift
    local extra_flags=()
    local copier_args=()

    if [ "$#" -gt 0 ]; then
        extra_flags=("$@")
    fi

    for var in "${TEMPLATE_VARS[@]}"; do
        copier_args+=(-d "$var")
    done

    if [ -d "$target_dir" ]; then
        echo -e "${YELLOW}Cleaning up previous test directory: ${target_dir}${NC}"
        rm -rf "$target_dir"
    fi

    echo -e "${YELLOW}Generating ${target_dir}...${NC}"
    local cmd=(
        copier copy --defaults --trust --vcs-ref=HEAD
        "${copier_args[@]}"
    )

    if [ ${#extra_flags[@]} -gt 0 ]; then
        cmd+=("${extra_flags[@]}")
    fi

    cmd+=(. "$target_dir")
    "${cmd[@]}"
}

verify_common_files() {
    local dir=$1
    pushd "$dir" >/dev/null

    echo -e "${YELLOW}Generated project structure (${dir}):${NC}"
    find . -type f \
        -not -path './.git/*' \
        -not -path './.venv/*' \
        -not -path './node_modules/*' \
        -not -path './widgets/node_modules/*' | sort

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

    popd >/dev/null
}

check_scripts_executable() {
    local dir=$1
    shift
    local scripts=("$@")
    pushd "$dir" >/dev/null
    echo -e "${YELLOW}Verifying scripts are executable...${NC}"
    for script in "${scripts[@]}"; do
        if [ -x "$script" ]; then
            echo -e "${GREEN}✓${NC} $script is executable"
        else
            echo -e "${RED}✗${NC} $script is not executable!"
            exit 1
        fi
    done
    popd >/dev/null
}

run_validation_suite() {
    local dir=$1
    local include_ts=$2
    pushd "$dir" >/dev/null

    if [ ! -d .git ]; then
        git init >/dev/null
        git add . >/dev/null
        git commit -m "Initial scaffold" >/dev/null
    fi

    echo -e "${YELLOW}Running project setup...${NC}"
    ./scripts/setup.sh

    if [[ -n $(git status --porcelain) ]]; then
        git add . >/dev/null
        git commit -m "Post-setup state" >/dev/null
    fi

    echo -e "${YELLOW}Running pre-release checks...${NC}"
    ./scripts/pre-release.sh

    echo -e "${YELLOW}Running notebook smoke test...${NC}"
    ./scripts/test_notebooks.sh --no-inplace

    if [ "$include_ts" = "true" ]; then
        if [ -f "src/pdum/test_awesome_package/widgets/index.js" ]; then
            echo -e "${GREEN}✓${NC} Widget bundle copied into Python package"
        else
            echo -e "${RED}✗${NC} Widget bundle missing at src/pdum/test_awesome_package/widgets/index.js"
            exit 1
        fi
    fi

    popd >/dev/null
}

test_with_widgets() {
    local dir="test-generated-project"
    run_copier "$dir"
    verify_common_files "$dir"

    echo -e "${YELLOW}Checking TypeScript workspace files...${NC}"
    for file in \
        package.json \
        pnpm-workspace.yaml \
        .npmrc \
        .pnpm-approvals.yaml \
        widgets/package.json \
        widgets/src/index.ts \
        widgets/src/version.ts \
        src/pdum/test_awesome_package/widgets/__init__.py; do
        if [ -f "$dir/$file" ]; then
            echo -e "${GREEN}✓${NC} $file exists"
        else
            echo -e "${RED}✗${NC} Required file missing: $file"
            exit 1
        fi
    done

    if grep -q '"workspaces"' "$dir/package.json"; then
        echo -e "${GREEN}✓${NC} pnpm workspace configured"
    else
        echo -e "${RED}✗${NC} pnpm workspace missing from package.json"
        exit 1
    fi

    check_scripts_executable "$dir" \
        scripts/setup.sh \
        scripts/build.sh \
        scripts/pre-release.sh \
        scripts/release.sh \
        scripts/publish.sh \
        scripts/nb.sh \
        scripts/test_notebooks.sh \
        scripts/setup-visual-tests.sh

    run_validation_suite "$dir" true
}

test_without_widgets() {
    local dir="test-generated-project-no-ts"
    run_copier "$dir" "-d" "include_ts_widgets=false"
    verify_common_files "$dir"

    echo -e "${YELLOW}Ensuring widget workspace files were removed...${NC}"
    for file in package.json pnpm-workspace.yaml .npmrc .pnpm-approvals.yaml widgets src/pdum/test_awesome_package/widgets; do
        if [ -e "$dir/$file" ]; then
            echo -e "${RED}✗${NC} $file should not exist when widgets are disabled"
            exit 1
        fi
    done

    check_scripts_executable "$dir" \
        scripts/setup.sh \
        scripts/build.sh \
        scripts/pre-release.sh \
        scripts/release.sh \
        scripts/publish.sh \
        scripts/nb.sh \
        scripts/test_notebooks.sh \
        scripts/setup-visual-tests.sh

    run_validation_suite "$dir" false
}

main() {
    echo -e "${YELLOW}Testing lil-python-template copier template${NC}"
    test_with_widgets
    test_without_widgets

    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}All template tests passed! ✓${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e "${YELLOW}Cleaning up test directories...${NC}"
    rm -rf test-generated-project test-generated-project-no-ts
    echo -e "${GREEN}Done!${NC}"
}

main "$@"
