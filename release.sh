#!/usr/bin/env python3
"""Release automation script for lil-python-template.

This script automates the release process for the copier template:
1. Verifies git repo is clean
2. Runs validation (test script)
3. Creates release tag
4. Pushes tag to origin
5. Creates GitHub release
"""

import argparse
import subprocess
import sys
from pathlib import Path


# File paths
REPO_ROOT = Path(__file__).parent


def print_step(message: str) -> None:
    """Print a step message with formatting."""
    print(f"\n{'='*70}")
    print(f"  {message}")
    print(f"{'='*70}\n")


def run_command(cmd: list[str], description: str, capture_output: bool = False) -> subprocess.CompletedProcess:
    """Run a command and check for errors.

    Args:
        cmd: Command and arguments as list
        description: Human-readable description of what the command does
        capture_output: Whether to capture stdout/stderr

    Returns:
        CompletedProcess instance

    Raises:
        SystemExit: If command fails
    """
    print(f"→ {description}")
    print(f"  Command: {' '.join(cmd)}")

    try:
        result = subprocess.run(
            cmd,
            cwd=REPO_ROOT,
            capture_output=capture_output,
            text=True,
            check=True
        )
        if not capture_output:
            print(f"✓ {description} completed successfully")
        return result
    except subprocess.CalledProcessError as e:
        print(f"\n✗ ERROR: {description} failed!")
        if capture_output:
            if e.stdout:
                print(f"stdout: {e.stdout}")
            if e.stderr:
                print(f"stderr: {e.stderr}")
        sys.exit(1)


def check_git_clean() -> None:
    """Verify that the git repository has no uncommitted changes."""
    print_step("Checking Git Repository Status")

    result = run_command(
        ["git", "status", "--porcelain"],
        "Checking for uncommitted changes",
        capture_output=True
    )

    if result.stdout.strip():
        print("✗ ERROR: Git repository is not clean!")
        print("\nUncommitted changes:")
        print(result.stdout)
        sys.exit(1)

    print("✓ Git repository is clean")


def run_template_tests() -> None:
    """Run the template test script."""
    print_step("Running Template Tests")
    run_command(
        ["./test_template.sh"],
        "Running test_template.sh"
    )


def create_release_tag(version: str) -> None:
    """Create an annotated git tag for the release.

    Args:
        version: Release version string (e.g., "v0.2.0")
    """
    print_step(f"Creating Release Tag: {version}")

    run_command(
        ["git", "tag", "-a", version, "-m", f"Release {version}"],
        f"Creating tag {version}"
    )


def push_tag(version: str) -> None:
    """Push the release tag to origin.

    Args:
        version: Release version string
    """
    print_step(f"Pushing Tag to Origin: {version}")

    run_command(
        ["git", "push", "origin", version],
        f"Pushing tag {version}"
    )


def create_github_release(version: str) -> None:
    """Create a GitHub release for the version tag.

    Args:
        version: Release version string
    """
    print_step(f"Creating GitHub Release: {version}")

    run_command(
        ["gh", "release", "create", version, "--title", version, "--generate-notes"],
        f"Creating GitHub release {version}"
    )


def get_latest_tag() -> str:
    """Get the latest git tag.

    Returns:
        Latest tag string (e.g., "v0.1.0")

    Raises:
        SystemExit: If no tags exist
    """
    print_step("Getting Latest Tag")

    result = run_command(
        ["git", "tag", "--sort=-version:refname"],
        "Fetching git tags",
        capture_output=True
    )

    tags = result.stdout.strip().split('\n')
    if not tags or not tags[0]:
        print("✗ ERROR: No git tags found!")
        print("  Create an initial tag first (e.g., git tag v0.1.0)")
        sys.exit(1)

    latest_tag = tags[0]
    print(f"✓ Latest tag: {latest_tag}")
    return latest_tag


def parse_version(version: str) -> tuple[int, int, int]:
    """Parse a version string into major, minor, patch.

    Args:
        version: Version string (e.g., "v0.1.0")

    Returns:
        Tuple of (major, minor, patch)

    Raises:
        SystemExit: If version format is invalid
    """
    import re
    match = re.match(r'^v?(\d+)\.(\d+)\.(\d+)', version)
    if not match:
        print(f"✗ ERROR: Invalid version format: {version}")
        print("  Expected format: v0.1.0")
        sys.exit(1)

    return tuple(map(int, match.groups()))


def bump_version(version: str, bump_type: str) -> str:
    """Bump version according to type.

    Args:
        version: Current version (e.g., "v0.1.0")
        bump_type: One of 'patch', 'minor', 'major'

    Returns:
        Next version string (e.g., "v0.1.1")
    """
    major, minor, patch = parse_version(version)

    if bump_type == "patch":
        patch += 1
    elif bump_type == "minor":
        minor += 1
        patch = 0
    elif bump_type == "major":
        major += 1
        minor = 0
        patch = 0
    else:
        print(f"✗ ERROR: Invalid bump type: {bump_type}")
        sys.exit(1)

    return f"v{major}.{minor}.{patch}"


def main() -> None:
    """Main release workflow."""
    # Parse arguments
    parser = argparse.ArgumentParser(
        description="Automate the release process for lil-python-template"
    )
    parser.add_argument(
        "bump_type",
        choices=["patch", "minor", "major"],
        help="Version bump type"
    )
    args = parser.parse_args()

    print("\n" + "="*70)
    print("  lil-python-template Release Script")
    print("="*70)
    print(f"\nBump type: {args.bump_type}")

    # Get latest tag and calculate new version
    latest_tag = get_latest_tag()
    new_version = bump_version(latest_tag, args.bump_type)

    print(f"\n→ Current version: {latest_tag}")
    print(f"→ New version: {new_version}")

    # Confirmation prompt
    print("\n" + "!"*70)
    print("  WARNING: This script will perform a RELEASE")
    print("!"*70)
    print("\nThis script will:")
    print("  • Run template validation tests")
    print("  • Create and push a release tag")
    print("  • Create a GitHub release")
    print("\nType 'acknowledge' to continue or Ctrl+C to cancel: ", end="", flush=True)

    confirmation = input().strip()
    if confirmation != "acknowledge":
        print("\n✗ Release cancelled. You must type 'acknowledge' to proceed.")
        sys.exit(1)

    print("✓ Proceeding with release...")

    # Step 1: Check git status
    check_git_clean()

    # Step 2: Run validation tests
    run_template_tests()

    # Step 3: Create release tag
    create_release_tag(new_version)

    # Step 4: Push tag to origin
    push_tag(new_version)

    # Step 5: Create GitHub release
    create_github_release(new_version)

    # Success!
    print_step("Release Complete!")
    print(f"✓ Released: {new_version} (was {latest_tag})")
    print(f"✓ Tagged and pushed: {new_version}")
    print(f"✓ Created GitHub release: {new_version}")
    print(f"\nUsers can now use this template with:")
    print(f"  copier copy gh:habemus-papadum/lil-python-template your-project")


if __name__ == "__main__":
    main()
