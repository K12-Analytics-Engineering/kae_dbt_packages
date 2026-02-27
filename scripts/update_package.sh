#!/usr/bin/env bash
#
# update_package.sh — Update a vendored dbt package from upstream.
#
# Usage:
#   ./scripts/update_package.sh <package_name> <upstream_repo> <tag>
#
# Example:
#   ./scripts/update_package.sh dbt_utils dbt-labs/dbt-utils 1.1.2
#   ./scripts/update_package.sh kae_dbt K12-Analytics-Engineering/kae_dbt 0.5.2
#
# What it does:
#   1. Clones the upstream repo at the specified tag (shallow)
#   2. Replaces the existing subdirectory in this monorepo
#   3. Strips Python manifest files that trigger Dependabot alerts
#   4. Strips dev/CI files not needed at runtime
#   5. Shows a summary of what changed
#

set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Usage: $0 <package_name> <upstream_repo> <tag>"
    echo "Example: $0 dbt_utils dbt-labs/dbt-utils 1.1.2"
    exit 1
fi

PACKAGE_NAME="$1"
UPSTREAM_REPO="$2"
TAG="$3"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MONO_ROOT="$(dirname "$SCRIPT_DIR")"
PACKAGE_DIR="$MONO_ROOT/$PACKAGE_NAME"
STAGING_DIR=$(mktemp -d)

trap 'rm -rf "$STAGING_DIR"' EXIT

echo "Updating $PACKAGE_NAME from $UPSTREAM_REPO @ $TAG"
echo "=================================================="

# Clone upstream at tag
echo ""
echo "Cloning upstream..."
git clone --depth 1 --branch "$TAG" "https://github.com/$UPSTREAM_REPO.git" "$STAGING_DIR/$PACKAGE_NAME" 2>&1 | grep -v "^$"

# Remove old package directory (preserve monorepo root files)
if [ -d "$PACKAGE_DIR" ]; then
    echo "Removing old $PACKAGE_NAME..."
    rm -rf "$PACKAGE_DIR"
fi

# Copy new package (excluding .git)
echo "Copying new $PACKAGE_NAME..."
rsync -a --exclude='.git' "$STAGING_DIR/$PACKAGE_NAME/" "$PACKAGE_DIR/"

# Strip Python manifest files
PYTHON_MANIFESTS=(
    "setup.py" "setup.cfg" "pyproject.toml"
    "requirements.txt" "dev-requirements.txt"
    "poetry.lock" "uv.lock"
    "Pipfile" "Pipfile.lock"
    "Makefile"
)

# dbt dependency files — these reference upstream Hub sources which conflict
# with our monorepo git sources when consumer repos run dbt deps.
DBT_DEP_FILES=(
    "packages.yml" "package-lock.yml"
)

echo ""
echo "Stripping Python manifest files..."
stripped=0
for pattern in "${PYTHON_MANIFESTS[@]}"; do
    while IFS= read -r -d '' file; do
        rm "$file"
        echo "  removed ${file#$PACKAGE_DIR/}"
        ((stripped++))
    done < <(find "$PACKAGE_DIR" -name "$pattern" -print0 2>/dev/null)
done

if [ "$stripped" -eq 0 ]; then
    echo "  (none found)"
fi

# Strip dbt dependency files
echo ""
echo "Stripping dbt dependency files..."
dbt_stripped=0
for pattern in "${DBT_DEP_FILES[@]}"; do
    while IFS= read -r -d '' file; do
        rm "$file"
        echo "  removed ${file#$PACKAGE_DIR/}"
        ((dbt_stripped++))
    done < <(find "$PACKAGE_DIR" -name "$pattern" -print0 2>/dev/null)
done

if [ "$dbt_stripped" -eq 0 ]; then
    echo "  (none found)"
fi

# Strip dev/CI files
DEV_PATTERNS=(
    ".github" ".circleci"
    "integration_tests" "integration_tests_2"
    ".venv" "dbt_packages" "target" "logs"
    ".editorconfig" ".gitignore" ".python-version"
    ".sqlfluff" ".sqlfluffignore"
    "run_test.sh" "run_functional_test.sh" "run_tox_tests.sh"
    "tox.ini" "pytest.ini"
    "docker-compose.yml" "supported_adapters.env"
    "mkdocs.yml" "CONTRIBUTING.md" "RELEASE.md"
)

echo ""
echo "Stripping dev/CI files..."
dev_stripped=0
for pattern in "${DEV_PATTERNS[@]}"; do
    while IFS= read -r -d '' item; do
        rm -rf "$item"
        echo "  removed ${item#$PACKAGE_DIR/}"
        ((dev_stripped++))
    done < <(find "$PACKAGE_DIR" -maxdepth 1 -name "$pattern" -print0 2>/dev/null)
done

if [ "$dev_stripped" -eq 0 ]; then
    echo "  (none found)"
fi

# Strip non-runtime directories (docs, samples, etc.)
# Keep: macros, models, seeds, tests, analysis, analyses, snapshots
NON_RUNTIME_DIRS=("docs" "etc" "static" "data" "sample_analysis" "sample_sources")

echo ""
echo "Stripping non-runtime directories..."
nr_stripped=0
for pattern in "${NON_RUNTIME_DIRS[@]}"; do
    while IFS= read -r -d '' item; do
        rm -rf "$item"
        echo "  removed ${item#$PACKAGE_DIR/}"
        ((nr_stripped++))
    done < <(find "$PACKAGE_DIR" -maxdepth 1 -type d -name "$pattern" -print0 2>/dev/null)
done

if [ "$nr_stripped" -eq 0 ]; then
    echo "  (none found)"
fi

# Summary
echo ""
echo "Done. $PACKAGE_NAME updated to $TAG."
echo "Stripped $stripped Python manifest(s), $dbt_stripped dbt dep file(s), $dev_stripped dev file(s), $nr_stripped non-runtime dir(s)."
echo ""
echo "Next steps:"
echo "  1. Update manifest.yml with the new version"
echo "  2. Review changes: git diff"
echo "  3. Commit and tag a new release"
